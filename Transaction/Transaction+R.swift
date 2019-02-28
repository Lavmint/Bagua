//
//  Transaction+R.swift
//  Bagua
//
//  Created by Alexey Averkin on 28/02/2019.
//

import CoreData

extension Transaction {
    
    public func managedIds<T: Managed>(_ type: T.Type) -> Request<T, NSManagedObjectID> {
        return Request<T, NSManagedObjectID>(container: container, ctx: managedObjectContext)
    }
    
    public func objects<T: Managed>(_ type: T.Type) -> Request<T, T> {
        return Request<T, T>(container: container, ctx: managedObjectContext)
    }
    
    public func dictionaries<T: Managed>(_ type: T.Type) -> Request<T, NSDictionary> {
        return Request<T, NSDictionary>(container: container, ctx: managedObjectContext)
    }
    
    public func count<T: Managed>(_ type: T.Type) -> Request<T, NSNumber> {
        return Request<T, NSNumber>(container: container, ctx: managedObjectContext)
    }
    
    public func managedIds<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSManagedObjectID> {
        return Request<T.Output, NSManagedObjectID>(container: container, ctx: managedObjectContext)
    }
    
    public func objects<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, T.Output> {
        return Request<T.Output, T.Output>(container: container, ctx: managedObjectContext)
    }
    
    public func dictionaries<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSDictionary> {
        return Request<T.Output, NSDictionary>(container: container, ctx: managedObjectContext)
    }
    
    public func count<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSNumber> {
        return Request<T.Output, NSNumber>(container: container, ctx: managedObjectContext)
    }
}
