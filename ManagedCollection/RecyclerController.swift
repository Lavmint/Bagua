//
//  RecyclerController.swift
//  LennyData
//
//  Created by Alexey Averkin on 18/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public protocol RecyclerController: class {
    associatedtype T: Managed
    var frc: NSFetchedResultsController<T> { get }
}

public extension RecyclerController {
    
    public var numberOfSections: Int {
        guard let s = frc.sections else {
            return 1
        }
        return s.count
    }
    
    public func object(forSection section: Int) -> T? {
        guard let s = frc.sections, let object = s[safe: section]?.objects?.first else {
            return nil
        }
        return object as? T
    }
}

public class TableViewRecycler<M: Managed>: RecyclerController {
    
    public typealias T = M
    
    public let frc: NSFetchedResultsController<T>
    
    public init(frc: NSFetchedResultsController<T>) {
        self.frc = frc
    }
    
    public func numberOfRows(inSection section: Int) -> Int {
        guard let s = frc.sections else {
            return frc.fetchedObjects?.count ?? 0
        }
        return s[safe: section]?.numberOfObjects ?? 0
    }
    
    public func object(atRow row: Int, inSection section: Int) -> T? {
        guard let s = frc.sections else {
            return frc.fetchedObjects?[safe: row]
        }
        return s[safe: section]?.objects?[safe: row] as? T
    }
}

public class CollectionViewRecycler<M: Managed>: RecyclerController {
    
    public typealias T = M
    
    public let frc: NSFetchedResultsController<T>
    
    public init(frc: NSFetchedResultsController<T>) {
        self.frc = frc
    }
    
    public func numberOfItems(inSection section: Int) -> Int {
        guard let s = frc.sections else {
            return frc.fetchedObjects?.count ?? 0
        }
        return s[safe: section]?.numberOfObjects ?? 0
    }
    
    public func object(forItem item: Int, inSection section: Int) -> T? {
        guard let s = frc.sections else {
            return frc.fetchedObjects?[safe: item]
        }
        return s[safe: section]?.objects?[safe: item] as? T
    }
}
