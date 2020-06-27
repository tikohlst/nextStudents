//
//  ContainerViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 26.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var sortingContainer: UIView!
    @IBOutlet weak var contentView: UIView!
    
    var sortViewController: SortTableViewController?
    var tabViewController: UITableViewController?
    
    
    var sortMenuVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomConstraint.constant = self.sortingContainer.frame.size.height
    }
    
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
                self.bottomConstraint.constant = 0
                //self.topConstraint.constant = self.sortingContainer.frame.size.height
                self.view.layoutIfNeeded()
            })
        }
        sortMenuVisible = !sortMenuVisible
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let sortController = sortViewController, let tabViewController = tabViewController as! NeighborsTableViewController? {
            sortController.delegate = tabViewController
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
