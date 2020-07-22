//
//  SortTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

protocol SortTableViewControllerDelegate: NSObjectProtocol {
    func forward(data: SortOption?)
}

class SortTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var selectedIndexPath: IndexPath?
    weak var delegate: SortTableViewControllerDelegate?
    var selectedSorting: String?
    
    var containerController: ContainerViewController?
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        //        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemMaterial)
        //        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //        blurEffectView.frame = view.bounds
        //        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //        tableView.backgroundColor = .clear
        //        tableView.backgroundView = blurEffectView
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let container = self.parent as? ContainerViewController {
            containerController = container
            containerController?.sortViewController = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedSorting = selectedSorting {
            for cell in tableView.visibleCells {
                if let text = cell.textLabel?.text, text == selectedSorting {
                    cell.accessoryType = .checkmark
                    if let indexPath = tableView.indexPath(for: cell) {
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.none)
                        
                        setCheckmark(tableView, indexPath)
                        selectedIndexPath = indexPath
                    }
                    
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        setCheckmark(tableView, indexPath)
        setDelegate(tableView, indexPath)
        
        selectedIndexPath = indexPath
    }
    
    // MARK: - Helper methods
    
    func tableViewHeight() -> CGFloat {
        tableView.layoutIfNeeded()
        return tableView.contentSize.height
    }
    
    private func setCheckmark(_ tableView: UITableView, _ indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let selectedIndexPath = selectedIndexPath, let cell = tableView.cellForRow(at: selectedIndexPath) {
            cell.accessoryType = .none
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
    }
    
    private func setDelegate(_ tableView: UITableView, _ indexPath: IndexPath) {
        if let delegate = delegate {
            let option = SortOption(rawValue: tableView.cellForRow(at: indexPath)?.textLabel?.text ?? "")
            delegate.forward(data: option)
        }
    }
    
}
