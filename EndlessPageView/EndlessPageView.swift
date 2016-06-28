//
//  EndlessPageView.swift
//  EndlessPageView
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import UIKit
import Interpolate

public struct IndexLocation : Hashable {
    public var column:Int
    public var row:Int
    
    public var hashValue: Int {
        return column.hashValue | (row.hashValue << 32)
    }
    
    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
}
public func == (lhs: IndexLocation, rhs: IndexLocation) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

public protocol EndlessPageViewDataSource : class {
    func endlessPageView(endlessPageView:EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell?
}

public protocol EndlessPageViewDelegate : class {
    func endlessPageViewDidSelectItemAtIndex(indexLocation: IndexLocation)
    func endlessPageViewDidScroll(endlessPageView: EndlessPageView)
    func endlessPageViewShouldScroll(endlessPageView: EndlessPageView, scrollingDirection: EndlessPageScrollDirectionRules) -> EndlessPageScrollDirectionRules
    
    func endlessPageView(endlessPageView: EndlessPageView, willDisplayCell cell: EndlessPageCell, forItemAtIndexLocation indexLocation: IndexLocation)
    func endlessPageView(endlessPageView: EndlessPageView, didEndDisplayingCell cell: EndlessPageCell, forItemAtIndexLocation indexLocation: IndexLocation)
    func endlessPageViewDidEndDecelerating(endlessPageView: EndlessPageView)
}

public struct EndlessPageScrollDirectionRules : OptionSetType {
    public var rawValue : UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let Horizontal = EndlessPageScrollDirectionRules(rawValue: 1 << 0)
    public static let Vertical = EndlessPageScrollDirectionRules(rawValue: 1 << 2)
    public static var Both : EndlessPageScrollDirectionRules = [ .Horizontal, .Vertical ]
}

@IBDesignable
public class EndlessPageView : UIView, UIGestureRecognizerDelegate, _EndlessPageCellDelegate {
    
    // - Public -
    
    // Protocols
    public weak var dataSource:EndlessPageViewDataSource?
    public weak var delegate:EndlessPageViewDelegate?
    
    // Public settings
    public var printDebugInfo = false
    public var scrollDirection:EndlessPageScrollDirectionRules = .Both
    public var pagingEnabled = true
    public var directionalLockEnabled = true
    
    // - Private -
    
    // Offset position
    public var contentOffset = CGPoint.zero {
        didSet {
            updateBounds()
            updateCells()
        }
    }
    private var panStartContentOffset = CGPoint.zero
    private var directionLockedTo:EndlessPageScrollDirectionRules = .Both
    
    // Cell pool
    private var cellPool = [String: [EndlessPageCell]]()
    private var registeredCellClasses = [String: EndlessPageCell.Type]()
    private var visibleCellsFromLocation = [IndexLocation: EndlessPageCell]()
    
    // Animation
    private var offsetChangeAnimation:Interpolate?
    
    private var hasDoneFirstReload = false
    
