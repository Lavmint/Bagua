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

    lazy var observer: TransactionObserver = {
        return TransactionObserver()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        observer.onWillExecuteTransaction = { _ in
            print("onWillExecuteTransaction")
        }
        
        observer.onDidExecuteTransaction = { _ in
            print("onDidExecuteTransaction")
        }
        
        observer.onWillSaveContext = { _ in
            print("onWillSaveContext")
        }
        
        observer.onDidSaveContext = { _ in
            print("onDidSaveContext")
        }

        observer.onDidChangeContextObjects = { _, changes in

            if let object = changes.filter
                .select(type: UserMO.self, ids: ["+79349569345"])
                .select(changes: [.update])
                .select(value: "Pitter is not a Pitter", forKey: #keyPath(UserMO.name))
                .resolve()?.first {
                
                self.debug()
                print(object.changedValues())
            }
            
            if let object = changes.filter
                .select(type: UserMO.self, ids: ["+63234535356"])
                .select(changes: [.update])
                .select(values: [
                    #keyPath(UserMO.surname)
                ])
                .resolve()?.first {
                
                self.debug()
                print(object.changedValues())
            }
            
            if let _ = changes.filter
                .select(type: UserMO.self)
                .select(changes: [.insert, .update, .delete])
                .resolve() {
                
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
        db.bagua.performBackgroundTask { (context) in
            context.bga.dictionaries(UserMO.self).configure({ (r) in
                r.sortDescriptors = [NSSortDescriptor(key: #keyPath(UserMO.name), ascending: true)]
            }).print()
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
        
        db.bagua.newBackgroundContext().write { (t) in
            try t.drop()
            try t.update(objects: users)
        }

        db.bagua.performBackgroundTask { (context) in
            context.write({ (t) in
                let user = try t.objects(User.self).find(id: "+79349569345")!.object!
                user.name = "Pitter is not a Pitter"
                try t.update(object: user)
            })
        }
        
        db.bagua.performBackgroundTask { (context) in
            context.write({ (t) in
                let user = try t.objects(UserMO.self).find(id: "+63234535356")!.object!
                user.surname = "Finn is not Finn"
                try t.update(object: user)
            })
        }
        
        db.bagua.newBackgroundContext().write { (t) in
            for _ in 0..<1000 {
                for (j, u) in users.enumerated() {
                    u.name = j % 2 == 0 ? "odd" : "even"
                }
                try t.update(objects: users)
            }
        }

//        let recycler = db.bagua(context: .view).objects(UserMO.self).tableViewRecycler()
//        _ = recycler.object(atRow: 0, inSection: 0)

    }

}
