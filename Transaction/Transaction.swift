//
//  Transaction.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public class Transaction {
    
    public let uuid: UUID
    public let managedObjectContext: NSManagedObjectContext
    
    ///will be inited only if needed
    public lazy var observer: TransactionObserver = {
        return TransactionObserver()
    }()
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.uuid = UUID()
    }
    
    internal func main(block: (_ transaction: Transaction) throws -> Void) throws {
        if managedObjectContext.concurrencyType == .mainQueueConcurrencyType {
            try block(self)
            try commit()
        } else {
            let info = TransactionInfo(uuid: uuid, managedObjectContext: managedObjectContext)
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
        }
        
        let info = TransactionInfo(uuid: uuid, managedObjectContext: managedObjectContext)
        let didExecuteTransactionNotification = Notification(
            name: .didExecuteTransaction,
            object: nil,
            userInfo: [TransactionObserver.NotificationKeys.transactionInfo.rawValue: info]
        )
        NotificationCenter.default.post(didExecuteTransactionNotification)
    }
}
