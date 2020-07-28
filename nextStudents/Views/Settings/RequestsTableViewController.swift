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
        
        // TODO: load friend requests
        
        
        getFriendList(uid: MainController.currentUser!.uid, completion: { (data) in
            self.rawRequests = data
            for uid in data.keys {
                if data[uid] == 0 {
                    MainController.database.collection("users").document(uid).getDocument { (neighbor, error) in
                        if let error = error {
                            print("Error getting neighbor information: \(error.localizedDescription)")
                        } else if let neighbor = neighbor {
                            let neighborData = neighbor.data()
                            if let firstName = neighborData?["firstName"] as! String?,
                                let lastName = neighborData?["lastName"] as! String? {
                                self.names.append("\(firstName) \(lastName)")
                                self.requestStatuses.append(data[uid]!)
                                self.ids.append(uid)
                                self.tableView.reloadData()
                                
                                MainController.storage
                                    .reference(withPath: "profilePictures/\(uid)/profilePicture.jpg")
                                    .getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                                        if let error = error {
                                            print("Error while downloading profile image: \(error.localizedDescription)")
                                            self.images.append(UIImage(named: "DefaultProfilePicture")!)
                                        } else {
                                            // Data for "profilePicture.jpg" is returned
                                            self.images.append(UIImage(data: data!)!)
                                            self.tableView.reloadData()
                                        }
                                }
                            }
                            
                        }
                    }
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
    
    // MARK: - Methods
    
    private func getFriendList(uid: String, completion: @escaping (_ data: Dictionary<String, Int>) -> Void) {
        MainController.database.collection("friends").document(uid).getDocument { document, error in
            if let error = error {
                print("Error getting friendlist: \(error.localizedDescription)")
            } else if let docData = document?.data(), let data = (docData["list"] as! Dictionary<String, Int>?) {
                completion(data)
            } else {
                // no error but document doesn't exist right now -> create data for empty document
                let newData = Dictionary<String, Int>()
                completion(newData)
            }
        }
    }
    
    private func setFriendList(uid: String, data: Dictionary<String, Int>, completion: @escaping (Bool) -> Void) {
        var docData = [String:Any]()
        docData["list"] = data
        MainController.database.collection("friends").document(uid).setData(docData) { error in
            if let error = error {
                print("Error setting data: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
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
            let currentUser = MainController.currentUser
            self.rawRequests[requestingId] = 1
            
            self.setFriendList(uid: currentUser!.uid, data: self.rawRequests) { (successful) in
                if successful {
                    self.names.remove(at: indexPath.row)
                    self.ids.remove(at: indexPath.row)
                    self.images.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .right)
                    
                    self.getFriendList(uid: requestingId) { (friendsList) in
                        var updatedList = friendsList
                        updatedList[currentUser!.uid] = 1
                        self.setFriendList(uid: requestingId, data: updatedList, completion: { (successful) in })
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
            let currentUser = MainController.currentUser
            
            self.setFriendList(uid: currentUser!.uid, data: self.rawRequests) { (successful) in
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
}
