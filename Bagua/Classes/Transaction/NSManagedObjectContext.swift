//
//  BaguaManagedObjectContext.swift
//  Bagua
//
//  Created by Alexey Averkin on 01/03/2019.
//

import CoreData

public extension NSManagedObjectContext {
    
    public var bga: Transaction {
        return Transaction(managedObjectContext: self)
    }
    
    public func write(_ block: @escaping (_ t: WriteTransaction) throws -> Void) {
        let policy = (self.mergePolicy as? NSMergePolicy)?.mergeType
        self.mergePolicy = NSMergePolicy(merge:.mergeByPropertyStoreTrumpMergePolicyType)
        let w = WriteTransaction(managedObjectContext: self)
        do {
            try w.main(block: { (t) in
                try block(w)
            })
        } catch {
            assertionFailure(error.localizedDescription)
        }
        self.mergePolicy = policy == nil ? self.mergePolicy : NSMergePolicy(merge: policy!)
    }
    
    public func perform(_ block: @escaping () throws -> Void) {
        do {
            try block()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    public func performAndWait(_ block: () throws -> Void) {
        do {
            try block()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

public extension NSPersistentContainer {
    
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) {
        do {
            try block(newBackgroundContext())
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}
