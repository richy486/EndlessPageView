//
//  ViewController.swift
//  EndlessPagingExample
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import UIKit
import EndlessPageView

class ViewController: UIViewController, EndlessPageViewDataSource, EndlessPageViewDelegate {
    
    let endlessPageView = EndlessPageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        endlessPageView.translatesAutoresizingMaskIntoConstraints = false
        endlessPageView.dataSource = self
        endlessPageView.delegate = self
        endlessPageView.registerClass(EndlessPageCell.self, forViewWithReuseIdentifier: "cell")
        endlessPageView.clipsToBounds = true
        view.addSubview(endlessPageView)
        
        endlessPageView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        endlessPageView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        
        endlessPageView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        endlessPageView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        
        
    }
    
    // MARK: Endless page view datasource
    func endlessPageView(endlessPageView: EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell {
        
        let cell = endlessPageView.dequeueReusableCellWithReuseIdentifier("cell")
        cell.backgroundColor = UIColor(hue: 1.0 - (CGFloat(indexLocation.row) / 10) % 1
            , saturation: 0.75
            , brightness: 1.0 - (CGFloat(indexLocation.column) / 10) % 1
            , alpha: 1.0)
        
        print("location: \(indexLocation), color: \(cell.backgroundColor)")
        
        return cell
    }
    
    // MARK: Endless page view delegate
    func endlessPageViewDidSelectItemAtIndex(index: Int) {
    }
    func endlessPageViewDidScroll(loopScrollView: EndlessPageView) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

