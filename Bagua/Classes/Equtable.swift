//
//  Equtable.swift
//  Bagua
//
//  Created by Alexey Averkin on 21/02/2019.
//

import Foundation

infix operator <?

public extension Equatable {
    
    public mutating func updateIfNeeded(newValue: Self) {
        if newValue != self {
            self = newValue
        }
    }
    
    public mutating func updateIfNeeded(newValue: Self?) {
        if let val = newValue, self != val {
            self = val
        }
    }
    
    public static func <? (lhs: inout Self, rhs: Self?) {
        if let val = rhs, lhs != val {
            lhs = val
        }
    }
    
    public static func <? (lhs: inout Self, rhs: Self) {
        if lhs != rhs {
            lhs = rhs
        }
    }
}
