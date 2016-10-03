//
//  CGHelpers.swift
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import Foundation



// CGFloat

func round(_ value: CGFloat, tollerence:CGFloat)-> CGFloat {
    if fabs(value).truncatingRemainder(dividingBy: 1.0) < tollerence || fabs(value).truncatingRemainder(dividingBy: 1.0) > 1.0 - tollerence {
        return round(value)
    }
    return value
}

extension CGFloat {
    public static var pi: CGFloat {
        get {
            return CGFloat(M_PI)
        }
    }
    public static var pi2: CGFloat {
        get {
            return CGFloat(M_PI/2)
        }
    }
    
    
}

// CGPoint

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
func * (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}
func / (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
}

func % (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPoint(x: left.x.truncatingRemainder(dividingBy: right.x), y: left.y.truncatingRemainder(dividingBy: right.y))
}

func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}
func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}
func *= (left: inout CGPoint, right: CGPoint) {
    left = left * right
}
func /= (left: inout CGPoint, right: CGPoint) {
    left = left / right
}


func * (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPoint(x: left.x * right, y: left.y * right)
}
func / (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPoint(x: left.x / right, y: left.y / right)
}
func + (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPoint(x: left.x + right, y: left.y + right)
}
func - (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPoint(x: left.x - right, y: left.y - right)
}

func floor(_ point:CGPoint) -> CGPoint {
    return CGPoint(x: floor(point.x), y: floor(point.y))
}

func round(_ value: CGPoint, tollerence:CGFloat)-> CGPoint {
    return CGPoint(x: round(value.x, tollerence: tollerence)
        , y: round(value.y, tollerence: tollerence))
}

// CGSize

func + (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSize(width: left.width + right.width, height: left.height + right.height)
}
func - (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSize(width: left.width - right.width, height: left.height - right.height)
}
func * (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSize(width: left.width * right.width, height: left.height * right.height)
}
func / (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSize(width: left.width / right.width, height: left.height / right.height)
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    
    return CGSize(width: left.width / right, height: left.height / right)
}

// CGSize v CGPoint

func sizeToPoint(_ size: CGSize) -> CGPoint {
    return CGPoint(x: size.width, y: size.height)
}

func * (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPoint(x: left.x * right.width, y: left.y * right.height)
}
func / (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPoint(x: left.x / right.width, y: left.y / right.height)
}
func + (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPoint(x: left.x + right.width, y: left.y + right.height)
}
func - (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPoint(x: left.x - right.width, y: left.y - right.height)
}
