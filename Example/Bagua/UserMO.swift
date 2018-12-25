//
//  UserMO.swift
//  Bagua_Example
//
//  Created by Alexey Averkin on 26/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Bagua

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
    
    public func update(with object: User) throws {
        name.updateIfNeeded(newValue: object.name)
        surname.updateIfNeeded(newValue: object.surname)
        sex.updateIfNeeded(newValue: object.sex.rawValue)
    }
}
