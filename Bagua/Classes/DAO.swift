//
//  Storage.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public enum Context {
    case view
    case background
    case unsafeBackground(ctx: NSManagedObjectContext)
}

public protocol TransactionDelegate: class {
    func willExecuteTransaction(in context: NSManagedObjectContext, ofType ctx: Context)
    func didExecuteTransaction(in context: NSManagedObjectContext, ofType ctx: Context)
    func willSaveCtx(notification: Notification)
    func didChangeCtxObjects(notification: Notification)
    func didSaveCtx(notification: Notification)
}

open class DAO {
    
    internal let container: NSPersistentContainer
    public weak var delegate: TransactionDelegate?
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    private func execute(ctx: Context, context: NSManagedObjectContext, block: ((_ t: Transaction) throws -> Void)) throws  {
        willExecuteTransaction(in: context, ofType: ctx)
        try block(Transaction(container: container, ctx: context))
        didExecuteTransaction(in: context, ofType: ctx)
    }
    
    public func sync(ctx: Context, _ block: ((_ w: Transaction) throws -> Void)) throws {
        switch ctx {
        case .view:
            try execute(ctx: ctx, context: container.viewContext, block: block)
        case .background:
            try execute(ctx: ctx, context: container.newBackgroundContext(), block: block)
        case .unsafeBackground(ctx: let context):
            try execute(ctx: ctx, context: context, block: block)
        }
    }
    
    public func async(await: ((Error?) -> Void)? = nil, ctx: Context, _ block: @escaping ((_ w: Transaction) throws -> Void)) {
        switch ctx {
        case .view:
            DispatchQueue.main.async { [weak self] in
                guard let welf = self else { return }
                do {
                    try welf.execute(ctx: ctx, context: welf.container.viewContext, block: block)
                    await?(nil)
                } catch {
                    assertionFailure(error.localizedDescription)
                    await?(error)
                }
            }
        case .background:
            container.performBackgroundTask { [weak self] (context) in
                guard let welf = self else { return }
                do {
                    try welf.execute(ctx: ctx, context: context, block: block)
                    await?(nil)
                } catch {
                    assertionFailure(error.localizedDescription)
                    await?(error)
                }
            }
        case .unsafeBackground(ctx: let context):
            DispatchQueue.dbBackgroundQueue.async { [weak self] in
                guard let welf = self else { return }
                do {
                    try welf.execute(ctx: ctx, context: context, block: block)
                    await?(nil)
                } catch {
                    assertionFailure(error.localizedDescription)
                    await?(error)
                }
            }
        }
    }
    
    public func subscribe(context: NSManagedObjectContext) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willSaveCtx),
            name: NSNotification.Name.NSManagedObjectContextWillSave,
            object: context
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didChangeCtxObjects),
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: context
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didSaveCtx),
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: context
        )
    }
    
    open func willExecuteTransaction(in context: NSManagedObjectContext, ofType ctx: Context) {
        
        switch ctx {
        case .view:
            break
        default:
            subscribe(context: context)
        }
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        
        delegate?.willExecuteTransaction(in: context, ofType: ctx)
    }
    
    open func didExecuteTransaction(in context: NSManagedObjectContext, ofType ctx: Context) {
        delegate?.didExecuteTransaction(in: context, ofType: ctx)
    }
    
    @objc open func willSaveCtx(_ notification: Notification) {
        delegate?.willSaveCtx(notification: notification)
    }
    
    @objc open func didChangeCtxObjects(_ notification: Notification) {
        delegate?.didChangeCtxObjects(notification: notification)
    }
    
    @objc open func didSaveCtx(_ notification: Notification) {
        
        DispatchQueue.main.async {
            self.container.viewContext.mergeChanges(fromContextDidSave: notification)
        }
        
        delegate?.didSaveCtx(notification: notification)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension DispatchQueue {
    static let dbBackgroundQueue = DispatchQueue(label: "dbBackgroundQueue", qos: .background)
}
