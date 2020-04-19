//
//  PictureRemark.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/3/13.
//  Copyright © 2020 Mike. All rights reserved.
//
import UIKit

class PictureRemark: NSObject {
    
    var locolID: String
    var text: String
    var colorString: String
    var size: Int
    var locationX: Double
    var locationY: Double
    
    init(locolIdentifier: String, text: String, colorString: String, size: Int, X: Double, Y: Double) {
        self.locolID = locolIdentifier
        self.text = text
        self.colorString = colorString
        self.size = size
        self.locationX = X
        self.locationY = Y
    }
    
}
