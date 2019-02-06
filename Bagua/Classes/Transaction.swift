//
//  Transaction.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public class Transaction {
    
    fileprivate let ctx: NSManagedObjectContext
    fileprivate let container: NSPersistentContainer
    
    internal init(container: NSPersistentContainer, ctx: NSManagedObjectContext) {
        self.container = container
        self.ctx = ctx
    }
    
    public func managedIds<T: Managed>(_ type: T.Type) -> Request<T, NSManagedObjectID> {
        return Request<T, NSManagedObjectID>(container: container, ctx: ctx)
    }
    
    public func objects<T: Managed>(_ type: T.Type) -> Request<T, T> {
        return Request<T, T>(container: container, ctx: ctx)
    }
    
    public func dictionaries<T: Managed>(_ type: T.Type) -> Request<T, NSDictionary> {
        return Request<T, NSDictionary>(container: container, ctx: ctx)
    }
    
    public func count<T: Managed>(_ type: T.Type) -> Request<T, NSNumber> {
        return Request<T, NSNumber>(container: container, ctx: ctx)
    }
    
    public func managedIds<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSManagedObjectID> {
        return Request<T.Output, NSManagedObjectID>(container: container, ctx: ctx)
    }
    
    public func objects<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, T.Output> {
        return Request<T.Output, T.Output>(container: container, ctx: ctx)
    }
    
    public func dictionaries<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSDictionary> {
        return Request<T.Output, NSDictionary>(container: container, ctx: ctx)
    }
    
    public func count<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSNumber> {
        return Request<T.Output, NSNumber>(container: container, ctx: ctx)
    }
}

//MARK: - Write
public extension Transaction {
    
    public func write(_ block: ((_ w: WriteTransaction) throws -> Void)) throws {
        try block(WriteTransaction(container: container, ctx: ctx))
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                ctx.rollback()
                throw error
            }
        }
    }
}

public class WriteTransaction: Transaction {
    
    @discardableResult
    public func create<Object: Managed>(_ type: Object.Type, id: Object.PrimaryKey) throws -> Object {
        let obj = try objects(Object.self).find(id: id) ?? Object(context: ctx)
        obj.primaryId = id
        return obj
    }
    
    public func update<Input, Output>(object: Input) throws where Input: InputCacheContract, Input.Output == Output, Output.Input == Input  {
        let obj = try create(Output.self, id: object.managedId)
        try obj.update(with: object)
    }
    
    public func update<Seq, Output>(objects: Seq) throws where Seq: Collection, Seq.Element: InputCacheContract, Seq.Element.Output == Output, Output.Input == Seq.Element  {
        for o in objects {
            let obj = try create(Seq.Element.Output.self, id: o.managedId)
            try obj.update(with: o)
        }
    }
    
    public func delete<Object: Managed, Result>(request: Request<Object, Result>) throws where Result: NSManagedObjectID {
        let r = NSBatchDeleteRequest(fetchRequest: request.request as! NSFetchRequest<NSFetchRequestResult>)
        try ctx.execute(r)
    }
    
    public func delete(request: NSBatchDeleteRequest) throws {
        try ctx.execute(request)
    }
    
    public func delete<Object: Managed>(object: Object) throws {
        ctx.delete(object)
    }
    
    public func drop() throws {
        try container.managedObjectModel.entities.forEach { (entity) in
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            try delete(request: request)
        }
    }
}
