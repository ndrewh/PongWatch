//
//  Utilities.swift
//  PongWatch
//
//  Created by Andrew H on 6/12/15.
//  Copyright © 2015 Andrew H. All rights reserved.
//

import WatchKit

class Utilities: NSObject {

}

extension CGVector {
    mutating func inverseVectorY() {
        dy = -dy;
    }
    
    mutating func inverseVectorX() {
        dx = -dx;
    }
}
