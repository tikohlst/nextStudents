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
    var localNeighborFriendList: Dictionary<String,Int> = [:]
    
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
        
        MainController.dataService.addListener(for: "Chats") { chat in
            // Get both users of the chat
            let users = chat.data()["users"] as! Array<String>
            
            if users.contains(MainController.dataService.currentUser.uid) {
                // Get uid from chat partner
                let chatPartnerUID = users.first(where: { $0 != MainController.dataService.currentUser.uid})! as String
                if let listener = ChatsTableViewController.threadListeners[chatPartnerUID] {
                    listener.remove()
                    ChatsTableViewController.threadListeners[chatPartnerUID] = nil
                }
                // Get newest message from the chat with the found chat id
                MainController.dataService.addListenerForChatThread(chatId: chat.documentID, chatPartnerUID: chatPartnerUID) { latestMessage in
                    // Create Chat object with the uid of the currentUser and its chat partner
                    // and the timestamp and the content from the latest message
                    
                    // Remove old chat object if exists
                    if let existingChat = self.chatsArray.firstIndex(where: { $0.chatPartner.uid == chatPartnerUID }) {
                        self.chatsArray.remove(at: existingChat)
                    }
                    
                    // Get information about the chat partner
                    MainController.dataService.getNeighbor(with: chatPartnerUID) { data, documentID in
                        do {
                            let chatPartner = try User().mapData(uid: documentID, data: data)
                            let newChat = try Chat().mapData(data: latestMessage.data(), chatPartner: chatPartner)
                            
                            // Get profile image of the chat partner
                            MainController.dataService.getProfilePicture(for: chatPartnerUID, completion: { image in
                                newChat!.chatPartner.profileImage = image
                                self.chatsArray.append(newChat!)
                                
                                // Sort the chats by time
                                self.chatsArray.sort(by: { (firstChat: Chat, secondChat: Chat) in
                                    firstChat.timestampOfTheLatestMessage.seconds > secondChat.timestampOfTheLatestMessage.seconds
                                })
                                // Update the table
                                self.tableView.reloadData()
                            })
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
        }
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
            
            MainController.dataService.getFriendList(uid: MainController.dataService.currentUser!.uid, completion: { (userFriendList) in
                if let userFriendStatus = userFriendList[currentChat.chatPartner.uid], userFriendStatus == 1 {
                    self.localNeighborFriendList[currentChat.chatPartner.uid] = 1
                    // Write first and last name of the chat partner in the cell
                    cell.chatPartnerNameLabel.text = currentChat.chatPartner.firstName + " " + currentChat.chatPartner.lastName
                } else {
                    self.localNeighborFriendList[currentChat.chatPartner.uid] = 0
                    // Write first name of the chat partner in the cell
                    cell.chatPartnerNameLabel.text = currentChat.chatPartner.firstName
                }
            })
            
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
            
            // Get all chats of current user
            MainController.dataService.getChats(for: MainController.dataService.currentUser.uid) { snapshot in
                if !snapshot.isEmpty {
                    for document in snapshot.documents {
                        let data = document.data()["users"] as! Array<String>
                        let chatRef = document.reference
                        // Get the current chat
                        if data.contains(currentChat.chatPartner.uid) {
                            // Get the thread collection for the current chat
                            MainController.dataService.getChatThreadCollection(for: chatRef) { threadQuery in
                                // Delete thread listener
                                if let listener = ChatsTableViewController.threadListeners[currentChat.chatPartner.uid] {
                                    listener.remove()
                                }
                                // Delete every chat message
                                for chatMessage in threadQuery.documents {
                                    let messageRef = chatMessage.reference
                                    messageRef.delete()
                                }
                                // Delete the chat document (Chats/{chatId})
                                chatRef.delete()
                                // Delete data from tableview data source
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
                                // Delete row from tableview
                                self.tableView.deleteRows(at: [indexPath], with: .left)
                            }
                        }
                    }
                }
            }
            MainController.dataService.database.collection("Chats").whereField("users", arrayContains: MainController.dataService.currentUser.uid).getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting chats: \(error.localizedDescription)")
                } else if let snapshot = snapshot, !snapshot.isEmpty {
                    
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
            if self.localNeighborFriendList[currentChat.chatPartner.uid] == 1 {
                // Write first and last name of the chat partner in the cell
                detailViewController.chatPartnerName = currentChat.chatPartner.firstName + " " + currentChat.chatPartner.lastName
            } else {
                // Write first name of the chat partner in the cell
                detailViewController.chatPartnerName = currentChat.chatPartner.firstName
            }
            
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
