//
//  Transaction+R.swift
//  Bagua
//
//  Created by Alexey Averkin on 28/02/2019.
//

import CoreData

extension Transaction {
    
    public func managedIds<T: Managed>(_ type: T.Type) -> Request<T, NSManagedObjectID> {
        return Request<T, NSManagedObjectID>(managedObjectContext: managedObjectContext)
    }
    
    public func objects<T: Managed>(_ type: T.Type) -> Request<T, T> {
        return Request<T, T>(managedObjectContext: managedObjectContext)
    }
    
    public func dictionaries<T: Managed>(_ type: T.Type) -> Request<T, NSDictionary> {
        return Request<T, NSDictionary>(managedObjectContext: managedObjectContext)
    }
    
    public func count<T: Managed>(_ type: T.Type) -> Request<T, NSNumber> {
        return Request<T, NSNumber>(managedObjectContext: managedObjectContext)
    }
    
    public func managedIds<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSManagedObjectID> {
        return Request<T.Output, NSManagedObjectID>(managedObjectContext: managedObjectContext)
    }
    
    public func objects<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, T.Output> {
        return Request<T.Output, T.Output>(managedObjectContext: managedObjectContext)
    }
    
    public func dictionaries<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSDictionary> {
        return Request<T.Output, NSDictionary>(managedObjectContext: managedObjectContext)
    }
    
    public func count<T: InputCacheContract>(_ type: T.Type) -> Request<T.Output, NSNumber> {
        return Request<T.Output, NSNumber>(managedObjectContext: managedObjectContext)
    }
}
