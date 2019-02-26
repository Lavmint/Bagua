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
    public var observer: DAOListener?
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    private func execute(ctx: Context, context: NSManagedObjectContext, block: ((_ t: Transaction) throws -> Void)) throws  {
        switch ctx {
        case .view:
            try block(Transaction(container: container, ctx: context))
        default:
            let info = TransactionInfo(context: ctx, managedObjectContext: context)
            let willExecuteTransactionNotification = Notification(
                name: .willExecuteTransaction,
                object: nil,
                userInfo: [DAOListener.NotificationKeys.transactionInfo.rawValue: info]
            )
            let didExecuteTransactionNotification = Notification(
                name: .didExecuteTransaction,
                object: nil,
                userInfo: [DAOListener.NotificationKeys.transactionInfo.rawValue: info]
            )
            NotificationCenter.default.post(willExecuteTransactionNotification)
            try block(Transaction(container: container, ctx: context))
            NotificationCenter.default.post(didExecuteTransactionNotification)
        }
    }
    
    public func sync(ctx: Context, _ block: ((_ t: Transaction) throws -> Void)) throws {
        switch ctx {
        case .view:
            try execute(ctx: ctx, context: container.viewContext, block: block)
        case .background:
            try execute(ctx: ctx, context: container.newBackgroundContext(), block: block)
        case .unsafeBackground(ctx: let context):
            try execute(ctx: ctx, context: context, block: block)
        }
    }
    
    public func async(await: (() throws -> Void)? = nil, ctx: Context, _ block: @escaping ((_ t: Transaction) throws -> Void)) {
        switch ctx {
        case .view:
            container.viewContext.performAndWait {
                do {
                    try self.execute(ctx: ctx, context: self.container.viewContext, block: block)
                    OperationQueue.awaitOperationQueue.addOperation {
                        do {
                            try await?()
                        } catch {
                            assertionFailure(error.localizedDescription)
                        }
                    }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        case .background:
            let context = container.newBackgroundContext()
            context.performAndWait {
                do {
                    try self.execute(ctx: ctx, context: context, block: block)
                    OperationQueue.awaitOperationQueue.addOperation {
                        do {
                            try await?()
                        } catch {
                            assertionFailure(error.localizedDescription)
                        }
                    }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        case .unsafeBackground(ctx: let context):
            context.performAndWait {
                do {
                    try self.execute(ctx: ctx, context: context, block: block)
                    OperationQueue.awaitOperationQueue.addOperation {
 
                    }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
    }
}

private extension OperationQueue {
    
    static let awaitOperationQueue: OperationQueue = {
       let op = OperationQueue()
        op.name = "org.cocoapods.bagua.queue.operation.await"
        op.qualityOfService = .background
        return op
    }()
}
