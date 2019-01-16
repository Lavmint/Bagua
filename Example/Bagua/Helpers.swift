//
//  Helpers.swift
//  Bagua_Example
//
//  Created by Alexey Averkin on 27/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Bagua
import CoreData

public enum db {
    
    public static let bagua: DAO = {
        
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
        
        let listener = DAOListener()
        listener.onWillExecuteTransaction = { info in
            info.managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        }
        
        let dao = DAO(container: container)
        dao.observer = listener
        
        return dao
        
    }()
    
}
