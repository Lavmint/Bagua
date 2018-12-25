//
//  Array.swift
//  Bagua
//
//  Created by Alexey Averkin on 10/12/2018.
//  Copyright © 2018 SMASS.tech. All rights reserved.
//

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
