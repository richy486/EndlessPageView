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
    func endlessPageView(endlessPageView:EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell
}

public protocol EndlessPageViewDelegate : class {
    func endlessPageViewDidSelectItemAtIndex(index: Int)
    func endlessPageViewDidScroll(endlessPageView: EndlessPageView)
}


public enum EndlessPageScrollDirection {
    case Horizontal
    case Vertical
    case Both
}

public class EndlessPageView : UIView, UIGestureRecognizerDelegate {
    
    // - Public -
    
    // Protocols
    public weak var dataSource:EndlessPageViewDataSource?
    public weak var delegate:EndlessPageViewDelegate?
    
    // Public settings
    public var scrollDirection = EndlessPageScrollDirection.Both
    
    // - Private -
    
    // Offset position
    private(set) public var contentOffset = CGPoint.zero
    private var panStartContentOffset = CGPoint.zero
    
    // Cell pool
    private var cellPool = [String: [EndlessPageCell]]()
    private var registeredCellClasses = [String: EndlessPageCell.Type]()
    
    // Data cache
    private var visibleCells = [IndexLocation: EndlessPageCell]()
    
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
        
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !hasDoneFirstReload {
            hasDoneFirstReload = true
            reloadData()
        }
    }
    
    
    // MARK: Actions
    
    func panGesture_scroll(panGesture: UIPanGestureRecognizer) {
        
        if let gestureView = panGesture.view, let holder = gestureView.superview {
            
            let translatePoint = panGesture.translationInView(holder)
            
            
            if panGesture.state == UIGestureRecognizerState.Began {
                panStartContentOffset = contentOffset
            }
            
            if panGesture.state == UIGestureRecognizerState.Changed {
                contentOffset = {
                    var point = contentOffset
                    switch scrollDirection {
                    case .Horizontal:
                        point.x = (panStartContentOffset - translatePoint).x
                    case .Vertical:
                        point.y = (panStartContentOffset - translatePoint).y
                    case .Both:
                        point = (panStartContentOffset - translatePoint)
                    }
                    
                    return point
                }()
            }
            
            if panGesture.state == UIGestureRecognizerState.Ended {
                
                let velocity = panGesture.velocityInView(holder) * -1
                let magnitude = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
                let slideMult = magnitude / 200
                
                let slideFactor = 0.1 * slideMult
                
                
                let finalPoint:CGPoint = {
                    var point = CGPoint.zero
                    switch scrollDirection {
                    case .Horizontal:
                        point = CGPoint(x: contentOffset.x + (velocity.x * slideFactor), y: contentOffset.y)
                    case .Vertical:
                        point = CGPoint(x: contentOffset.x, y: contentOffset.y + (velocity.y * slideFactor))
                    case .Both:
                        point = CGPoint(x: contentOffset.x + (velocity.x * slideFactor), y: contentOffset.y + (velocity.y * slideFactor))
                    }
                    
                    return point
                }()
                
                
                if let offsetChangeAnimation = offsetChangeAnimation {
                    offsetChangeAnimation.stopAnimation()
                    offsetChangeAnimation.invalidate()
                }
                offsetChangeAnimation = Interpolate(from: contentOffset
                    , to: finalPoint
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
                offsetChangeAnimation?.animate(duration: slideFactor * 2)
            }
            
            updateBounds()
            updateCells()
        }
        
    }
    
    // MARK: Data cache
    
    public func reloadData() {
        contentOffset = CGPoint.zero
        updateBounds()
        updateCells()
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
                    return cell
                }
            }
        }
        
        if let cellClass = registeredCellClasses[identifier] {
            let cell = cellClass.init()
            cellPool[identifier]?.append(cell)
            
            print("generated cell for identifer: \(identifier), pool size: ", cellPool[identifier]?.count)
            
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
        let pageOffset = contentOffset / CGPoint(x: CGRectGetWidth(self.frame), y: CGRectGetHeight(self.frame))
        
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
                    updatedVisibleCellIndexLocations.append(indexLocation)
                    
                    let cell:EndlessPageCell? = {
                        if let cell = visibleCells[indexLocation] {
                            return cell
                        } else if let cell = dataSource?.endlessPageView(self, cellForIndexLocation: indexLocation) {
                            visibleCells[indexLocation] = cell
                            addSubview(cell)
                            return cell
                        }
                        
                        return nil
                    }()
                    
                    if let cell = cell {
                        cell.frame = CGRect(x: CGRectGetWidth(self.frame) * CGFloat(column)
                            , y: CGRectGetHeight(self.frame) * CGFloat(row)
                            , width: CGRectGetWidth(self.frame)
                            , height: CGRectGetHeight(self.frame))
                    }
                }
            }
            
            let oldCount = visibleCells.count
            
            let previousKeys = visibleCells.keys
            let removedKeys = previousKeys.filter( { !updatedVisibleCellIndexLocations.contains($0) } )
            
            removedKeys.forEach({ (indexLocation) in
                visibleCells[indexLocation]?.removeFromSuperview()
                visibleCells[indexLocation] = nil
            })
            
            if oldCount != visibleCells.count {
                print("removed \(oldCount - visibleCells.count) cells")
            }
        }
    }
    
    
    // MARK: Gesture delegate
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}