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

public enum RequestError: Error {
    case notViewContext
}

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
    
    private func primaryKeyEquals(value: CVarArg) -> NSPredicate {
        let keyFormat: String
        switch value {
        case is NSNumber:
            keyFormat = "%d"
        case is NSString:
            keyFormat = "%@"
        default:
            assertionFailure()
            keyFormat = ""
        }
        return NSPredicate(format: "\(Object.primaryKey()) == \(keyFormat)", value)
    }
}

public extension Request where Result: FetchableType {
    
    public func find(id: Object.PrimaryKey) throws -> Result? {
        request.predicate = primaryKeyEquals(value: id)
        let objects = try ctx.fetch(request)
        return objects.first
    }
    
    public func find(ids: [Object.PrimaryKey]) throws -> [Result] {
        request.predicate = NSPredicate(format: "\(Object.primaryKey()) IN %@", ids)
        return try ctx.fetch(request)
    }
    
    public func fetch() throws -> [Result] {
        return try ctx.fetch(request)
    }
    
    public func frc(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<Result> {
        guard isViewContext else {
            fatalError(RequestError.notViewContext.localizedDescription)
        }
        let f = NSFetchedResultsController(fetchRequest: request, managedObjectContext: ctx, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        return f
    }
}

public extension Request where Result: NSNumber {
    
    public func count() throws -> Int {
        return try ctx.count(for: request)
    }
    
    public func isExists(id: Object.PrimaryKey) throws -> Bool {
        request.predicate = primaryKeyEquals(value: id)
        return try count() > 0
    }
}

public extension Request where Result: NSDictionary {
    
    public func decode<T: Decodable>(with decoder: JSONDecoder, to decodable: T.Type) throws -> [T] {
        let dicts = try ctx.fetch(request)
        let data = try JSONSerialization.data(withJSONObject: dicts)
        return try decoder.decode([T].self, from: data)
    }
    
    public func print() {
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
    
    public func tableViewRecycler(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> TableViewRecycler<Object> {
        guard isViewContext else {
            fatalError(RequestError.notViewContext.localizedDescription)
        }
        return TableViewRecycler<Object>(frc: frc(sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName))
    }
    
    public func collectionViewRecycler(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> CollectionViewRecycler<Object> {
        guard isViewContext else {
            fatalError(RequestError.notViewContext.localizedDescription)
        }
        return CollectionViewRecycler<Object>(frc: frc(sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName))
    }
}
