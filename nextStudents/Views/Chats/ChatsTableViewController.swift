//
//  ChatsTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ChatTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var chatPartnerNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var chatPartnerImageView: UIImageView!
    
    // MARK: - Methods
    
    // Inside UITableViewCell subclass
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Customize profile image
        chatPartnerImageView.frame = CGRect(x: 20, y: 10, width: 80, height: 80)
        
        // Show the profile image without whitespace
        if chatPartnerImageView.frame.width > chatPartnerImageView.frame.height {
            chatPartnerImageView.contentMode = .scaleAspectFit
        } else {
            chatPartnerImageView.contentMode = .scaleAspectFill
        }
        
        // Show profile image rounded
        chatPartnerImageView.layer.cornerRadius = chatPartnerImageView.frame.width/2
        
        // Customize labels
        chatPartnerNameLabel.frame = CGRect(x: 120, y: 10, width: self.frame.width - 20, height: 34)
        lastMessageLabel.frame = CGRect(x: 120, y: 44, width: self.frame.width - 20, height: 34)
    }
    
}

class ChatsTableViewController: SortableTableViewController {
    
    // MARK: - Variables
    
    private let showChatDetailSegue = "showChatDetail"
    var chatsArray = [Chat]() {
        didSet {
            searchedChats = chatsArray.map({$0})
        }
    }
    var searchedChats = [Chat]()
    
