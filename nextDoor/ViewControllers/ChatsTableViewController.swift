//
//  ChatsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseStorage

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var chatPartnerNameLabel: UILabel?
    @IBOutlet weak var lastMessageLabel: UILabel?
    @IBOutlet weak var chatPartnerImageView: UIImageView?

}

class ChatsTableViewController: UITableViewController {

    var db = Firestore.firestore()
    var storage = Storage.storage()
    let currentUserUID = Auth.auth().currentUser?.uid

    private let showChatDetailSegue = "showChatDetail"
    var chatsArray: [Chat] = [] {
        didSet {
            searchedChats = chatsArray.map({$0})
        }
    }
    var searchedChats: [Chat] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        // Change placeholder for search field
        navigationItem.searchController?.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Suche", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
        // Change the title of the Cancel button on the search bar
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "Abbrechen"

        // Get all chats from the current user
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
                                    // Create Chat object with the uid of the currentUser and its chat partner
                                    // and the timestamp and the content from the latest message
                                    var newChat = Chat(dictionary: chat.data())

                                    // Remove old chat object if exists
                                    if let existingChat = self.chatsArray.firstIndex(where: { $0.users.sorted() == newChat?.users.sorted() })
                                    {
                                        self.chatsArray.remove(at: existingChat)
                                    }

                                    newChat!.timestamp = (newestMessage.data()["created"] as? Timestamp)!
                                    newChat!.latestMessage = (newestMessage.data()["content"] as? String)!
                                    newChat!.chatUID = chat.documentID

                                    // Get both users of the chat
                                    let users = newChat!.dictionary["users"] as! Array<String>

                                    // Get uid from chat partner
                                    let chatPartnerUID = users.first(where: { $0 != self.currentUserUID})! as String
                                    newChat!.chatPartnerUID = chatPartnerUID

                                    // Get first and last name of the chat partner
                                    self.db.collection("users")
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

                                        newChat!.chatPartnerFirstName = data["givenName"] as! String
                                        newChat!.chatPartnerLastName = data["name"] as! String
                                    }

                                    // Get profile image of the chat partner
                                    let storageRef = self.storage.reference(withPath: "profilePictures/\(chatPartnerUID)/profilePicture.jpg")
                                    storageRef.getData(maxSize: 4 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            print("Error while downloading profile image: \(error.localizedDescription)")
                                            newChat?.chatPartnerProfileImage = UIImage(named: "defaultProfilePicture")
                                        } else {
                                            // Data for "profilePicture.jpg" is returned
                                            newChat?.chatPartnerProfileImage = UIImage(data: data!)
                                        }

                                        self.chatsArray.append(newChat!)

                                        // Sort the chats by time
                                        self.chatsArray.sort(by: { (firstChat: Chat, secondChat: Chat) in
                                            firstChat.timestamp!.seconds > secondChat.timestamp!.seconds
                                        })

                                        // Update the table
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                    }
                }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            searchedChats = chatsArray.filter({$0.chatPartnerFirstName.localizedCaseInsensitiveContains(searchText) || $0.chatPartnerLastName.localizedCaseInsensitiveContains(searchText)})
        } else {
            searchedChats = chatsArray.map({$0})
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedChats.count
    }

    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell

        // Show all existing chats
        if searchedChats.count > 0 {
            let currentChat = searchedChats[indexPath.row]

            // Write first and last name of the chat partner in the cell
            cell.textLabel?.text = currentChat.chatPartnerFirstName + " " + currentChat.chatPartnerLastName

            // Write latest message in cell
            cell.detailTextLabel?.text = currentChat.latestMessage

            // Write profil image in cell
            cell.imageView?.image = currentChat.chatPartnerProfileImage
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Retrieve the selected chat
            let currentChat = searchedChats[indexPath.row]

            // Delete chat from the firebase database
            self.db.collection("Chats")
                .document(currentChat.chatUID)
                .delete() { error in
                if let error = error {
                    // An error happened.
                    print(error)
                } else {
                    let removedChat = self.searchedChats.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self.chatsArray.remove(at: self.chatsArray.firstIndex(where: {
                        return $0.chatUID  == removedChat.chatUID
                    })!)
                    print("Chat deleted successfully")
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == showChatDetailSegue {
            // Show the selected Chat on the Detail view
            let indexPath = self.tableView.indexPathForSelectedRow!

            // Retrieve the selected chat
            let currentChat = searchedChats[indexPath.row]

            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController

            // Set the user ID at the ChatViewController
            detailViewController.user2UID = currentChat.chatPartnerUID

            // Set the label on the ChatViewController
            detailViewController.user2Name = "\(currentChat.chatPartnerFirstName) \(currentChat.chatPartnerLastName)"

            // Set the user image
            detailViewController.user2Img = currentChat.chatPartnerProfileImage
        }
    }

}
