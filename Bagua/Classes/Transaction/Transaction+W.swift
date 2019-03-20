//
//  Transaction+W.swift
//  Bagua
//
//  Created by Alexey Averkin on 28/02/2019.
//

import CoreData

public class WriteTransaction: Transaction {
    
    @discardableResult
    public func create<Object: Managed>(_ type: Object.Type, id: Object.PrimaryKey) throws -> Object {
        let obj = try objects(Object.self).find(id: id) ?? Object(context: managedObjectContext)
        obj.primaryId = id
        return obj
    }
    
    public func update<Input, Output>(object: Input) throws where Input: InputCacheContract, Input.Output == Output, Output.Input == Input  {
        let obj = try create(Output.self, id: object.managedId)
        try obj.update(with: object, in: self)
    }
    
    public func update<Seq, Output>(objects: Seq) throws where Seq: Collection, Seq.Element: InputCacheContract, Seq.Element.Output == Output, Output.Input == Seq.Element  {
        for o in objects {
            let obj = try create(Seq.Element.Output.self, id: o.managedId)
            try obj.update(with: o, in: self)
        }
    }
    
    public func delete<Object: Managed, Result>(request: Request<Object, Result>) throws where Result: NSManagedObjectID {
        let r = NSBatchDeleteRequest(fetchRequest: request.request as! NSFetchRequest<NSFetchRequestResult>)
        try managedObjectContext.execute(r)
    }
    
    public func delete(request: NSBatchDeleteRequest) throws {
        try managedObjectContext.execute(request)
    }
    
    public func delete<Object: Managed>(object: Object) throws {
        managedObjectContext.delete(object)
    }
    
    public func drop() throws {
        try managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entities.forEach { (entity) in
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            try delete(request: request)
        }
    }
}