    override var sortingOption: SortOption? {
        didSet {
            if let sortingOption = sortingOption {
                if isSorting {
                    searchedChats = super.sort(searchedChats, by: sortingOption)
                } else {
                    chatsArray = super.sort(chatsArray, by: sortingOption)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    static var threadListeners = Dictionary<String, ListenerRegistration>()
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        // Change placeholder for search field
        navigationItem.searchController?.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Suche", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
        // Change the title of the Cancel button on the search bar
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "Abbrechen"
        
        // Get all chats from the current user
        MainController.listeners.append(MainController.database.collection("Chats")
            .addSnapshotListener() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for chat in querySnapshot!.documents {
                        // Get both users of the chat
                        let users = chat.data()["users"] as! Array<String>
                        
                        if users.contains(MainController.currentUser.uid) {
                            // Get uid from chat partner
                            let chatPartnerUID = users.first(where: { $0 != MainController.currentUser.uid})! as String
                            if let listener = ChatsTableViewController.threadListeners[chatPartnerUID] {
                                listener.remove()
                                ChatsTableViewController.threadListeners[chatPartnerUID] = nil
                            }
                            // Get newest message from the chat with the found chat id
                            ChatsTableViewController.threadListeners[chatPartnerUID] = (MainController.database.collection("Chats")
                                .document(chat.documentID)
                                .collection("thread")
                                .order(by: "created", descending: true)
                                .limit(to: 1)
                                .addSnapshotListener { querySnapshot, error in
                                    guard let documents = querySnapshot?.documents else {
                                        print("Error fetching documents: \(error!)")
                                        return
                                    }
                                    
                                    for latestMessage in documents {
                                        // Create Chat object with the uid of the currentUser and its chat partner
                                        // and the timestamp and the content from the latest message
                                        
                                        // Remove old chat object if exists
                                        if let existingChat = self.chatsArray.firstIndex(where: { $0.chatPartner.uid == chatPartnerUID }) {
                                            self.chatsArray.remove(at: existingChat)
                                        }
                                        
                                        // Get information about the chat partner
                                        MainController.database.collection("users")
                                            .document(chatPartnerUID)
                                            .getDocument { (querySnapshot, error) in
                                                if error != nil {
                                                    print("Error occured")
                                                }
                                                else if querySnapshot!.exists == false {
                                                    print("Chat partner doesn't exist!")
                                                }
                                                else {
                                                    do {
                                                        let chatPartner = try User().mapData(uid: querySnapshot!.documentID, data: querySnapshot!.data()!)
                                                        let newChat = try Chat().mapData(data: latestMessage.data(), chatPartner: chatPartner)
                                                        
                                                        // Get profile image of the chat partner
                                                        MainController.storage
                                                            .reference(withPath: "profilePictures/\(chatPartnerUID)/profilePicture.jpg")
                                                            .getData(maxSize: 4 * 1024 * 1024) { data, error in
                                                                
                                                                if let error = error {
                                                                    print("Error while downloading profile image: \(error.localizedDescription)")
                                                                    newChat!.chatPartner.profileImage = UIImage(named: "defaultProfilePicture")!
                                                                } else {
                                                                    // Data for "profilePicture.jpg" is returned
                                                                    newChat!.chatPartner.profileImage = UIImage(data: data!)!
                                                                }
                                                                
                                                                self.chatsArray.append(newChat!)
                                                                
                                                                // Sort the chats by time
                                                                self.chatsArray.sort(by: { (firstChat: Chat, secondChat: Chat) in
                                                                    firstChat.timestampOfTheLatestMessage.seconds > secondChat.timestampOfTheLatestMessage.seconds
                                                                })
                                                                
                                                                // Update the table
                                                                self.tableView.reloadData()
                                                        }
                                                    } catch UserError.mapDataError {
                                                        print("Error while mapping User!")
                                                        let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                                                        self.present(alert, animated: true, completion: nil)
                                                    } catch ChatError.mapDataError {
                                                        print("Error while mapping Chat!")
                                                        let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                                                        self.present(alert, animated: true, completion: nil)
                                                    } catch {
                                                        print("Unexpected error: \(error)")
                                                    }
                                                }
                                        }
                                    }
                            })
                        }
                    }
                }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
        if let container = self.navigationController?.tabBarController?.parent as? ContainerViewController {
            containerController = container
            containerController!.tabViewController = self
            containerController!.setupSortingCellsAndDelegate()
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            searchedChats = chatsArray.filter({$0.chatPartner.firstName.localizedCaseInsensitiveContains(searchText) || $0.chatPartner.lastName.localizedCaseInsensitiveContains(searchText)})
        } else {
            searchedChats = chatsArray.map({$0})
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSorting ? searchedChats.count : chatsArray.count
    }
    
    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        
        // Show all existing chats
        let chatsToDisplay = isSorting ? searchedChats : chatsArray
        if chatsToDisplay.count > 0 {
            let currentChat = chatsToDisplay[indexPath.row]
            
            // Write first and last name of the chat partner in the cell
            cell.chatPartnerNameLabel.text = currentChat.chatPartner.firstName + " " + currentChat.chatPartner.lastName
            
            // Write latest message in cell
            cell.lastMessageLabel.text = currentChat.latestMessage
            
            // Write profil image in cell
            cell.chatPartnerImageView.image = currentChat.chatPartner.profileImage
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let displayedChats = isSorting ? searchedChats : chatsArray
        if editingStyle == .delete {
            // Retrieve the selected chat
            let currentChat = displayedChats[indexPath.row]
            
            // get all chats of current user
            MainController.database.collection("Chats").whereField("users", arrayContains: MainController.currentUser.uid).getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting chats: \(error.localizedDescription)")
                } else if let snapshot = snapshot, !snapshot.isEmpty {
                    for document in snapshot.documents {
                        let data = document.data()["users"] as! Array<String>
                        let chatRef = document.reference
                        // get the current chat
                        if data.contains(currentChat.chatPartner.uid) {
                            // get the thread collection for the current chat
                            chatRef.collection("thread").getDocuments { (threadQuery, error) in
                                if let error = error {
                                    print("Error gettin thread: \(error.localizedDescription)")
                                } else if let threadQuery = threadQuery, !threadQuery.isEmpty {
                                    // delete thread listener
                                    if let listener = ChatsTableViewController.threadListeners[currentChat.chatPartner.uid] {
                                        listener.remove()
                                    }
                                    // delete every chat message
                                    for chatMessage in threadQuery.documents {
                                        let messageRef = chatMessage.reference
                                        messageRef.delete()
                                    }
                                    // delete the chat document (Chats/{chatId})
                                    chatRef.delete()
                                    // delete data from tableview data source
                                    if self.isSorting {
                                        let removedChat = self.searchedChats.remove(at: indexPath.row)
                                        let tmp = self.searchedChats
                                        if let index = self.chatsArray.firstIndex(where: { (chat) -> Bool in
                                            return chat.localChatID == removedChat.localChatID
                                        }) {
                                            self.chatsArray.remove(at: index)
                                        }
                                        self.searchedChats = tmp
                                    } else {
                                        self.chatsArray.remove(at: indexPath.row)
                                    }
                                    // delete row from tableview
                                    self.tableView.deleteRows(at: [indexPath], with: .left)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        let displayedChats = isSorting ? searchedChats : chatsArray
        if segue.identifier == showChatDetailSegue {
            
            if let vc = containerController, vc.sortMenuVisible {
                vc.toggleSortMenu(from: self)
            }
            // Show the selected Chat on the Detail view
            let indexPath = self.tableView.indexPathForSelectedRow!
            
            // Retrieve the selected chat
            let currentChat = displayedChats[indexPath.row]
            
            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController
            
            // Set the user ID at the ChatViewController
            detailViewController.chatPartnerUID = currentChat.chatPartner.uid
            
            // Set the label on the ChatViewController
            detailViewController.chatPartnerName = "\(currentChat.chatPartner.firstName) \(currentChat.chatPartner.lastName)"
            
            // Set the user image
            detailViewController.chatPartnerProfileImage = currentChat.chatPartner.profileImage
            
            let backItem = UIBarButtonItem()
            backItem.title = "Zurück"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    @IBAction func touchSortButton(_ sender: UIBarButtonItem) {
        if let vc = containerController {
            vc.toggleSortMenu(from: self)
        }
    }
    
}

// MARK: - Extensions

extension ChatsTableViewController: SortTableViewControllerDelegate {
    func forward(data: SortOption?) {
        sortingOption = data
    }
}
