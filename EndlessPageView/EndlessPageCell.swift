//
//  EndlessPageCell.swift
//  EndlessPageView
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import UIKit

internal protocol _EndlessPageCellDelegate {
    func didSelectCell(_ cell: EndlessPageCell)
}

open class EndlessPageCell : UIView, UIGestureRecognizerDelegate {
    
    internal var privateDelegate:_EndlessPageCellDelegate?
    
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required public convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
    
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture_select(_:)))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: Gestures
    
    func tapGesture_select(_ tapGesture: UITapGestureRecognizer) {
        privateDelegate?.didSelectCell(self)
    }
    
    // MARK: Memory management
    
    open func prepareForReuse() {
    }
}
