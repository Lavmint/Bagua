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
    public let uuid: UUID
    internal let managedObjectContext: NSManagedObjectContext
}

public struct ContextChangesInfo {
    public fileprivate(set) var inserts = Set<NSManagedObject>()
    public fileprivate(set) var updates = Set<NSManagedObject>()
    public fileprivate(set) var deletes = Set<NSManagedObject>()
    public fileprivate(set) var refreshes = Set<NSManagedObject>()
    public fileprivate(set) var invalidates = Set<NSManagedObject>()
}

public protocol TransactionObservable: class {
    func onWillExecuteTransaction(info: TransactionInfo)
    func onDidExecuteTransaction(info: TransactionInfo)
    func onWillSaveContext(managedObjectContext: NSManagedObjectContext)
    func onDidChangeContextObjects(managedObjectContext: NSManagedObjectContext, changes: ContextChangesInfo)
    func onDidSaveContext(managedObjectContext: NSManagedObjectContext)
}

public extension TransactionObservable {
    public func onWillExecuteTransaction(info: TransactionInfo) {}
    public func onDidExecuteTransaction(info: TransactionInfo) {}
    public func onWillSaveContext(managedObjectContext: NSManagedObjectContext) {}
    public func onDidChangeContextObjects(managedObjectContext: NSManagedObjectContext, changes: ContextChangesInfo) {}
    public func onDidSaveContext(managedObjectContext: NSManagedObjectContext) {}
}

public class TransactionObserver {
    
    enum NotificationKeys: String {
        case transactionInfo
    }
    
    public weak var observable: TransactionObservable?
    
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
        observable?.onWillExecuteTransaction(info: info)
    }
    
    @objc private func didExecuteTransaction(_ notification: Notification) {
        let info = unboxTransactionInfo(from: notification)
        unsubscribe(context: info.managedObjectContext)
        observable?.onDidExecuteTransaction(info: info)
    }
    
    @objc private func willSaveContext(_ notification: Notification) {
        guard let managedObjectContext = notification.object as? NSManagedObjectContext else { return }
        observable?.onWillSaveContext(managedObjectContext: managedObjectContext)
    }
    
    @objc private func didChangeContextObjects(_ notification: Notification) {
        guard let managedObjectContext = notification.object as? NSManagedObjectContext else { return }
        observable?.onDidChangeContextObjects(managedObjectContext: managedObjectContext, changes: collectContextChanges(from: notification))
    }
    
    @objc private func didSaveContext(_ notification: Notification) {
        guard let managedObjectContext = notification.object as? NSManagedObjectContext else { return }
        observable?.onDidSaveContext(managedObjectContext: managedObjectContext)
    }
    
    private func collectContextChanges(from notification: Notification) -> ContextChangesInfo {
        
        guard let userInfo = notification.userInfo else {
            return ContextChangesInfo(inserts: [], updates: [], deletes: [], refreshes: [], invalidates: [])
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

public enum ChangeType: CaseIterable {
    case update
    case insert
    case invalidate
    case delete
    case refresh
}

public class Filter {
    
    let contextChanges: ContextChangesInfo
    private(set) var changedManagedObjects: Set<NSManagedObject>
    
    private(set) var changesFilterResult: Set<NSManagedObject>?
    private(set) var typeFilterResult: Set<NSManagedObject>?
    private(set) var valueFilterResult: Set<NSManagedObject>?
    
    init(contextChanges: ContextChangesInfo) {
        self.contextChanges = contextChanges
        self.changedManagedObjects = Set<NSManagedObject>()
        for t in ChangeType.allCases {
            switch t {
            case .update:
                changedManagedObjects = changedManagedObjects.union(contextChanges.updates)
            case .insert:
                changedManagedObjects = changedManagedObjects.union(contextChanges.inserts)
            case .invalidate:
                changedManagedObjects = changedManagedObjects.union(contextChanges.invalidates)
            case .delete:
                changedManagedObjects = changedManagedObjects.union(contextChanges.deletes)
            case .refresh:
                changedManagedObjects = changedManagedObjects.union(contextChanges.refreshes)
            }
        }
    }
    
    public func select(changes changeTypes: [ChangeType]) -> Filter {
        var changes: Set<NSManagedObject> = []
        for t in changeTypes {
            switch t {
            case .update:
                changes = changes.union(contextChanges.updates)
            case .insert:
                changes = changes.union(contextChanges.inserts)
            case .invalidate:
                changes = changes.union(contextChanges.invalidates)
            case .delete:
                changes = changes.union(contextChanges.deletes)
            case .refresh:
                changes = changes.union(contextChanges.refreshes)
            }
        }
        changesFilterResult = changes
        return self
    }
    
    public func select<T: Managed>(type: T.Type, ids: [T.PrimaryKey]? = nil) -> Filter {
        var typeFilterResult = Set<NSManagedObject>()
        for object in changedManagedObjects {
            guard let managed = object as? T else { continue }
            if let IDs = ids {
                if IDs.contains(managed.primaryId) {
                    typeFilterResult.insert(object)
                } else {
                    continue
                }
            } else {
                typeFilterResult.insert(object)
            }
        }
        self.typeFilterResult = typeFilterResult
        return self
    }
    
    public func select<T: Equatable>(value: T, forKey key: String) -> Filter {
        var valueFilterResult = Set<NSManagedObject>()
        for object in changedManagedObjects {
            guard let val = object.changedValues()[key] as? T else { continue }
            guard val == value else { continue }
            valueFilterResult.insert(object)
        }
        self.valueFilterResult = valueFilterResult
        return self
    }
    
    public func select(values: [String]) -> Filter {
        var valueFilterResult = Set<NSManagedObject>()
        for object in changedManagedObjects {
            var set = Set<String>(values)
            set = set.intersection(object.changedValues().keys)
            guard !set.isEmpty else { continue }
            valueFilterResult.insert(object)
        }
        self.valueFilterResult = valueFilterResult
        return self
    }
    
    public func resolve() -> Set<NSManagedObject>? {
        
        var result = Set<NSManagedObject>()
        
        if let filter = changesFilterResult {
            result = filter
        } else {
            result = changedManagedObjects
        }
        
        if let filter = typeFilterResult {
            result = result.intersection(filter)
        }
        
        if let filter = valueFilterResult {
            result = result.intersection(filter)
        }
        
        return result.isEmpty ? nil : result
    }
}

public extension ContextChangesInfo {
    
    public var filter: Filter {
        return Filter(contextChanges: self)
    }
}
