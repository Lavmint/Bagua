//
//  BaguaManagedObjectContext.swift
//  Bagua
//
//  Created by Alexey Averkin on 01/03/2019.
//

import CoreData

public class BGManagedObjectContext: NSManagedObjectContext {
    public var changes: ContextChangesInfo?
}

public class BGPersistentContainer: NSPersistentContainer {
    
    public override func newBackgroundContext() -> NSManagedObjectContext {
        let managedObjectContext = BGManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }
}

public extension NSManagedObjectContext {
    
    public func transaction(_ block: @escaping (_ t: Transaction) throws -> Void) {
        let policy = (self.mergePolicy as? NSMergePolicy)?.mergeType
        self.mergePolicy = NSMergePolicy(merge:.mergeByPropertyStoreTrumpMergePolicyType)
        let t = Transaction(managedObjectContext: self)
        do {
            try t.main(block: block)
        } catch {
            assertionFailure(error.localizedDescription)
        }
        self.mergePolicy = policy == nil ? self.mergePolicy : NSMergePolicy(merge: policy!)
    }
    
    public func perform(_ block: @escaping (_ t: Transaction) throws -> Void) {
        perform {
            self.transaction(block)
        }
    }
    
    public func performAndWait(_ block: @escaping (_ t: Transaction) throws -> Void) {
        performAndWait {
            self.transaction(block)
        }
    }
}
