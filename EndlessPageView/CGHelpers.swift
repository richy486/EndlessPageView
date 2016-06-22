//
//  CGHelpers.swift
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import Foundation



// CGFloat

func round(value: CGFloat, tollerence:CGFloat)-> CGFloat {
    if fabs(value) % 1.0 < tollerence || fabs(value) % 1.0 > 1.0 - tollerence {
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
    
    return CGPointMake(left.x + right.x, left.y + right.y)
}
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPointMake(left.x - right.x, left.y - right.y)
}
func * (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPointMake(left.x * right.x, left.y * right.y)
}
func / (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPointMake(left.x / right.x, left.y / right.y)
}

func % (left: CGPoint, right: CGPoint) -> CGPoint {
    
    return CGPointMake(left.x % right.x, left.y % right.y)
}

func += (inout left: CGPoint, right: CGPoint) {
    left = left + right
}
func -= (inout left: CGPoint, right: CGPoint) {
    left = left - right
}
func *= (inout left: CGPoint, right: CGPoint) {
    left = left * right
}
func /= (inout left: CGPoint, right: CGPoint) {
    left = left / right
}


func * (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPointMake(left.x * right, left.y * right)
}
func / (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPointMake(left.x / right, left.y / right)
}
func + (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPointMake(left.x + right, left.y + right)
}
func - (left: CGPoint, right: CGFloat) -> CGPoint {
    
    return CGPointMake(left.x - right, left.y - right)
}

func floor(point:CGPoint) -> CGPoint {
    return CGPointMake(floor(point.x), floor(point.y))
}

func round(value: CGPoint, tollerence:CGFloat)-> CGPoint {
    return CGPoint(x: round(value.x, tollerence: tollerence)
        , y: round(value.y, tollerence: tollerence))
}

// CGSize

func + (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSizeMake(left.width + right.width, left.height + right.height)
}
func - (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSizeMake(left.width - right.width, left.height - right.height)
}
func * (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSizeMake(left.width * right.width, left.height * right.height)
}
func / (left: CGSize, right: CGSize) -> CGSize {
    
    return CGSizeMake(left.width / right.width, left.height / right.height)
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    
    return CGSizeMake(left.width / right, left.height / right)
}

// CGSize v CGPoint

func sizeToPoint(size: CGSize) -> CGPoint {
    return CGPointMake(size.width, size.height)
}

func * (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x * right.width, left.y * right.height)
}
func / (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x / right.width, left.y / right.height)
}
func + (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x + right.width, left.y + right.height)
}
func - (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x - right.width, left.y - right.height)
}