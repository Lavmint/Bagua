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

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try transactions()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func transactions() throws {
        
        //generate stubs
        let users: [User] = [
            User(phone: "+79349569345", name: "Peter", surname: "Griffin", sex: .male),
            User(phone: "+63234535356", name: "Finn", surname: "the Human", sex: .male),
            User(phone: "+13432342342", name: "Bubblegum", surname: "the Princess", sex: .female),
            User(phone: "+33432535325", name: "Marceline", surname: "the Vampire Queen", sex: .female)
        ]
        
        db.bagua.delegate = self
        
        //clean db
        try db.bagua.sync(ctx: .view) { (t) in
            try t.write({ (w) in
                try w.drop()
            })
        }
        
        //print sync in viewContext
        try db.bagua.sync(ctx: .view) { (t) in
            t.dictionaries(UserMO.self).configure({ (r) in
                r.sortDescriptors = [NSSortDescriptor(key: #keyPath(UserMO.name), ascending: false)]
            }).print()
        }
        
        //create sync transaction in viewContext
        try db.bagua.sync(ctx: .view) { (t) in
            //write transaction in viewContext
            try t.write({ (w) in
                try w.update(objects: users)
            })
        }
        
        //print sync in viewContext
        try db.bagua.sync(ctx: .view) { (t) in
            t.dictionaries(UserMO.self).configure({ (r) in
                r.sortDescriptors = [NSSortDescriptor(key: #keyPath(UserMO.name), ascending: false)]
            }).print()
        }
        
        //modify async in viewContext
        db.bagua.async(await: onModify, ctx: .background, { (t) in
            let user = try t.objects(UserMO.self).find(id: "+79349569345")!.object!
            user.name = "Pitter is not a Pitter"
            try t.write({ (w) in
                try w.update(object: user)
            })
        })
    }
    
    private func onModify(error: Error?) {
        
        if let err = error {
            assertionFailure(err.localizedDescription)
        }
        
        do {
            try db.bagua.sync(ctx: .background, { (t) in
                t.dictionaries(UserMO.self).configure({ (r) in
                    r.sortDescriptors = [NSSortDescriptor(key: #keyPath(UserMO.name), ascending: true)]
                }).print()
            })
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
}

extension ViewController: TransactionDelegate {

    func willExecuteTransaction(in context: NSManagedObjectContext, ofType ctx: Context) {
        print(#function)
    }
    
    func didExecuteTransaction(in context: NSManagedObjectContext, ofType ctx: Context) {
        print(#function)
    }

    func willSaveCtx(notification: Notification) {
        print(#function)
    }
    
    func didChangeCtxObjects(notification: Notification) {
        print(#function)
    }
    
    func didSaveCtx(notification: Notification) {
        print(#function)
    }
}
