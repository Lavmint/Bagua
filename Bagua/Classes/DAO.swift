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
    
    func allValues(in array: [Int], match predicate: (Int) -> Bool) -> Bool {
        return withoutActuallyEscaping(predicate) { escapablePredicate in
            array.lazy.filter { !escapablePredicate($0) }.isEmpty
        }
    }
    
    private func perform(_ f: () -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        withoutActuallyEscaping(f) { escapableF in
            OperationQueue.Bagua.background.addOperation {
                defer {
                    semaphore.signal()
                }
                escapableF()
            }
        }
        _ = semaphore.wait(timeout: .now() + 160)
    }
    
    public func sync(ctx: Context, _ block: ((_ w: Transaction) throws -> Void)) throws {
        switch ctx {
        case .view:
            try execute(ctx: ctx, context: container.viewContext, block: block)
        case .background:
            perform {
                do {
                    try execute(ctx: ctx, context: container.newBackgroundContext(), block: block)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        case .unsafeBackground(ctx: let context):
            perform {
                do {
                    try execute(ctx: ctx, context: context, block: block)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
    }
    
    public func async(ctx: Context, _ block: @escaping ((_ w: Transaction) throws -> Void)) {
        switch ctx {
        case .view:
            OperationQueue.main.addOperation { [weak self] in
                guard let welf = self else { return }
                do {
                    try welf.execute(ctx: ctx, context: welf.container.viewContext, block: block)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        case .background:
            let context = container.newBackgroundContext()
            OperationQueue.Bagua.background.addOperation { [weak self] in
                guard let welf = self else { return }
                do {
                    try welf.execute(ctx: ctx, context: context, block: block)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        case .unsafeBackground(ctx: let context):
            OperationQueue.Bagua.background.addOperation { [weak self] in
                guard let welf = self else { return }
                do {
                    try welf.execute(ctx: ctx, context: context, block: block)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
    }
}

extension OperationQueue {
    
    enum Bagua {
        
        static let background: OperationQueue = {
            let op = OperationQueue()
            op.qualityOfService = .background
            op.name = "org.cocoapods.bagua.opqueue.background"
            op.maxConcurrentOperationCount = 1
            return op
        }()
        
    }
}
