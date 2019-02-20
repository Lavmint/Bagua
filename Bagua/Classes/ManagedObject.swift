//
//  ManagedObject.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public protocol ManagedObject: class {
    associatedtype PrimaryKey: CVarArg & Hashable
    static func primaryKey() -> String
    var primaryId: PrimaryKey { get set }
}

public typealias Managed = NSManagedObject & ManagedObject
