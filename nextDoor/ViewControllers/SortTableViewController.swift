//
//  SortTableViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 25.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit

protocol SortTableViewControllerDelegate: NSObjectProtocol {
    func forward(data: String?)
}

class SortTableViewController: UITableViewController {

    var selectedIndexPath: IndexPath?
    weak var delegate: SortTableViewControllerDelegate?
    var selectedSorting: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
            delegate.forward(data: tableView.cellForRow(at: indexPath)?.textLabel?.text)
        }
    }
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
