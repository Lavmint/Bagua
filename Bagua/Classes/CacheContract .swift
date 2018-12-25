//
//  CachingContract.swift
//  CoreDeputy
//
//  Created by Alexey Averkin on 22/12/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import Foundation

public protocol OutputCacheContract {
    associatedtype Input: InputCacheContract
    func update(with object: Input) throws
}

public extension OutputCacheContract where Self == Input.Output {
    public var object: Input? {
        return Input.init(mo: self)
    }
}

public protocol InputCacheContract {
    associatedtype Output: Managed & OutputCacheContract
    var managedId: Output.PrimaryKey { get }
    init?(mo: Output)
}
