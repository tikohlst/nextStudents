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
    var friendList: Dictionary<String,Int>?
    var cameFromChat = false
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var skillsTextView: UITextView!
    @IBOutlet weak var getToKnowButton: UIButton!
    @IBOutlet weak var contactButton: UIButton!
    
    @IBAction func touchGetToKnow(_ sender: UIButton) {
        if friendList == nil {
            friendList = Dictionary<String, Int>()
        }
        friendList![MainController.currentUser!.uid] = 0
        var docData = [String:Any]()
        docData["list"] = friendList
        addRequest(with: docData, to: user.uid, completion: {
            self.getToKnowButton.setTitle("Anfrage gesendet", for: .disabled)
            self.getToKnowButton.isEnabled = false
            self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
        })
    }
    
    private func addRequest(with data: [String:Any], to id: String, completion: @escaping () -> Void) {
        MainController.database.collection("friends").document(id).setData(data) { error in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
            } else {
                completion()
            }
        }
    }
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if cameFromChat {
            contactButton.isEnabled = false
            contactButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
        }
        
        MainController.database.collection("friends").document(user.uid).getDocument { document, error in
            if let error = error {
                print("Error getting friendlist: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                let docData = document.data()
                if let data = (docData?["list"] as! Dictionary<String, Int>?) {
                    self.friendList = data
                    if let status = data[MainController.currentUser!.uid] {
                        
                        switch status {
                        case 0:
                            self.getToKnowButton.setTitle("Anfrage gesendet", for: .disabled)
                            self.getToKnowButton.isEnabled = false
                            self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
                            
                        case 1:
                            self.getToKnowButton.setTitle("Ihr kennt euch!", for: .disabled)
                            self.getToKnowButton.isEnabled = false
                            self.getToKnowButton.backgroundColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.6156862745, alpha: 1)
                            
                            self.userNameLabel.text = "\(self.user.firstName) \(self.user.lastName)"
                            
                            // show user bio
                            self.bioTextView.text = self.user.bio
                            
                            // show user skills
                            self.skillsTextView.text = self.user.skills
                            
                        default:
                            break
                        }
                    }
                }
            }
        }
        
        self.userNameLabel.text = "\(self.user.firstName)"
        // show user profile Image
        self.profileImageView.image = self.user.profileImage
        // Show the profile image without whitespace
        if self.profileImageView.frame.width > self.profileImageView.frame.height {
            self.profileImageView.contentMode = .scaleAspectFit
        } else {
            self.profileImageView.contentMode = .scaleAspectFill
        }
        
        // Show profile image rounded
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height/2
        
        // show user address
        self.address.text = "\(self.user.street) \(self.user.housenumber), \(self.user.zipcode)"
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
            
            // Get first and last name of the chat partner and write it in the correct label
            detailViewController.chatPartnerName = "\(user.firstName) \(user.lastName)"
            
            // Set the title of the navigation item on the ChatViewController
            detailViewController.navigationItem.title = "\(user.firstName) \(user.lastName)"
            
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
