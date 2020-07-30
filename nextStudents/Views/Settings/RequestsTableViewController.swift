//
//  RequestsTableViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 22.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit
import Firebase

class RequestTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    func animateSwipeHint() {
        slideInFromRight()
    }
    
    private func slideInFromRight() {
        UIView.animate(withDuration: 0.5, delay: 0.3, options: [.curveEaseOut], animations: {
            if self.backgroundView != nil {
                self.backgroundView!.transform = CGAffineTransform(translationX: -30, y: 0)
                self.backgroundView!.layer.cornerRadius = 10
            }
        }) { (success) in
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear], animations: {
                if self.backgroundView != nil {
                    self.backgroundView!.transform = .identity
                }
            }, completion: { (success) in
                // Slide from left if you have leading swipe actions
                self.slideInFromLeft()
            })
        }
    }
    
    private func slideInFromLeft() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
            if self.backgroundView != nil {
                self.backgroundView!.transform = CGAffineTransform(translationX: 30, y: 0)
            }
        }) { (success) in
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear], animations: {
                if self.backgroundView != nil {
                    self.backgroundView!.transform = .identity
                }
            })
        }
    }
}

class RequestsTableViewController: UITableViewController {
    
    var rawRequests = Dictionary<String, Int>()
    var names = [String]()
    var ids = [String]()
    var requestStatuses = [Int]()
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        MainController.dataService.getFriendList(uid: MainController.dataService.currentUser!.uid, completion: { (data) in
            self.rawRequests = data
            for uid in data.keys {
                if data[uid] == 0 {
                    
                    MainController.dataService.getNeighbor(with: uid, completion: { neighborData, _ in
                        if let firstName = neighborData["firstName"] as! String?,
                            let lastName = neighborData["lastName"] as! String? {
                            self.names.append("\(firstName) \(lastName)")
                            self.requestStatuses.append(data[uid]!)
                            self.ids.append(uid)
                            self.tableView.reloadData()
                            
                            MainController.dataService.getProfilePicture(for: uid, completion: { image in
                                self.images.append(image)
                                self.tableView.reloadData()
                            })
                        }
                    })
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.tableView.visibleCells.count > 0 {
            let cell = self.tableView.visibleCells[0] as! RequestTableViewCell
            cell.animateSwipeHint()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return names.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath) as! RequestTableViewCell
        
        
        // Configure the cell...
        cell.nameLabel.text = names[indexPath.row]
        if indexPath.row < images.count {
            cell.profileImageView.image = images[indexPath.row]
        } else {
            cell.profileImageView.image = UIImage(named: "DefaultProfilePicture")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let acceptAction = UIContextualAction(style: .destructive, title: "Akzeptieren") { (ac: UIContextualAction, view: UIView, success: @escaping (Bool) -> Void) in
            let requestingId = self.ids[indexPath.row]
            let currentUser = MainController.dataService.currentUser
            self.rawRequests[requestingId] = 1
            
            MainController.dataService.setFriendList(uid: currentUser!.uid, data: self.rawRequests) { (successful) in
                if successful {
                    self.names.remove(at: indexPath.row)
                    self.ids.remove(at: indexPath.row)
                    self.images.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .right)
                    
                    MainController.dataService.getFriendList(uid: requestingId) { (friendsList) in
                        var updatedList = friendsList
                        updatedList[currentUser!.uid] = 1
                        MainController.dataService.setFriendList(uid: requestingId, data: updatedList, completion: { (successful) in })
                    }
                    
                    success(true)
                } else {
                    success(false)
                }
            }
        }
        acceptAction.image = UIImage(systemName: "checkmark")
        acceptAction.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [acceptAction])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let denyAction = UIContextualAction(style: .destructive, title: "Ablehnen") { (ac: UIContextualAction, view: UIView, success: @escaping (Bool) -> Void) in
            // TODO: Deny request
            if let deletionIndex = self.rawRequests.index(forKey: self.ids[indexPath.row]) {
                self.rawRequests.remove(at: deletionIndex)
            }
            let currentUser = MainController.dataService.currentUser
            
            MainController.dataService.setFriendList(uid: currentUser!.uid, data: self.rawRequests) { (successful) in
                if successful {
                    self.names.remove(at: indexPath.row)
                    self.ids.remove(at: indexPath.row)
                    self.images.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                    success(true)
                } else {
                    success(false)
                }
            }
        }
        denyAction.image = UIImage(systemName: "xmark")
        denyAction.backgroundColor = #colorLiteral(red: 1, green: 0.2705882353, blue: 0.2274509804, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [denyAction])
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
