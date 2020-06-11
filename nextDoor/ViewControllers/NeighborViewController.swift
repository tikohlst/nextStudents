//
//  NeighborViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class NeighborViewController: UIViewController {

    var db = Firestore.firestore()
    var chatsArray: [Chat] = []
    var user: User!
    private let createOrShowChatSegue = "createOrShowChat"
    let currentUserUID = Auth.auth().currentUser?.uid

    @IBOutlet weak var bioTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // show user bio
        bioTextView.text = user.bio
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == createOrShowChatSegue {
            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController

            // Set the user ID at the ChatViewController
            detailViewController.user2UID = user.uid

            var firstName = ""
            var lastName = ""

            db.collection("users")
                .whereField("uid", isEqualTo: user.uid)
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            // Get first and last name of the chat partner
                            firstName = document.data()["givenName"] as! String
                            lastName = document.data()["name"] as! String
                        }
                    }
            }

            // Get first and last name of the chat partner and write it in the correct label
            detailViewController.user2Name = "\(firstName) \(lastName)"

            detailViewController.user2ImgUrl = "https://image.flaticon.com/icons/svg/21/21104.svg"

            // Set the title of the navigation item on the ChatViewController
            detailViewController.navigationItem.title = "\(firstName) \(lastName)"
        }
    }
}
