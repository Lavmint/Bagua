//
//  Transaction.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public enum Context {
    case view
    case background
    case unsafeBackground(managedObjectContext: NSManagedObjectContext)
}

public class Transaction {
    
    public let context: Context
    public let container: NSPersistentContainer
    public let managedObjectContext: NSManagedObjectContext
    
    ///will be inited only if needed
    public lazy var observer: TransactionObserver = {
        return TransactionObserver()
    }()
    
    public init(context: Context, container: NSPersistentContainer) {
        self.context = context
        self.container = container
        switch context {
        case .view:
            managedObjectContext = container.viewContext
        case .background:
            let managedObjectContext = BaguaManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.context = .background
            managedObjectContext.persistentStoreCoordinator = container.persistentStoreCoordinator
            self.managedObjectContext = managedObjectContext
        case .unsafeBackground(managedObjectContext: let c):
            managedObjectContext = c
        }
    }
    
    public func perform(block: @escaping (_ transaction: Transaction) throws -> Void) {
        managedObjectContext.perform {
            do {
                try self.main(block: block)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    public func performAndWait(block: (_ transaction: Transaction) throws -> Void) {
        managedObjectContext.performAndWait {
            do {
                try main(block: block)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    private func main(block: (_ transaction: Transaction) throws -> Void) throws {
        switch context {
        case .view:
            try block(self)
            try commit()
        default:
            let info = TransactionInfo(context: context, managedObjectContext: managedObjectContext)
            let willExecuteTransactionNotification = Notification(
                name: .willExecuteTransaction,
                object: nil,
                userInfo: [TransactionObserver.NotificationKeys.transactionInfo.rawValue: info]
            )

            NotificationCenter.default.post(willExecuteTransactionNotification)
            try block(self)
            try commit()
        }
        
    }
    
    private func commit() throws {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                managedObjectContext.rollback()
                throw error
            }
        } else {
            let info = TransactionInfo(context: context, managedObjectContext: managedObjectContext)
            let didExecuteTransactionNotification = Notification(
                name: .didExecuteTransaction,
                object: nil,
                userInfo: [TransactionObserver.NotificationKeys.transactionInfo.rawValue: info]
            )
            NotificationCenter.default.post(didExecuteTransactionNotification)
        }
    }
}
