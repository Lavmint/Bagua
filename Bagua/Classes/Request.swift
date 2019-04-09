//
//  RequestBuilder.swift
//  LennyData
//
//  Created by Alexey Averkin on 17/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public protocol FetchableType { }
extension NSDictionary: FetchableType {}
extension NSManagedObject: FetchableType {}
extension NSManagedObjectID: FetchableType {}

public class Request<Object: Managed, Result: NSFetchRequestResult> {
    
    public private(set) var request: NSFetchRequest<Result>
    private let container: NSPersistentContainer
    private let ctx: NSManagedObjectContext
    private var isViewContext: Bool {
        return ctx === container.viewContext
    }
    
    internal init(container: NSPersistentContainer, ctx: NSManagedObjectContext) {
        self.container = container
        self.ctx = ctx
        request = NSFetchRequest<Result>()
        request.entity = Object.entity()

        if Result.self == NSDictionary.self {
            request.resultType = .dictionaryResultType
        } else if Result.self == NSNumber.self {
            request.resultType = .countResultType
        } else if Result.self == NSManagedObjectID.self {
            request.resultType = .managedObjectIDResultType
        } else {
            request.resultType = .managedObjectResultType
        }
    }
    
    @discardableResult
    public func configure(_ configurator: (NSFetchRequest<Result>) -> Void) -> Self {
        configurator(request)
        return self
    }
}

public extension Request where Result: FetchableType {
    
    func find(id: Object.PrimaryKey) throws -> Result? {
        let p = id is NSNumber ? "%d" : "%@"
        request.predicate = NSPredicate(format: "\(Object.primaryKey()) == \(p)", id)
        let objects = try ctx.fetch(request)
        if objects.count > 1 {
            assertionFailure("Record in is not unique")
        }
        return objects.first
    }
    
    func find(ids: [Object.PrimaryKey]) throws -> [Result] {
        request.predicate = NSPredicate(format: "\(Object.primaryKey()) IN %@", ids)
        return try ctx.fetch(request)
    }
    
    func fetch() throws -> [Result] {
        return try ctx.fetch(request)
    }
    
    func frc(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<Result> {
        guard isViewContext else {
            fatalError("Oops you must use viewContext")
        }
        let f = NSFetchedResultsController(fetchRequest: request, managedObjectContext: ctx, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        return f
    }
}

public extension Request where Result: NSNumber {
    
    func count() throws -> Int {
        return try ctx.count(for: request)
    }
    
    func isExists(id: Object.PrimaryKey) throws -> Bool {
        let p = id is NSNumber ? "%d" : "%@"
        request.predicate = NSPredicate(format: "\(Object.primaryKey()) == \(p)", id)
        let c = try count()
        if c > 1 {
            assertionFailure("Record in is not unique")
        }
        return c > 0
    }
}

public extension Request where Result: NSDictionary {
    
    func decode<T: Decodable>(with decoder: JSONDecoder, to decodable: T.Type) throws -> [T] {
        let dicts = try ctx.fetch(request)
        let data = try JSONSerialization.data(withJSONObject: dicts)
        return try decoder.decode([T].self, from: data)
    }
    
    func print() {
        do {
            let dictionary = try fetch()
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            guard let description = String(data: data, encoding: .utf8) else { return }
            Swift.print(description)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

public extension Request where Result: Managed, Result == Object {
    
    func recycler(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> RecyclerController<Object> {
        guard isViewContext else {
            fatalError("Oops you must use viewContext")
        }
        return RecyclerController<Object>(frc: frc(sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName))
    }
}
