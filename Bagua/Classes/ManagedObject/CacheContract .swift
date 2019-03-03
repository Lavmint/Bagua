//
//  CachingContract.swift
//  CoreDeputy
//
//  Created by Alexey Averkin on 22/12/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import Foundation
import CoreData

public protocol OutputCacheContract {
    associatedtype Input: InputCacheContract
    func update(with object: Input, in transaction: Transaction) throws
}

public extension OutputCacheContract where Self == Input.Output {
    
    public var object: Input? {
        return Input.init(mo: self)
    }
}

public protocol InputCacheContract: Hashable, CustomStringConvertible {
    associatedtype Output: Managed & OutputCacheContract
    var managedId: Output.PrimaryKey { get }
    init?(mo: Output)
}

extension InputCacheContract {
    
    public var hashValue: Int {
        return managedId.hashValue
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.managedId == rhs.managedId
    }
    
    public var description: String {
        let properties = Mirror(reflecting: self).children.map({ (child) -> String in
            guard let name = child.label else { return "" }
            return "\t\(name): \(child.value)"
        }).joined(separator: "\n")
        return "\n{\n\(properties)\n}"
    }
    
}
