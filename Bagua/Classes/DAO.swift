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

public class DAO {
    
    internal let container: NSPersistentContainer
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    private func execute(ctx: Context, context: NSManagedObjectContext, block: ((_ t: Transaction) throws -> Void)) throws  {
        if context != container.viewContext {
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
        try block(Transaction(container: container, ctx: context))
    }
    
    public func sync(ctx: Context, _ block: ((_ w: Transaction) throws -> Void)) throws {
        switch ctx {
        case .view:
            let context = container.viewContext
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            try execute(ctx: ctx, context: container.viewContext, block: block)
        case .background:
            let context = container.newBackgroundContext()
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            try execute(ctx: ctx, context: context, block: block)
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
    
    @objc private func willSaveCtx(_ notification: Notification) {
        
    }
    
    @objc private func didChangeCtxObjects(_ notification: Notification) {
        
    }
    
    @objc private func didSaveCtx(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let welf = self else { return }
            welf.container.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}

extension DispatchQueue {
    static let dbBackgroundQueue = DispatchQueue(label: "dbBackgroundQueue", qos: .background)
}
