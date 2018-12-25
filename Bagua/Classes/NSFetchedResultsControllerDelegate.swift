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
    
    public func defaultObjectActionHandler(_ action: NSFetchedResultsChangeType, in tableView: UITableView?, at indexPath: IndexPath?, newIndexPath: IndexPath?) {
        switch action {
        case .insert:
            tableView?.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView?.reloadRows(at: [indexPath!], with: .none)
        case .move:
            tableView?.deleteRows(at: [indexPath!], with: .fade)
            tableView?.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    public func defaultSectionActionHandler(_ action: NSFetchedResultsChangeType, in tableView: UITableView?, atSectionIndex sectionIndex: Int) {
        switch action {
        case .insert:
            tableView?.insertSections(IndexSet(arrayLiteral: sectionIndex), with: .fade)
        case .delete:
            tableView?.deleteSections(IndexSet(arrayLiteral: sectionIndex), with: .fade)
        default:
            assertionFailure()
        }
    }
}
