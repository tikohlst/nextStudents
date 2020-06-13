//
//  ChatsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class ChatTableViewCell: UITableViewCell {
    @IBOutlet weak var chatPartnerNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var chatPartnerImageView: UIImageView!
}

class ChatsTableViewController: UITableViewController {
    var db = Firestore.firestore()
    var chatsArray: [Chat] = []
    private let showChatDetailSegue = "showChatDetail"
    let currentUserUID = Auth.auth().currentUser?.uid
    var counter2 = 0
    var chatPartnerUID = ""

    func getFirstNameLastName(completion: @escaping (String) -> Void) {
        // The database query is actually asynchronous, but in order
        // to display the name, it must be executed synchronously
        db.collection("users")
            .whereField("uid", isEqualTo: chatPartnerUID)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // Get first and last name of the chat partner
                        let firstName = document.data()["givenName"] as! String
                        let lastName = document.data()["name"] as! String
                        completion("\(firstName) \(lastName)")
                    }
                }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.chatsArray = []

        db.collection("Chats")
            .whereField("users", arrayContains: currentUserUID ?? 0)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // Create Chat object with the uid of the currentUser and its chat partner
                        let chat = Chat(dictionary: document.data())
                        if chat != nil {
                            self.chatsArray.append(chat!)
                        }

                        // Update the table
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatsArray.count
    }

    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell

        // Show all existing chats
        if chatsArray.count > 0 {
            let currentChat = chatsArray[indexPath.row]

            // Get both users of the chat
            let users = currentChat.dictionary["users"] as! Array<String>
            
            // Get uid from other chat partner
            let chatPartnerUID = users.first(where: { $0 != currentUserUID})! as String

            // Get first and last name of the chat partner and write it in the correct label
            self.chatPartnerUID = chatPartnerUID
            getFirstNameLastName { firstAndLastName in
                cell.chatPartnerNameLabel?.text = firstAndLastName
            }

            // Get image of the chat partner and write it in the correct image
            cell.chatPartnerImageView?.image = UIImage(named: "Test")

            // Get the chat id from the chat with currentUserUID and chatPartnerUID
            db.collection("Chats")
                .whereField("users", in: [[currentUserUID, chatPartnerUID], [chatPartnerUID, currentUserUID]])
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            // Get newest message from the chat with the found chat id
                            self.db.collection("Chats")
                                .document(document.documentID)
                                .collection("thread")
                                .order(by: "created", descending: true)
                                .limit(to: 1)
                                .getDocuments() { (querySnapshot, err) in
                                    if let err = err {
                                        print("Error getting documents: \(err)")
                                    } else {
                                        for document in querySnapshot!.documents {
                                            // Write last message in cell
                                            cell.lastMessageLabel?.text = document.data()["content"] as? String

                                            // Update the table
                                            DispatchQueue.main.async {
                                                self.tableView.reloadData()
                                            }
                                        }
                                    }
                            }
                        }
                    }
            }
        }

        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == showChatDetailSegue {
            // Show the selected Chat on the Detail view
            let indexPath = self.tableView.indexPathForSelectedRow!

            // Retrieve the selected chat
            let currentChat = chatsArray[indexPath.row]

            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController

            // Get both users of the chat
            let users = currentChat.dictionary["users"] as! Array<String>

            // Get uid from chat partner
            let chatPartnerUID = users.first(where: { $0 != currentUserUID})! as String

            // Set the user ID at the ChatViewController
            detailViewController.user2UID = chatPartnerUID

            // Get first and last name of the chat partner and write it in the correct label
            //detailViewController.user2Name = getFirstNameLastName(chatPartnerUID: chatPartnerUID)

            detailViewController.user2ImgUrl = "https://image.flaticon.com/icons/svg/21/21104.svg"

            // Set the title of the navigation item on the ChatViewController
            self.chatPartnerUID = chatPartnerUID
            getFirstNameLastName { firstAndLastName in
                detailViewController.navigationItem.title = firstAndLastName
            }
        }
    }
}
