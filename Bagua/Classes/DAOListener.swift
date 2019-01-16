//
//  DAOListener.swift
//  Bagua
//
//  Created by Alexey Averkin on 16/01/2019.
//

import Foundation
import CoreData

extension Notification.Name {
    static let willExecuteTransaction = Notification.Name("bagua.willExecuteTransaction")
    static let didExecuteTransaction = Notification.Name("bagua.didExecuteTransaction")
}

public struct TransactionInfo {
    public let context: Context
    public let managedObjectContext: NSManagedObjectContext
}

public struct ContextChangesInfo {
    public fileprivate(set) var inserts = Set<NSManagedObject>()
    public fileprivate(set) var updates = Set<NSManagedObject>()
    public fileprivate(set) var deletes = Set<NSManagedObject>()
    public fileprivate(set) var refreshes = Set<NSManagedObject>()
    public fileprivate(set) var invalidates = Set<NSManagedObject>()
}

public class DAOListener {
    
    enum NotificationKeys: String {
        case transactionInfo
    }
    
    public var onWillExecuteTransaction: ((TransactionInfo) -> Void)?
    public var onDidExecuteTransaction: ((TransactionInfo) -> Void)?
    public var onWillSaveContext: (() -> Void)?
    public var onDidChangeContextObjects: ((ContextChangesInfo) -> Void)?
    public var onDidSaveContext: (() -> Void)?
    
    public init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willExecuteTransaction),
            name: .willExecuteTransaction,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didExecuteTransaction),
            name: .didExecuteTransaction,
            object: nil
        )
    }
    
    @objc private func willExecuteTransaction(_ notification: Notification) {
        let info = unboxTransactionInfo(from: notification)
        subscribe(context: info.managedObjectContext)
        onWillExecuteTransaction?(info)
    }
    
    @objc private func didExecuteTransaction(_ notification: Notification) {
        let info = unboxTransactionInfo(from: notification)
        unsubscribe(context: info.managedObjectContext)
        onDidExecuteTransaction?(info)
    }
    
    @objc private func willSaveContext(_ notification: Notification) {
        onWillSaveContext?()
    }
    
    @objc private func didChangeContextObjects(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        var changes = ContextChangesInfo()
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            changes.inserts = inserts
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            changes.updates = updates
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
            changes.deletes = deletes
        }
        
        if let invalidates = userInfo[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, invalidates.count > 0 {
            changes.invalidates = invalidates
        }
        
        if let refreshes = userInfo[NSRefreshedObjectsKey] as? Set<NSManagedObject>, refreshes.count > 0 {
            changes.refreshes = refreshes
        }
        
        onDidChangeContextObjects?(changes)
    }
    
    @objc private func didSaveContext(_ notification: Notification) {
        onDidSaveContext?()
    }
    
    private func unboxTransactionInfo(from notification: Notification) -> TransactionInfo {
        return notification.userInfo?[NotificationKeys.transactionInfo.rawValue] as! TransactionInfo
    }
    
    private func subscribe(context: NSManagedObjectContext) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willSaveContext),
            name: .NSManagedObjectContextWillSave,
            object: context
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didChangeContextObjects),
            name: .NSManagedObjectContextObjectsDidChange,
            object: context
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didSaveContext),
            name: .NSManagedObjectContextDidSave,
            object: context
        )
    }
    
    private func unsubscribe(context: NSManagedObjectContext) {
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextWillSave, object: context)
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: context)
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextDidSave, object: context)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
