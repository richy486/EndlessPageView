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
        endlessPageView.scrollDirection = .Both
        endlessPageView.pagingEnabled = true
        endlessPageView.directionalLockEnabled = true
        view.addSubview(endlessPageView)
        
        endlessPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        endlessPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        endlessPageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        endlessPageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("shake")
            
            if endlessPageView.contentOffset.x < 1 && endlessPageView.contentOffset.y < 1 {
                endlessPageView.scrollToItemAtIndexLocation(IndexLocation(column: 33, row: 44), animated: true)
            } else {
            
                endlessPageView.setContentOffset(CGPoint.zero, animated: true)
            }
            
        }
    }
    
    // MARK: Endless page view datasource
    func endlessPageView(_ endlessPageView:EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell? {
        
        let cell = endlessPageView.dequeueReusableCellWithReuseIdentifier("cell")
        cell.backgroundColor = UIColor(hue: CGFloat(1.0 - fabs(Float(indexLocation.row) / 10).truncatingRemainder(dividingBy: 1))
            , saturation: 0.75
            , brightness: CGFloat(1.0 - fabs(Float(indexLocation.column) / 10).truncatingRemainder(dividingBy: 1))
            , alpha: 1.0)
        
        print("cellForIndexLocation: \(indexLocation), color: \(cell.backgroundColor)")
        
        return cell
    }
    
    // MARK: Endless page view delegate
    func endlessPageViewDidSelectItemAtIndex(_ indexLocation: IndexLocation) {
        print("selected: \(indexLocation)")
    }
    public func endlessPageViewWillScroll(_ endlessPageView: EndlessPageView) {
        
    }
    func endlessPageViewDidScroll(_ endlessPageView: EndlessPageView) {
        
        //print(String(format: "%.02f, %.02f", endlessPageView.contentOffset.x, endlessPageView.contentOffset.y))
    }
    func endlessPageViewShouldScroll(_ endlessPageView: EndlessPageView, scrollingDirection: EndlessPageScrollDirectionRules) -> EndlessPageScrollDirectionRules {
        return EndlessPageScrollDirectionRules.Both.intersection(scrollingDirection)
    }
    func endlessPageView(_ endlessPageView: EndlessPageView, willDisplayCell cell: EndlessPageCell, forItemAtIndexLocation indexLocation: IndexLocation) {
        print("willDisplayCell: \(cell), at: \(indexLocation)")
    }
    func endlessPageView(_ endlessPageView: EndlessPageView, didEndDisplayingCell cell: EndlessPageCell, forItemAtIndexLocation indexLocation: IndexLocation) {
        print("didEndDisplayingCell: \(cell), at: \(indexLocation)")
    }
    func endlessPageViewDidEndDecelerating(_ endlessPageView: EndlessPageView) {
        print("endlessPageViewDidEndDecelerating")
        
        print("visible cells: \(endlessPageView.visibleCells())")
        print("index locations for visible items: \(endlessPageView.indexLocationsForVisibleItems())")
        
        if let point = endlessPageView.indexLocationForItemAtPoint(endlessPageView.contentOffset) {
            print("index location for item at point: \(point)")
        }
        
        if let indexLocation = endlessPageView.indexLocationFromContentOffset() {
            print("index location for content offset: \(indexLocation)")
        }
        
        if let firstCell = endlessPageView.visibleCells().first {
            print("index location for cell: \(endlessPageView.indexLocationForCell(firstCell))")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