    // MARK: View lifecycle
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    convenience public init () {
        self.init(frame:CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture_scroll(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)

        clipsToBounds = true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !hasDoneFirstReload {
            hasDoneFirstReload = true
            reloadData()
        }
    }
    
    override public func prepareForInterfaceBuilder() {
        print("prepareForInterfaceBuilder")
    }
    
    // MARK: Actions
    
    func panGesture_scroll(panGesture: UIPanGestureRecognizer) {
        
        if let gestureView = panGesture.view, let holder = gestureView.superview {
            
            let translatePoint = panGesture.translationInView(holder)
            
            
            if panGesture.state == UIGestureRecognizerState.Began {
                panStartContentOffset = contentOffset
                directionLockedTo = .Both
                
                if let offsetChangeAnimation = offsetChangeAnimation {
                    offsetChangeAnimation.stopAnimation()
                    offsetChangeAnimation.invalidate()
                }
            }
            
            if panGesture.state == UIGestureRecognizerState.Changed {
                contentOffset = {
                    var point = contentOffset
                    
                    guard scrollDirection != [] else { return panStartContentOffset }
                    
                    if scrollDirection.contains(.Horizontal) {
                        point.x = (panStartContentOffset - translatePoint).x
                    }
                    if scrollDirection.contains(.Vertical) {
                        point.y = (panStartContentOffset - translatePoint).y
                    }
                    
                    if directionalLockEnabled {
                        
                        if directionLockedTo == .Both {
                            
                            let deltaX = abs(panStartContentOffset.x - point.x)
                            let deltaY = abs(panStartContentOffset.y - point.y)
                            
                            if deltaX != 0 && deltaY != 0 {
                                if deltaX >= deltaY {
                                    directionLockedTo = [.Horizontal]
                                } else {
                                    directionLockedTo = [.Vertical]
                                }
                            }
                        }
                    }
                    
                    guard directionLockedTo != [] else {
                        return panStartContentOffset
                    }
                    
                    if let allowedScrollDirection = delegate?.endlessPageViewShouldScroll(self, scrollingDirection: directionLockedTo) {
                        
                        guard allowedScrollDirection != [] else {
                            return panStartContentOffset
                        }
                        
                        if !allowedScrollDirection.contains(.Horizontal) {
                            point.x = panStartContentOffset.x
                        }
                        
                        if !allowedScrollDirection.contains(.Vertical) {
                            point.y = panStartContentOffset.y
                        }
                    }
                    
                    
                    return point
                }()
            }
            
            if panGesture.state == UIGestureRecognizerState.Ended {
                
                if let offsetChangeAnimation = offsetChangeAnimation {
                    offsetChangeAnimation.stopAnimation()
                    offsetChangeAnimation.invalidate()
                }
                
                if pagingEnabled {
                    
                    let offsetPage = floor((contentOffset / self.bounds.size) + 0.5)
                    let targetColumn = Int(offsetPage.x)
                    let targetRow = Int(offsetPage.y)
                    var pagePoint = CGPoint(x: CGFloat(targetColumn), y: CGFloat(targetRow)) * self.bounds.size
                    
                    // Check if cell exists, we already have loaded the visible cells
                    if visibleCellsFromLocation[IndexLocation(column: targetColumn, row: targetRow)] == nil {
                        
                        let offsetPage = floor((panStartContentOffset / self.bounds.size) + 0.5)
                        let targetColumn = Int(offsetPage.x)
                        let targetRow = Int(offsetPage.y)
                        pagePoint = CGPoint(x: CGFloat(targetColumn), y: CGFloat(targetRow)) * self.bounds.size
                    }
                    
                    let animationTime:CGFloat = 0.2
                    
                    offsetChangeAnimation = Interpolate(from: contentOffset
                        , to: pagePoint
                        , function: BasicInterpolation.EaseOut
                        , apply: { [weak self] (pos) in
                            
                            var position = pos
                            if position.x.isNaN {
                                position.x = 0.0
                            }
                            if position.y.isNaN {
                                position.y = 0.0
                            }
                            self?.contentOffset = position
                            self?.updateBounds()
                            self?.updateCells()
                        })
                    offsetChangeAnimation?.animate(1.0, duration: animationTime, complete: { [weak self] in
                        
                        if let strongSelf = self {
                            strongSelf.delegate?.endlessPageViewDidEndDecelerating(strongSelf)
                        }
                        })
                    
                } else {
                    
                    let velocity = panGesture.velocityInView(holder) * -1
                    let magnitude = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
                    let slideMult = magnitude / 200
                    
                    let slideFactor = 0.1 * slideMult
                    
                    let animationTime = slideFactor * 2
                    
                    let slideToPoint:CGPoint = {
                        var point = contentOffset
                        
                        if scrollDirection.contains(.Horizontal) {
                            point.x = contentOffset.x + (velocity.x * slideFactor)
                        }
                        if scrollDirection.contains(.Vertical) {
                            point.y = contentOffset.y + (velocity.y * slideFactor)
                        }
                        
                        return point
                    }()
                    
                    
                    
                    offsetChangeAnimation = Interpolate(from: contentOffset
                        , to: slideToPoint
                        , function: BasicInterpolation.EaseOut
                        , apply: { [weak self] (pos) in
                            
                            var position = pos
                            if position.x.isNaN {
                                position.x = 0.0
                            }
                            if position.y.isNaN {
                                position.y = 0.0
                            }
                            
                            self?.contentOffset = position
                        })
                    offsetChangeAnimation?.animate(1.0, duration: animationTime, complete: { [weak self] in
                        
                        if let strongSelf = self {
                            strongSelf.delegate?.endlessPageViewDidEndDecelerating(strongSelf)
                        }
                        })
                }
            }
        }
        
        
    }
    
    // MARK: Public getters
    
    public func visibleCells() -> [EndlessPageCell] {
        return Array(visibleCellsFromLocation.values)
    }
    
    public func indexLocationsForVisibleItems() -> [IndexLocation] {
        return Array(visibleCellsFromLocation.keys)
    }
    
    public func indexLocationForCell(cell: EndlessPageCell) -> IndexLocation? {
        let pagePoint = round(cell.frame.origin / self.bounds.size, tollerence: 0.0001)
        
        if !pagePoint.x.isNaN && !pagePoint.y.isNaN {
            let indexLocation = IndexLocation(column: Int(pagePoint.x), row: Int(pagePoint.y))
            return indexLocation
        }
        
        return nil
    }
    
    public func setContentOffset(offset: CGPoint, animated: Bool) {
        if let indexLocation = indexLocationForItemAtPoint(offset) {
            scrollToItemAtIndexLocation(indexLocation, animated: animated)
        }
        
    }
    
    public func indexLocationForItemAtPoint(point: CGPoint) -> IndexLocation? {
        let pagePoint = round(point / self.bounds.size, tollerence: 0.0001)
        if !pagePoint.x.isNaN && !pagePoint.y.isNaN {
            let indexLocation = IndexLocation(column: Int(pagePoint.x), row: Int(pagePoint.y))
            
            return indexLocation
        }
        return nil
    }
    
    public func indexLocationFromContentOffset() -> IndexLocation? {
        return indexLocationForItemAtPoint(contentOffset)
    }
    
    public func cellForItemAtIndexLocation(indexLocation: IndexLocation) -> EndlessPageCell? {
        if let cell = visibleCellsFromLocation[indexLocation] {
            return cell
        } else if let cell = dataSource?.endlessPageView(self, cellForIndexLocation: indexLocation) {
            visibleCellsFromLocation[indexLocation] = cell
            addSubview(cell)
            delegate?.endlessPageView(self, willDisplayCell: cell, forItemAtIndexLocation: indexLocation)
            return cell
        }
        
        return nil
    }
    public func scrollToItemAtIndexLocation(indexLocation: IndexLocation, animated:Bool) {
        
        let animationTime = animated ? CGFloat(0.25) : CGFloat(0.0)
        
        let pagePoint = CGPoint(x: indexLocation.column, y: indexLocation.row) * self.bounds.size
        
        if let offsetChangeAnimation = offsetChangeAnimation {
            offsetChangeAnimation.stopAnimation()
            offsetChangeAnimation.invalidate()
        }
        
        offsetChangeAnimation = Interpolate(from: contentOffset
            , to: pagePoint
            , function: BasicInterpolation.EaseOut
            , apply: { [weak self] (pos) in
                
                var position = pos
                if position.x.isNaN {
                    position.x = 0.0
                }
                if position.y.isNaN {
                    position.y = 0.0
                }
                self?.contentOffset = position
            })
        offsetChangeAnimation?.animate(1.0, duration: animationTime, complete: { [weak self] in
            
            if let strongSelf = self {
                strongSelf.delegate?.endlessPageViewDidEndDecelerating(strongSelf)
            }
            })
    }
    
    // MARK: Data cache
    
    public func reloadData() {
        contentOffset = CGPoint.zero
    }
    
    public func registerClass(cellClass: EndlessPageCell.Type?, forViewWithReuseIdentifier identifier: String) {
        
        registeredCellClasses[identifier] = cellClass
    }
    public func registerNib(nib: UINib?, forViewWithReuseIdentifier identifier: String) {
        fatalError("registerNib(nib:forViewWithReuseIdentifier:) has not been implemented")
    }
    
    public func dequeueReusableCellWithReuseIdentifier(identifier: String) -> EndlessPageCell {
        if cellPool[identifier] == nil {
            cellPool[identifier] = [EndlessPageCell]()
        }
        
        // This could probably be faster with two arrays for is use and not in use
        if let cells = cellPool[identifier] {
            for cell in cells {
                if cell.superview == nil {
                    cell.prepareForReuse()
                    return cell
                }
            }
        }
        
        if let cellClass = registeredCellClasses[identifier] {
            let cell = cellClass.init()
            cell.privateDelegate = self
            cellPool[identifier]?.append(cell)
            
            if printDebugInfo {
                print("generated cell for identifer: \(identifier), pool size: ", cellPool[identifier]?.count)
            }
            
            return cell
        }
        
        fatalError(String(format: "Did not register class %@ for EndlessPageView ", identifier))
    }
    
    
    // MARK: Update cells
    
    private func updateBounds() {
        
        bounds = CGRect(origin: contentOffset, size: bounds.size)
        delegate?.endlessPageViewDidScroll(self)
    }
    
    private func updateCells() {
        let pageOffset = round(contentOffset / CGPoint(x: CGRectGetWidth(self.frame), y: CGRectGetHeight(self.frame))
            , tollerence: 0.0001)
        
        if !pageOffset.x.isNaN && !pageOffset.y.isNaN {
            
            
            
            
            let rows:[Int] = {
                if pageOffset.y >= 0 {
                    return floor(pageOffset.y) == pageOffset.y ? [Int(pageOffset.y)] : [Int(pageOffset.y), Int(pageOffset.y + 1)]
                }
                return floor(pageOffset.y) == pageOffset.y ? [Int(pageOffset.y)] : [Int(pageOffset.y), Int(pageOffset.y - 1)]
            }()
            
            let columns:[Int] = {
                if pageOffset.x >= 0 {
                    return floor(pageOffset.x) == pageOffset.x ? [Int(pageOffset.x)] : [Int(pageOffset.x), Int(pageOffset.x + 1)]
                }
                return floor(pageOffset.x) == pageOffset.x ? [Int(pageOffset.x)] : [Int(pageOffset.x), Int(pageOffset.x - 1)]
            }()
            
            var updatedVisibleCellIndexLocations = [IndexLocation]()
            
            for row in rows {
                for column in columns {
                    
                    let indexLocation = IndexLocation(column: column, row: row)
                    
                    if let cell = cellForItemAtIndexLocation(indexLocation) {
                        cell.frame = CGRect(x: CGRectGetWidth(self.frame) * CGFloat(column)
                            , y: CGRectGetHeight(self.frame) * CGFloat(row)
                            , width: CGRectGetWidth(self.frame)
                            , height: CGRectGetHeight(self.frame))
                        updatedVisibleCellIndexLocations.append(indexLocation)
                    }
                }
            }
            
            let oldCount = visibleCellsFromLocation.count
            
            let previousKeys = visibleCellsFromLocation.keys
            let removedKeys = previousKeys.filter( { !updatedVisibleCellIndexLocations.contains($0) } )
            
            removedKeys.forEach({ (indexLocation) in
                
                if let cell = visibleCellsFromLocation[indexLocation] {
                    delegate?.endlessPageView(self, didEndDisplayingCell: cell, forItemAtIndexLocation: indexLocation)
                    cell.removeFromSuperview()
                }
                visibleCellsFromLocation[indexLocation] = nil
            })
            
            if printDebugInfo {
                if oldCount != visibleCellsFromLocation.count {
                    print("removed \(oldCount - visibleCellsFromLocation.count) cells")
                }
            }
        } else {
            print("Error in page offset: \(pageOffset)")
        }
        
    }
    
    
    // MARK: Gesture delegate
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Endless page cell delegate
    
    internal func didSelectCell(cell: EndlessPageCell) {
        
        if let indexLocation = self.indexLocationForCell(cell) {
            delegate?.endlessPageViewDidSelectItemAtIndex(indexLocation)
        }
    }
}