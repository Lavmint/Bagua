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
    public fileprivate(set) var changedKeys = Set<String>()
}

public class TransactionObserver {
    
    enum NotificationKeys: String {
        case transactionInfo
    }
    
    public var onWillExecuteTransaction: ((TransactionInfo) -> Void)?
    public var onDidExecuteTransaction: ((TransactionInfo) -> Void)?
    public var onWillSaveContext: ((NSManagedObjectContext) -> Void)?
    public var onDidChangeContextObjects: ((NSManagedObjectContext, ContextChangesInfo) -> Void)?
    public var onDidSaveContext: ((NSManagedObjectContext, ContextChangesInfo) -> Void)?
    
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
        onWillSaveContext?(notification.object! as! NSManagedObjectContext)
    }
    
    @objc private func didChangeContextObjects(_ notification: Notification) {
        let changes = collectContextChanges(from: notification)
        if let managedObjectContext = notification.object as? BaguaManagedObjectContext {
            managedObjectContext.changes = changes
        }
        onDidChangeContextObjects?(notification.object! as! NSManagedObjectContext, changes)
    }
    
    @objc private func didSaveContext(_ notification: Notification) {
        if let managedObjectContext = notification.object as? BaguaManagedObjectContext,
            let changes = managedObjectContext.changes,
            let context = managedObjectContext.context {
            onDidSaveContext?(managedObjectContext, changes)
            let info = TransactionInfo(context: context, managedObjectContext: managedObjectContext)
            let didExecuteTransactionNotification = Notification(
                name: .didExecuteTransaction,
                object: nil,
                userInfo: [TransactionObserver.NotificationKeys.transactionInfo.rawValue: info]
            )
            NotificationCenter.default.post(didExecuteTransactionNotification)
        } else {
            onDidSaveContext?(notification.object! as! NSManagedObjectContext, collectContextChanges(from: notification))
        }
    }
    
    private func collectContextChanges(from notification: Notification) -> ContextChangesInfo {
        
        guard let userInfo = notification.userInfo else {
            return ContextChangesInfo(inserts: [], updates: [], deletes: [], refreshes: [], invalidates: [], changedKeys: [])
        }
        
        var changes = ContextChangesInfo()
        var objects = Set<NSManagedObject>()
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            changes.inserts = inserts
            objects = objects.union(inserts)
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            changes.updates = updates
            objects = objects.union(updates)
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
            changes.deletes = deletes
            objects = objects.union(deletes)
        }
        
        if let invalidates = userInfo[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, invalidates.count > 0 {
            changes.invalidates = invalidates
            objects = objects.union(invalidates)
        }
        
        if let refreshes = userInfo[NSRefreshedObjectsKey] as? Set<NSManagedObject>, refreshes.count > 0 {
            changes.refreshes = refreshes
            objects = objects.union(refreshes)
        }
        
        for o in objects {
            changes.changedKeys = changes.changedKeys.union(o.changedValues().keys)
        }
        
        return changes
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

public extension ContextChangesInfo {
    
    public enum ChangeType: CaseIterable {
        case update
        case insert
        case invalidate
        case delete
        case refresh
    }
    
    public func trigger<T: Managed>(track: T.Type, forKeys keys: [String] = [], changes changeTypes: [ChangeType] = [], ids: [T.PrimaryKey] = [], _ block: @escaping (_ ids: [T.PrimaryKey]) -> Void) {
        
        let types = !changeTypes.isEmpty ? changeTypes : ChangeType.allCases
        var changes: [Set<NSManagedObject>] = []
        for t in types {
            switch t {
            case .update:
                changes.append(updates)
            case .insert:
                changes.append(inserts)
            case .invalidate:
                changes.append(invalidates)
            case .delete:
                changes.append(deletes)
            case .refresh:
                changes.append(refreshes)
            }
        }
        
        l1: for change in changes {
            for upd in change {
                
                guard let obj = upd as? T else { continue }
                
                var isConformedId = true
                var isConformedKey = true
                
                if !ids.isEmpty {
                    isConformedId = ids.contains(obj.primaryId)
                }
                
                if !keys.isEmpty {
                    var isChangedKey = false
                    for key in self.changedKeys {
                        if keys.contains(key) {
                            isChangedKey = true
                            break
                        }
                    }
                    isConformedKey = isChangedKey
                }
                
                if isConformedId && isConformedKey {
                    var tasks = Set<T>()
                    for ch in changes {
                        for obj in ch {
                            guard let o = obj as? T, obj.value(forKey: T.primaryKey()) != nil else { continue }
                            tasks.insert(o)
                        }
                    }
                    block(tasks.map({ $0.primaryId }))
                    break l1
                }
            }
        }
    }
    
}
