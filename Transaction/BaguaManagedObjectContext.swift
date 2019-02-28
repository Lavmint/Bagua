//
//  BaguaManagedObjectContext.swift
//  Bagua
//
//  Created by Alexey Averkin on 01/03/2019.
//

import CoreData

public class BaguaManagedObjectContext: NSManagedObjectContext {
    public var context: Context?
    public var changes: ContextChangesInfo?
}
