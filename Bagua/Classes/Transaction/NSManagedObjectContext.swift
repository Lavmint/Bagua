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
    
    public func performWithThrowable(_ block: @escaping () throws -> Void) {
        perform {
            do {
                try block()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    public func performAndWaitWithThrowable(_ block: () throws -> Void) {
        performAndWait {
            do {
                try block()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}

public extension NSPersistentContainer {
    
    public func performThrowableBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) {
        performBackgroundTask { (context) in
            do {
                try block(context)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
