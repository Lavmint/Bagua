//
//  ViewController.swift
//  Bagua
//
//  Created by Alexey Averkin on 12/26/2018.
//  Copyright (c) 2018 Alexey Averkin. All rights reserved.
//

import UIKit
import Bagua
import CoreData

class ViewController: UIViewController {

    lazy var daoListener: DAOListener = {
        return DAOListener()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        daoListener.onWillExecuteTransaction = { _ in
            print("onWillExecuteTransaction")
        }
        daoListener.onDidExecuteTransaction = { _ in
            print("onDidExecuteTransaction")
        }
        daoListener.onWillSaveContext = {
            print("onWillSaveContext")
        }
        daoListener.onDidChangeContextObjects = { changes in
            print("onDidChangeContextObjects")
        }
        
        daoListener.onDidSaveContext = { changes in
            
            changes.trigger(track: UserMO.self, forKeys: [#keyPath(UserMO.name)], changes: [.update], ids: ["+79349569345"]) { ids in
                self.debug()
            }
            
            changes.trigger(track: UserMO.self, forKeys: [#keyPath(UserMO.surname)], changes: [.update], ids: ["+63234535356"]) { ids in
                self.debug()
            }
            
            changes.trigger(track: UserMO.self, changes: [.insert, .update, .delete]) { ids in
                self.debug()
            }
            
        }
        
        do {
            try transactions()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func debug() {
        do {
            try db.bagua.sync(ctx: .background, { (t) in
                
                t.dictionaries(UserMO.self).configure({ (r) in
                    r.sortDescriptors = [NSSortDescriptor(key: #keyPath(UserMO.name), ascending: true)]
                }).print()
//
//                let users = try t.objects(UserMO.self).configure({ (r) in
//                    r.sortDescriptors = [NSSortDescriptor(key: #keyPath(UserMO.name), ascending: true)]
//                }).fetch().compactMap({ $0.object })
//                print(users)
                
            })
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func transactions() throws {
        
        //generate stubs
        var users = Set<User>()
        users = users.union([
            User(phone: "+79349569345", name: "Peter", surname: "Griffin", sex: .male),
            User(phone: "+63234535356", name: "Finn", surname: "the Human", sex: .male),
            User(phone: "+13432342342", name: "Bubblegum", surname: "the Princess", sex: .female),
            User(phone: "+33432535325", name: "Marceline", surname: "the Vampire Queen", sex: .female)
        ])
        
        try db.bagua.write({ (w) in
            try w.drop()
            try w.update(objects: users)
        })
        
        try db.bagua.write({ (w) in
            let user = try w.objects(User.self).find(id: "+79349569345")!.object!
            user.name = "Pitter is not a Pitter"
            try w.update(object: user)
        })
        
        try db.bagua.write({ (w) in
            let user = try w.objects(UserMO.self).find(id: "+63234535356")!.object!
            user.surname = "Finn is not Finn"
            try w.update(object: user)
        })
    }
    
}
