//
//  Helpers.swift
//  Bagua_Example
//
//  Created by Alexey Averkin on 27/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Bagua
import CoreData

fileprivate extension NSPersistentContainer {
    
    static let bagua: NSPersistentContainer = {
        
        let container = NSPersistentContainer(
            name: "Bagua",
            managedObjectModel: NSManagedObjectModel(
                contentsOf: Bundle.main.url(
                    forResource: "Bagua",
                    withExtension: "momd"
                    )!
                )!
        )
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
        
        return container
        
    }()
    
}

public enum db {
    
    public static func bagua(context: Context) -> Transaction {
        let t = Transaction(context: context, container: NSPersistentContainer.bagua)
        t.managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        return t
    }
}
