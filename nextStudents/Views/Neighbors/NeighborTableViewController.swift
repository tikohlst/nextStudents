//
//  NeighborTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

class NeighborTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var chatsArray: [Chat] = []
    private let createOrShowChatSegue = "createOrShowChat"
    
    // currentNeighbor
    var user: User!
    var neighborFriendList: Dictionary<String,Int>?
    var userFriendList: Dictionary<String, Int>?
    var cameFromChat = false
    var neighborFriendStatus = false
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var skillsTextView: UITextView!
    @IBOutlet weak var getToKnowButton: UIButton!
    @IBOutlet weak var contactButton: UIButton!
    
    @IBAction func touchGetToKnow(_ sender: UIButton) {
        if neighborFriendList == nil {
            neighborFriendList = Dictionary<String, Int>()
        }
        
        if userFriendList != nil , let status = userFriendList![user.uid], status == 0 {
            let alert = UIAlertController(
                title: nil,
                message: "Anfrage annehmen?",
                preferredStyle: .alert)
            
            let acceptAction = UIAlertAction(title: "Ja", style: .default) { _ in
                // accept request
                self.userFriendList![self.user.uid] = 1
                MainController.dataService.setFriendList(uid: MainController.dataService.currentUser.uid, data: self.userFriendList!) { success in
                    if success {
                        
                        self.neighborFriendList![MainController.dataService.currentUser.uid] = 1
                        MainController.dataService.setFriendList(uid: self.user.uid, data: self.neighborFriendList!) { success in
                            
                            if success {
                                self.getToKnowButton.setTitle("Ihr kennt euch!", for: .disabled)
                                self.getToKnowButton.isEnabled = false
                                self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
                            }
                        }
                    }
                }
            }
            
            let declineAction = UIAlertAction(title: "Nein", style: .cancel) { _ in
                // deny request
                self.userFriendList![self.user.uid] = nil
                MainController.dataService.setFriendList(uid: MainController.dataService.currentUser.uid, data: self.userFriendList!) { (success) in
                    if success {
                        self.getToKnowButton.setTitle("Kennenlernen", for: .normal)
                        self.getToKnowButton.isEnabled = true
                        self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.03529411765, green: 0.5176470588, blue: 1, alpha: 1)
                    }
                }
            }
            
            alert.addAction(acceptAction)
            alert.addAction(declineAction)
            
            present(alert, animated: true, completion: nil)
        } else {
            neighborFriendList![MainController.dataService.currentUser!.uid] = 0
            var docData = [String:Any]()
            docData["list"] = neighborFriendList
            MainController.dataService.addRequest(with: docData, to: user.uid, completion: {
                self.getToKnowButton.setTitle("Anfrage gesendet", for: .disabled)
                self.getToKnowButton.isEnabled = false
                self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
            })
        }
    }
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if cameFromChat {
            contactButton.isEnabled = false
            contactButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
        }
        
        self.userNameLabel.text = "\(self.user.firstName)"
        let differenceInMeter = Utility.getGPSDifference(
            self.user.gpsCoordinates,
            MainController.dataService.currentUser.gpsCoordinates)
        self.address.text = "\(Int(differenceInMeter))m"
        self.bioTextView.text = "Die Biografie kannst du erst sehen, wenn ihr befreundet seid."
        self.skillsTextView.text = "Die Eigenschaften kannst du erst sehen, wenn ihr befreundet seid."
        
        MainController.dataService.getFriendList(uid: user.uid) { data in
            self.neighborFriendList = data
            if let status = data[MainController.dataService.currentUser!.uid] {
                switch status {
                case 0:
                    self.getToKnowButton.setTitle("Anfrage gesendet", for: .disabled)
                    self.getToKnowButton.isEnabled = false
                    self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
                case 1:
                    self.neighborFriendStatus = true
                    
                    self.getToKnowButton.setTitle("Ihr kennt euch!", for: .disabled)
                    self.getToKnowButton.isEnabled = false
                    self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
                    
                    self.userNameLabel.text = "\(self.user.firstName) \(self.user.lastName)"
                    self.address.text = "\(self.user.street) \(self.user.housenumber), \(self.user.zipcode)"
                    self.bioTextView.text = self.user.bio
                    self.skillsTextView.text = self.user.skills
                    
                default:
                    break
                }
            } else if self.userFriendList?[self.user.uid] != nil {
                self.getToKnowButton.setTitle("Anfrage beantworten", for: .normal)
            }
        }
        
        // Show the user's profile image
        self.profileImageView.image = self.user.profileImage
        // Show the profile image without whitespace
        if self.profileImageView.frame.width > self.profileImageView.frame.height {
            self.profileImageView.contentMode = .scaleAspectFit
        } else {
            self.profileImageView.contentMode = .scaleAspectFill
        }
        // Show the profile image rounded
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height/2
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == createOrShowChatSegue {
            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController
            
            // Set the user ID at the ChatViewController
            detailViewController.chatPartnerUID = user.uid
            
            if neighborFriendStatus {
                // Get first and last name of the chat partner and write it in the correct label
                detailViewController.chatPartnerName = self.user.firstName + " " + self.user.lastName
                
                // Set the title of the navigation item on the ChatViewController
                detailViewController.navigationItem.title = self.user.firstName + " " + self.user.lastName
            } else {
                // Get first name of the chat partner and write it in the correct label
                detailViewController.chatPartnerName = self.user.firstName
                
                // Set the title of the navigation item on the ChatViewController
                detailViewController.navigationItem.title = self.user.firstName
            }
            
            // Set the user image
            detailViewController.chatPartnerProfileImage = user.profileImage
            
            let backItem = UIBarButtonItem()
            backItem.title = "Zurück"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    @IBAction func showFullScreen(_ sender: UITapGestureRecognizer) {
        let iVC = FullScreenImageViewController()
        iVC.imageToShow = user.profileImage
        
        let backItem = UIBarButtonItem()
        backItem.title = "Zurück"
        navigationItem.backBarButtonItem = backItem
        
        self.navigationController?.pushViewController(iVC, animated: true)
    }
}
