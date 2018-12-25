//
//  Equatable.swift
//  LennyData
//
//  Created by Alexey Averkin on 18/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

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
}
