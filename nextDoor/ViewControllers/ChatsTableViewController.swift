//
//  ChatsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var chatPartnerNameLabel: UILabel?
    @IBOutlet weak var lastMessageLabel: UILabel?
    @IBOutlet weak var chatPartnerImageView: UIImageView?

}

class ChatsTableViewController: UITableViewController {

    var db = Firestore.firestore()
    var chatsArray: [Chat] = []
    private let showChatDetailSegue = "showChatDetail"
    let currentUserUID = Auth.auth().currentUser?.uid
    var chatPartnerUID = ""
    var storage: Storage!

    
    override func viewDidLoad() {
        storage = Storage.storage()
        getAndSortChatsAndUpdateTable()
    }
    func getFirstAndLastName(completion: @escaping (String) -> Void) {
        // The database query is actually asynchronous, but in order
        // to display the name, it must be executed synchronously
        db.collection("users")
            .document(chatPartnerUID)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }

                // Get first and last name of the chat partner
                let firstName = data["givenName"] as! String
                let lastName = data["name"] as! String
                completion("\(firstName) \(lastName)")
            }
    }

    func getAndSortChatsAndUpdateTable() {
        self.chatsArray = []

        db.collection("Chats")
            .whereField("users", arrayContains: currentUserUID ?? 0)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for chat in querySnapshot!.documents {
                        // Get newest message from the chat with the found chat id
                        self.db.collection("Chats")
                            .document(chat.documentID)
                            .collection("thread")
                            .order(by: "created", descending: true)
                            .limit(to: 1)
                            .addSnapshotListener { querySnapshot, error in
                                guard let documents = querySnapshot?.documents else {
                                    print("Error fetching documents: \(error!)")
                                    return
                                }

                                for newestMessage in documents {
                                    // Create Chat object with the uid of the currentUser and its chat partner and the timestamp from the latest message
                                    let newChat = Chat(dictionary: chat.data(), timestamp: (newestMessage.data()["created"] as? Timestamp)!)

                                    // Remove existing chat object if exists
                                    if let existingChat = self.chatsArray.firstIndex(where: { $0.users.sorted() == newChat?.users.sorted() })
                                    {
                                        self.chatsArray.remove(at: existingChat)
                                    }

                                    self.chatsArray.append(newChat!)

                                    // Sort the chats by time
                                    self.chatsArray.sort(by: { (firstChat: Chat, secondChat: Chat) in
                                        firstChat.timestamp.seconds > secondChat.timestamp.seconds
                                    })

                                    // Update the table
                                    self.tableView.reloadData()
                                }
                            }
                    }
                }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //getAndSortChatsAndUpdateTable()
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
            getFirstAndLastName { firstAndLastName in
                //cell.chatPartnerNameLabel?.text = firstAndLastName
                cell.textLabel?.text = firstAndLastName
            }

            // Get image of the chat partner and write it in the correct image
            
            // get profile image if it exists
            let storageRef = self.storage.reference(withPath: "profilePictures/\(self.chatPartnerUID)/profilePicture.jpg")

            storageRef.getData(maxSize: 4 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error while downloading profile image: \(error.localizedDescription)")
                    cell.chatPartnerImageView?.image = UIImage(named: "Test")
                } else {
                    // Data for "profilePicture.jpg" is returned
                    let image = UIImage(data: data!)
                    //cell.chatPartnercurrentUser.profileImage = image
                    //cell.chatPartnerImageView?.image = image
                    cell.imageView?.image  = image
                }
            }
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
                                .addSnapshotListener { querySnapshot, error in
                                    guard let documents = querySnapshot?.documents else {
                                        print("Error fetching documents: \(error!)")
                                        return
                                    }

                                    for document in documents {
                                        // Write last message in cell
                                        //cell.lastMessageLabel?.text = document.data()["content"] as? String
                                        cell.detailTextLabel?.text = document.data()["content"] as? String
                                    }
                            }
                        }
                    }
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Retrieve the selected chat
            let currentChat = chatsArray[indexPath.row]

            // Get both users of the chat
            let users = currentChat.dictionary["users"] as! Array<String>

            // Get uid from chat partner
            let chatPartnerUID = users.first(where: { $0 != currentUserUID})! as String

            chatsArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)

            // Get the chat id from the chat with currentUserUID and chatPartnerUID
            db.collection("Chats")
                .whereField("users", in: [[currentUserUID, chatPartnerUID], [chatPartnerUID, currentUserUID]])
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            print("\ndocument.documentID: \(document.documentID)\n")
                            // Delete chat from the firebase database
                            self.db.collection("Chats")
                                .document(document.documentID)
                                .delete() { error in
                                if let error = error {
                                    // An error happened.
                                    print(error)
                                } else {
                                    print("Success")
                                }
                            }
                        }
                    }
            }
        }
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

            detailViewController.user2ImgUrl = "https://image.flaticon.com/icons/svg/21/21104.svg"

            self.chatPartnerUID = chatPartnerUID

            // Get first and last name of the chat partner
            getFirstAndLastName { firstAndLastName in
                // Set the title of the navigation item on the ChatViewController
                detailViewController.navigationItem.title = firstAndLastName
                // Set the user name of the user label on the ChatViewController
                detailViewController.user2Name = firstAndLastName
            }
        }
    }

}
