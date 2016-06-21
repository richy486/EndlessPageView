//: Playground - noun: a place where people can play

import UIKit
import EndlessPageView

import XCPlayground


class Client : EndlessPageViewDataSource, EndlessPageViewDelegate {
    
    
    
    // Datasource
    func endlessPageView(endlessPageView: EndlessPageView, cellForIndexLocation indexLocation: IndexLocation) -> EndlessPageCell {
        
        let cell = endlessPageView.dequeueReusableCellWithReuseIdentifier("cell")
        cell.backgroundColor = UIColor(hue: 1.0 - (CGFloat(indexLocation.row) / 10)
            , saturation: 0.75
            , brightness: 1.0 - (CGFloat(indexLocation.column) / 10)
            , alpha: 1.0)
        
        print("location: \(indexLocation), color: \(cell.backgroundColor)")
        
        return cell
    }
    
    // Delegate
    func endlessPageViewDidSelectItemAtIndex(index: Int) {
    }
    func endlessPageViewDidScroll(loopScrollView: EndlessPageView) {
    }
    
}

let endlesssPageView = EndlessPageView(frame: CGRectMake(0,0,320,575))
//endlesssPageView.contentSize = CGSize(width: 400,height: 400)
endlesssPageView.backgroundColor = UIColor.whiteColor()
endlesssPageView.registerClass(EndlessPageCell.self, forViewWithReuseIdentifier: "cell")

let client = Client()
endlesssPageView.delegate = client
endlesssPageView.dataSource = client

endlesssPageView.reloadData()

XCPlaygroundPage.currentPage.liveView = endlesssPageView
