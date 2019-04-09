//
//  User.swift
//  Bagua_Example
//
//  Created by Alexey Averkin on 26/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Bagua

final public class User {
    
    public enum Sex: String {
        case male, female
    }
    
    public let phone: String
    public var name: String
    public var surname: String
    public var sex: Sex

    public init(phone: String, name: String, surname: String, sex: Sex) {
        self.phone = phone
        self.name = name
        self.surname = surname
        self.sex = sex
    }
    
}

extension User: InputCacheContract {

    public var managedId: String {
        return phone
    }
    
    convenience public init?(mo: UserMO) {
        guard let name = mo.name else { return nil }
        guard let surname = mo.surname else { return nil }
        guard let rawSex = mo.sex, let sex = Sex(rawValue: rawSex) else { return nil }
        self.init(phone: mo.phone!, name: name, surname: surname, sex: sex)
    }
}

extension User: Decodable { }
extension User.Sex: Decodable { }
