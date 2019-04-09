//
//  Equtable.swift
//  Bagua
//
//  Created by Alexey Averkin on 21/02/2019.
//

import Foundation

infix operator <?

public extension Optional where Wrapped: Equatable {
    
    static func <? (lhs: inout Optional<Wrapped>, rhs: Optional<Wrapped>) {
        guard rhs != nil else { return }
        if lhs != rhs {
            lhs = rhs
        }
    }
}

public extension Equatable {
    
    static func <? (lhs: inout Self, rhs: Self?) {
        if let val = rhs, lhs != val {
            lhs = val
        }
    }
    
    static func <? (lhs: inout Self, rhs: Self) {
        if lhs != rhs {
            lhs = rhs
        }
    }
}
