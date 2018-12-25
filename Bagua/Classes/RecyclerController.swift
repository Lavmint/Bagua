//
//  RecyclerController.swift
//  LennyData
//
//  Created by Alexey Averkin on 18/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public class RecyclerController<T: Managed> {
    
    public let frc: NSFetchedResultsController<T>
    
    public init(frc: NSFetchedResultsController<T>) {
        self.frc = frc
    }
    
    public var numberOfSections: Int {
        guard let s = frc.sections else {
            return 1
        }
        return s.count
    }
    
    public func numberOfItems(in section: Int) -> Int {
        return numberOfRows(in: section)
    }
    
    public func numberOfRows(in section: Int) -> Int {
        guard let s = frc.sections else {
            return frc.fetchedObjects?.count ?? 0
        }
        return s[safe: section]?.numberOfObjects ?? 0
    }
    
    public func object(forRow row: Int, in section: Int) -> T? {
        guard let s = frc.sections else {
            return frc.fetchedObjects?[row]
        }
        return s[safe: section]?.objects?[row] as? T
    }
    
    public func object(forItem item: Int, in section: Int) -> T? {
        guard let s = frc.sections else {
            return frc.fetchedObjects?[item]
        }
        return s[safe: section]?.objects?[item] as? T
    }
    
    public func object(for section: Int) -> T? {
        guard let s = frc.sections, let object = s[safe: section]?.objects?.first else {
            return nil
        }
        return object as? T
    }
}
