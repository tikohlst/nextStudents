//
//  NeighborTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

class NeighborTableViewController: UITableViewController {

    var db = Firestore.firestore()
    let currentUserUID = Auth.auth().currentUser?.uid

    var chatsArray: [Chat] = []
    private let createOrShowChatSegue = "createOrShowChat"

    var user: User!

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var address: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        userNameLabel.text = "\(user.firstName) \(user.lastName)"
        
        // show user profile Image
        profileImage.image = user.profileImage
        // show profile image rounded
        profileImage.layer.cornerRadius = profileImage.frame.height/2

        // show user bio
        bioTextView.text = user.bio
        
        // show user address
        address.text = user.address
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
            detailViewController.user2UID = user.uid

            // Get first and last name of the chat partner and write it in the correct label
            detailViewController.user2Name = "\(user.firstName) \(user.lastName)"

            // Set the title of the navigation item on the ChatViewController
            detailViewController.navigationItem.title = "\(user.firstName) \(user.lastName)"

            // Set the user image
            detailViewController.user2Img = user.profileImage
        }
    }

}
