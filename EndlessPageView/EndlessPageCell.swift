//
//  EndlessPageCell.swift
//  EndlessPageView
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import UIKit

internal protocol _EndlessPageCellDelegate {
    func didSelectCell(cell: EndlessPageCell)
}

public class EndlessPageCell : UIView, UIGestureRecognizerDelegate {
    
    internal var privateDelegate:_EndlessPageCellDelegate?
    
    override public init(frame: CGRect) {
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
    
    private func setup() {
    
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture_select(_:)))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: Gestures
    
    func tapGesture_select(tapGesture: UITapGestureRecognizer) {
        privateDelegate?.didSelectCell(self)
    }
}
