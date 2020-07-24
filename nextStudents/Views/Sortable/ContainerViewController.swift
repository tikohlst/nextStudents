//
//  ContainerViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {
    
    // MARK: - Variables
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var sortingContainer: UIView!
    @IBOutlet weak var contentView: UIView!
    
    var sortViewController: SortTableViewController?
    var tabViewController: UITableViewController?
    var mainController: MainController?
    
    
    var sortMenuVisible = false
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomConstraint.constant = self.sortingContainer.frame.size.height
    }
    
    // MARK: - Helper methods
    
    func toggleSortMenu(from viewController: UIViewController) {
        if sortMenuVisible {
            UIView.animate(withDuration: 0.5, animations: {
                self.bottomConstraint.constant = self.sortingContainer.frame.size.height
                //self.topConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        } else {
            self.view.bringSubviewToFront(sortingContainer)
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.bottomConstraint.constant = 0 - (self.tabViewController?.navigationController?.tabBarController?.tabBar.frame.size.height ?? 0)
                //self.topConstraint.constant = self.sortingContainer.frame.size.height
                self.view.layoutIfNeeded()
            })
        }
        sortMenuVisible = !sortMenuVisible
    }
    
    // TODO: refactor copy pasted code
    func setupSortingCellsAndDelegate() {
        if let sortController = sortViewController, let tabViewController = tabViewController {
            if tabViewController is NeighborsTableViewController {
                sortController.delegate = tabViewController as! NeighborsTableViewController
                let options = [SortOption.firstName, SortOption.lastName, SortOption.distance]
                if let indexPaths = sortController.tableView.indexPathsForRows(in: sortController.tableView.frame) {
                    for i in 0..<indexPaths.count {
                        if let cell = sortController.tableView.cellForRow(at: indexPaths[i]) {
                            cell.textLabel?.text = options[i].rawValue
                        }
                    }
                }
            } else if tabViewController is ChatsTableViewController {
                sortController.delegate = tabViewController as! ChatsTableViewController
                let cells = sortController.tableView.visibleCells
                let options = [SortOption.firstName, SortOption.lastName, SortOption.time]
                for i in 0..<cells.count {
                    cells[i].textLabel?.text = options[i].rawValue
                }
            } else if tabViewController is OffersTableViewController {
                sortController.delegate = tabViewController as! OffersTableViewController
                let cells = sortController.tableView.visibleCells
                let options = [SortOption.title, SortOption.date, SortOption.duration]
                for i in 0..<cells.count {
                    cells[i].textLabel?.text = options[i].rawValue
                }
            }
        }
    }
    
}
