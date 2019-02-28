//
//  NSFetchedResultsControllerDelegate.swift
//  LennyData
//
//  Created by Alexey Averkin on 18/11/2018.
//  Copyright © 2018 aaverkin. All rights reserved.
//

import CoreData

public extension NSFetchedResultsControllerDelegate {
    
    public func defaultWillChangeContentHandler(in tableView: UITableView?) {
        tableView?.beginUpdates()
    }
    
    public func defaultDidChangeContentHandler(in tableView: UITableView?) {
        tableView?.endUpdates()
    }
    
    public func defaultObjectActionHandler(_ action: NSFetchedResultsChangeType, in tableView: UITableView?, at indexPath: IndexPath?, newIndexPath: IndexPath?, animations: [NSFetchedResultsChangeType: UITableView.RowAnimation]? = nil) {
        
        let animationForAction = animations ?? [
            .insert: .fade,
            .delete: .fade,
            .update: .none,
            .move: .fade
        ]
        let animation = animationForAction[action]!
        
        switch action {
        case .insert:
            tableView?.insertRows(at: [newIndexPath!], with: animation)
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: animation)
        case .update:
            tableView?.reloadRows(at: [indexPath!], with: animation)
        case .move:
            tableView?.deleteRows(at: [indexPath!], with: animation)
            tableView?.insertRows(at: [newIndexPath!], with: animation)
        }
    }
    
    public func defaultSectionActionHandler(_ action: NSFetchedResultsChangeType, in tableView: UITableView?, atSectionIndex sectionIndex: Int, animations: [NSFetchedResultsChangeType: UITableView.RowAnimation]? = nil) {
        
        let animationForAction = animations ?? [
            .insert: .fade,
            .delete: .fade,
            .update: .none,
            .move: .fade
        ]
        let animation = animationForAction[action]!
        
        switch action {
        case .insert:
            tableView?.insertSections(IndexSet(arrayLiteral: sectionIndex), with: animation)
        case .delete:
            tableView?.deleteSections(IndexSet(arrayLiteral: sectionIndex), with: animation)
        default:
            assertionFailure()
        }
    }
}
