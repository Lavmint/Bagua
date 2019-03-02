//
//  BaguaManagedObjectContext.swift
//  Bagua
//
//  Created by Alexey Averkin on 01/03/2019.
//

import CoreData

public class BGManagedObjectContext: NSManagedObjectContext {
    public var context: Context?
    public var changes: ContextChangesInfo?
}

public class BGPersistentContainer: NSPersistentContainer {
    
    public override func newBackgroundContext() -> NSManagedObjectContext {
        let managedObjectContext = BGManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.context = .background
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }
}

public extension NSManagedObjectContext {
    
    public func perform(_ block: @escaping (_ t: Transaction) throws -> Void) {
        perform {
//            let t = Transaction(context: .background, container: )
//            do {
//                try block(t)
//            } catch {
//
//            }
        }
    }
    
    public func performAndWait(_ block: @escaping (_ t: Transaction) throws -> Void) {
        performAndWait {
            //
        }
    }
}
