//
//  ManagedObject.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public protocol ManagedObject: class {
    associatedtype PrimaryKey: CVarArg & Equatable
    static func primaryKey() -> String
    var primaryId: PrimaryKey { get set }
}

public typealias Managed = NSManagedObject & ManagedObject

public extension ManagedObject where Self: NSManagedObject {
    
    func newTransaction(in db: DAO, ctx: NSManagedObjectContext) -> Transaction {
        return Transaction(container: db.container, ctx: ctx)
    }
    
    func newWriteTransaction(in db: DAO, ctx: NSManagedObjectContext) -> WriteTransaction {
        return WriteTransaction(container: db.container, ctx: ctx)
    }
}
