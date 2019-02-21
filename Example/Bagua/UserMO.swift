//
//  UserMO.swift
//  Bagua_Example
//
//  Created by Alexey Averkin on 26/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Bagua
import CoreData

extension UserMO: ManagedObject {
    
    public static func primaryKey() -> String {
        return #keyPath(UserMO.phone)
    }
    
    public var primaryId: String {
        get {
            return phone!
        }
        set {
            phone = newValue
        }
    }
}

extension UserMO: OutputCacheContract {
    
    public func update(with object: User, in context: NSManagedObjectContext, container: NSPersistentContainer) throws {
        name <? object.name
        surname <? object.surname
        sex <? object.sex.rawValue
    }
}
