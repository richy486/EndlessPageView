//
//  CGHelpers.swift
//
//  Created by Richard Adem on 6/21/16.
//  Copyright © 2016 Richard Adem. All rights reserved.
//

import Foundation

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

func / (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x / right.width, left.y / right.width)
}
func + (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x + right.width, left.y + right.width)
}
func - (left: CGPoint, right: CGSize) -> CGPoint {
    
    return CGPointMake(left.x - right.width, left.y - right.width)
}