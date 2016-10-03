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
        if MemoryLayout<Int>.size == MemoryLayout<Int64>.size {
            return column.hashValue | (row.hashValue << 32)
        } else {
            return column.hashValue | (row.hashValue << 16)
        }
        
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
    func endlessPageView(_ endlessPageView:EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell?
}

public protocol EndlessPageViewDelegate : class {
    func endlessPageViewDidSelectItemAtIndex(_ indexLocation: IndexLocation)
    func endlessPageViewWillScroll(_ endlessPageView: EndlessPageView)
    func endlessPageViewDidScroll(_ endlessPageView: EndlessPageView)
    func endlessPageViewShouldScroll(_ endlessPageView: EndlessPageView, scrollingDirection: EndlessPageScrollDirectionRules) -> EndlessPageScrollDirectionRules
    
    func endlessPageView(_ endlessPageView: EndlessPageView, willDisplayCell cell: EndlessPageCell, forItemAtIndexLocation indexLocation: IndexLocation)
    func endlessPageView(_ endlessPageView: EndlessPageView, didEndDisplayingCell cell: EndlessPageCell, forItemAtIndexLocation indexLocation: IndexLocation)
    func endlessPageViewDidEndDecelerating(_ endlessPageView: EndlessPageView)
}

public struct EndlessPageScrollDirectionRules : OptionSet {
    public var rawValue : UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let Horizontal = EndlessPageScrollDirectionRules(rawValue: 1 << 0)
    public static let Vertical = EndlessPageScrollDirectionRules(rawValue: 1 << 2)
    public static var Both : EndlessPageScrollDirectionRules = [ .Horizontal, .Vertical ]
}

@IBDesignable
open class EndlessPageView : UIView, UIGestureRecognizerDelegate, _EndlessPageCellDelegate {
    
    // - Public -
    
    // Protocols
    open weak var dataSource:EndlessPageViewDataSource?
    open weak var delegate:EndlessPageViewDelegate?
    
    // Public settings
    open var printDebugInfo = false
    open var scrollDirection:EndlessPageScrollDirectionRules = .Both
    open var pagingEnabled = true
    open var directionalLockEnabled = true
    fileprivate(set) open var directionLockedTo:EndlessPageScrollDirectionRules = .Both
    
    // - Private -
    
    // Offset position
    open var contentOffset = CGPoint.zero {
        didSet {
            if contentOffset.x.isNaN || contentOffset.y.isNaN {
                contentOffset = oldValue
            }
            updateBounds()
            updateCells()
        }
    }
    
    fileprivate var panStartContentOffset = CGPoint.zero
    open var scrollingInDirection: CGFloat {
        get {
            if directionLockedTo == .Horizontal {
                return self.bounds.origin.x - panStartContentOffset.x
            } else if directionLockedTo == .Vertical {
                return self.bounds.origin.y - panStartContentOffset.y
            }
            
            return CGFloat(0)
        }
    }
    
    // Cell pool
    fileprivate var cellPool = [String: [EndlessPageCell]]()
    fileprivate var registeredCellClasses = [String: EndlessPageCell.Type]()
    fileprivate var visibleCellsFromLocation = [IndexLocation: EndlessPageCell]()
    
    // Animation
    fileprivate var offsetChangeAnimation:Interpolate?
    
    fileprivate var hasDoneFirstReload = false
    
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
    
    fileprivate func setup() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture_scroll(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        clipsToBounds = true
        
        
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if !hasDoneFirstReload {
            hasDoneFirstReload = true
            reloadData()
        }
    }
    
    override open func prepareForInterfaceBuilder() {
        print("prepareForInterfaceBuilder")
    }
    
    // MARK: Actions
    
