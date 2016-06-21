//
//  EndlessPageView.swift
//  EndlessPageView
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import UIKit

struct IndexLocation : Hashable {
    var column:Int
    var row:Int
    
    var hashValue: Int {
        return column.hashValue | (row.hashValue << 32)
    }
    
    init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
}
func == (lhs: IndexLocation, rhs: IndexLocation) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

protocol EndlessPageViewDataSource : class {
    func endlessPageView(endlessPageView:EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell
}

protocol EndlessPageViewDelegate : class {
    func endlessPageViewDidSelectItemAtIndex(index: Int)
    func endlessPageViewDidScroll(loopScrollView: EndlessPageView)
}


enum EndlessPageScrollDirection {
    case Horizontal
    case Vertical
    case Both
}

class EndlessPageView : UIView, UIGestureRecognizerDelegate {
    
    // Protocols
    weak var dataSource:EndlessPageViewDataSource?
    weak var delegate:EndlessPageViewDelegate?
    
    // Offset position
    private(set) var contentOffset = CGPoint.zero
    private var panStartContentOffset = CGPoint.zero
    
    // Cell pool
    private var cellPool = [String: [EndlessPageCell]]()
    private var registeredCellClasses = [String: EndlessPageCell.Type]()
    
    // Data cache
    private var visibleCells = [IndexLocation: EndlessPageCell]()
    
    var scrollDirection = EndlessPageScrollDirection.Both
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture_scroll(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
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
            
            self.bounds = CGRect(origin: contentOffset, size: self.bounds.size)
            
            
            updateCells()
        }
        
    }
    
    // MARK: Data cache
    
    func reloadData() {
        updateCells()
    }
    
    func registerClass(cellClass: EndlessPageCell.Type?, forViewWithReuseIdentifier identifier: String) {
        
        registeredCellClasses[identifier] = cellClass
    }
    func registerNib(nib: UINib?, forViewWithReuseIdentifier identifier: String) {
        fatalError("registerNib(nib:forViewWithReuseIdentifier:) has not been implemented")
    }
    
    func dequeueReusableCellWithReuseIdentifier(identifier: String) -> EndlessPageCell {
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
            
            return cell
        }
        
        fatalError(String(format: "Did not register class %@ for EndlessPageView ", identifier))
    }
    
    
    // MARK: Update cells
    
    private func updateCells() {
        let pageOffset = contentOffset / CGPoint(x: CGRectGetWidth(self.frame), y: CGRectGetHeight(self.frame))
        let rows = floor(pageOffset.x) == pageOffset.x ? [Int(pageOffset.x)] : [Int(pageOffset.x), Int(pageOffset.x + 1)]
        let columns = floor(pageOffset.y) == pageOffset.y ? [Int(pageOffset.y)] : [Int(pageOffset.y), Int(pageOffset.y + 1)]
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
                    cell.frame = CGRect(x: CGRectGetWidth(self.frame) * CGFloat(row)
                        , y: CGRectGetHeight(self.frame) * CGFloat(column)
                        , width: CGRectGetWidth(self.frame)
                        , height: CGRectGetHeight(self.frame))
                }
            }
        }
        
        visibleCells = visibleCells.filter({ updatedVisibleCellIndexLocations.contains($0.0) })
    }
    
    
    // MARK: Gesture delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}