    func panGesture_scroll(_ panGesture: UIPanGestureRecognizer) {
        
        if let gestureView = panGesture.view, let holder = gestureView.superview {
            
            let translatePoint = panGesture.translation(in: holder)
            var runCompletion = false
            
            
            if panGesture.state == UIGestureRecognizerState.began {
                panStartContentOffset = contentOffset
                
                if let offsetChangeAnimation = offsetChangeAnimation {
                    runCompletion = false
                    offsetChangeAnimation.stopAnimation()
                }
                
                delegate?.endlessPageViewWillScroll(self)
            }
            
            if panGesture.state == UIGestureRecognizerState.changed {
                contentOffset = {
                    var point = contentOffset
                    
                    guard scrollDirection != [] else {
                        return panStartContentOffset
                    }
                    
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
            
            if panGesture.state == UIGestureRecognizerState.ended {
                
                if let offsetChangeAnimation = offsetChangeAnimation {
                    runCompletion = false
                    offsetChangeAnimation.stopAnimation()
                }
                
                
                if pagingEnabled {
                    
                    let offsetPage = floor((panStartContentOffset / self.bounds.size) + 0.5)
                    var targetColumn = Int(offsetPage.x)
                    var targetRow = Int(offsetPage.y)
                    
                    let localizedOffset = contentOffset - (CGPoint(x: targetColumn, y: targetRow) * self.bounds.size)
                    let triggerPercent = CGFloat(0.1)
                    
                    if abs(localizedOffset.x) > self.bounds.size.width * triggerPercent {
                        if contentOffset.x > panStartContentOffset.x {
                            targetColumn += 1
                        } else if contentOffset.x < panStartContentOffset.x {
                            targetColumn -= 1
                        }
                    } else if abs(localizedOffset.y) > self.bounds.size.height * triggerPercent {
                        if contentOffset.y > panStartContentOffset.y {
                            targetRow += 1
                        } else if contentOffset.y < panStartContentOffset.y {
                            targetRow -= 1
                        }
                    }
                    
                    
                    var pagePoint = CGPoint(x: CGFloat(targetColumn), y: CGFloat(targetRow)) * self.bounds.size
                    
                    // Check if cell exists, we already have loaded the visible cells
                    if visibleCellsFromLocation[IndexLocation(column: targetColumn, row: targetRow)] == nil {
                        let targetColumn = Int(offsetPage.x)
                        let targetRow = Int(offsetPage.y)
                        pagePoint = CGPoint(x: CGFloat(targetColumn), y: CGFloat(targetRow)) * self.bounds.size
                    }
                    
                    
                    print("targetColumn: \(targetColumn), targetRow: \(targetRow)")
                    
                    let animationTime:TimeInterval = 0.2
                    
                    runCompletion = true
                    
                    offsetChangeAnimation = Interpolate(from: contentOffset
                        , to: pagePoint
                        , function: BasicInterpolation.easeOut
                        , apply: { [weak self] (pos) in
                            
                            self?.contentOffset = pos
                            self?.updateBounds()
                            self?.updateCells()
                    })
                    offsetChangeAnimation?.animate(1.0, duration: CGFloat(animationTime), completion: { [weak self] in
                        if runCompletion {
                            if let strongSelf = self {
                                strongSelf.directionLockedTo = .Both
                                strongSelf.delegate?.endlessPageViewDidEndDecelerating(strongSelf)
                            }
                        }
                    })
                } else {
                    
                    let velocity = panGesture.velocity(in: holder) * -1
                    let magnitude = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
                    let slideMult = magnitude / 200
                    
                    let slideFactor = 0.1 * slideMult
                    
                    let animationTime = TimeInterval(slideFactor * 2)
                    
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
                        , function: BasicInterpolation.easeOut
                        , apply: { [weak self] (pos) in
                            
                            self?.contentOffset = pos
                    })
                    offsetChangeAnimation?.animate(1.0, duration: CGFloat(animationTime), completion: { [weak self] in
                        
                        if let strongSelf = self {
                            strongSelf.directionLockedTo = .Both
                            strongSelf.delegate?.endlessPageViewDidEndDecelerating(strongSelf)
                        }
                    })
                }
            }
        }
    }
    
    // MARK: Public getters
    
    open func visibleCells() -> [EndlessPageCell] {
        return Array(visibleCellsFromLocation.values)
    }
    
    open func indexLocationsForVisibleItems() -> [IndexLocation] {
        return Array(visibleCellsFromLocation.keys)
    }
    
    open func indexLocationForCell(_ cell: EndlessPageCell) -> IndexLocation? {
        let pagePoint = round(cell.frame.origin / self.bounds.size, tollerence: 0.0001)
        
        if !pagePoint.x.isNaN && !pagePoint.y.isNaN {
            let indexLocation = IndexLocation(column: Int(pagePoint.x), row: Int(pagePoint.y))
            return indexLocation
        }
        
        return nil
    }
    
    open func setContentOffset(_ offset: CGPoint, animated: Bool) {
        if let indexLocation = indexLocationForItemAtPoint(offset) {
            scrollToItemAtIndexLocation(indexLocation, animated: animated)
        }
        
    }
    
    open func indexLocationForItemAtPoint(_ point: CGPoint) -> IndexLocation? {
        let pagePoint = round(point / self.bounds.size, tollerence: 0.0001)
        if !pagePoint.x.isNaN && !pagePoint.y.isNaN {
            let indexLocation = IndexLocation(column: Int(pagePoint.x), row: Int(pagePoint.y))
            
            return indexLocation
        }
        return nil
    }
    
    open func indexLocationFromContentOffset() -> IndexLocation? {
        return indexLocationForItemAtPoint(contentOffset)
    }
    
    open func cellForItemAtIndexLocation(_ indexLocation: IndexLocation) -> EndlessPageCell? {
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
    open func scrollToItemAtIndexLocation(_ indexLocation: IndexLocation, animated:Bool) {
        
        let animationTime = TimeInterval(animated ? 0.25 : 0.0)
        
        let pagePoint = CGPoint(x: indexLocation.column, y: indexLocation.row) * self.bounds.size
        
        if let offsetChangeAnimation = offsetChangeAnimation {
            offsetChangeAnimation.stopAnimation()
            offsetChangeAnimation.invalidate()
        }
        
        if animated {
            if contentOffset.x != pagePoint.x && contentOffset.y == pagePoint.y {
                directionLockedTo = [.Horizontal]
            } else if contentOffset.x == pagePoint.x && contentOffset.y != pagePoint.y {
                directionLockedTo = [.Vertical]
            } else {
                directionLockedTo = .Both
            }
        }
        
        offsetChangeAnimation = Interpolate(from: contentOffset
            , to: pagePoint
            , function: BasicInterpolation.easeOut
            , apply: { [weak self] (pos) in
                
                self?.contentOffset = pos
        })
        offsetChangeAnimation?.animate(1.0, duration: CGFloat(animationTime), completion: { [weak self] in
            
            if let strongSelf = self {
                strongSelf.contentOffset = pagePoint
                strongSelf.delegate?.endlessPageViewDidEndDecelerating(strongSelf)
            }
        })
    }
    
    // MARK: Data cache
    
    open func reloadData() {
        
        let keys = visibleCellsFromLocation.keys
        keys.forEach({ (indexLocation) in
            
            if let cell = visibleCellsFromLocation[indexLocation] {
                delegate?.endlessPageView(self, didEndDisplayingCell: cell, forItemAtIndexLocation: indexLocation)
                cell.removeFromSuperview()
            }
            visibleCellsFromLocation[indexLocation] = nil
        })
        
        contentOffset = CGPoint.zero
        updateBounds()
        updateCells()
    }
    
    open func setIndexLocation(_ indexLocation: IndexLocation) {
        let position = CGPoint(x: CGFloat(indexLocation.column) * self.frame.width
            , y: CGFloat(indexLocation.row) * self.frame.height)
        contentOffset = position
        updateBounds()
    }
    
    open func registerClass(_ cellClass: EndlessPageCell.Type?, forViewWithReuseIdentifier identifier: String) {
        
        registeredCellClasses[identifier] = cellClass
    }
    open func registerNib(_ nib: UINib?, forViewWithReuseIdentifier identifier: String) {
        fatalError("registerNib(nib:forViewWithReuseIdentifier:) has not been implemented")
    }
    
    open func dequeueReusableCellWithReuseIdentifier(_ identifier: String) -> EndlessPageCell {
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
            let cell = cellClass.init(frame: bounds)
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
    
    fileprivate func updateBounds() {
        
        bounds = CGRect(origin: contentOffset, size: bounds.size)
        delegate?.endlessPageViewDidScroll(self)
    }
    
    fileprivate func updateCells() {
        let pageOffset = round(contentOffset / CGPoint(x: self.frame.width, y: self.frame.height)
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
                        cell.frame = CGRect(x: self.frame.width * CGFloat(column)
                                            , y: self.frame.height * CGFloat(row)
                                            , width: self.frame.width
                                            , height: self.frame.height)
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
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Endless page cell delegate
    
    internal func didSelectCell(_ cell: EndlessPageCell) {
        
        if let indexLocation = self.indexLocationForCell(cell) {
            delegate?.endlessPageViewDidSelectItemAtIndex(indexLocation)
        }
    }
}
