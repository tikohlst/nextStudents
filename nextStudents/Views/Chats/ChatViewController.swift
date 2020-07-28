//
//  ChatViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView
import SDWebImage

class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    // MARK: - Variables
    
    var chatPartnerUID: String?
    var chatPartnerName: String?
    var chatPartnerProfileImage: UIImage?
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    var listener: ListenerRegistration?
    
    var batch = MainController.database.batch()
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let imageView = UIImageView(image: chatPartnerProfileImage)
        
        // Show the profile image without whitespace
        if imageView.frame.width > imageView.frame.height {
            imageView.contentMode = .scaleAspectFit
        } else {
            imageView.contentMode = .scaleAspectFill
        }
        
        // Show profile image rounded
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = false
        imageView.layer.shouldRasterize = true
        imageView.layer.rasterizationScale = UIScreen.main.scale
        
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.init(displayP3Red: 211.0/255.0, green: 211.0/255.0, blue: 211.0/255.0, alpha: 1.0).cgColor
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(gesture:)))
               // add it to the image view
               imageView.addGestureRecognizer(tapGesture)
               // make sure imageView can be interacted with by user
               imageView.isUserInteractionEnabled = true
        
        let buttonItem = UIBarButtonItem(customView: imageView)
        buttonItem.customView?.widthAnchor.constraint(equalToConstant: 25).isActive = true
        buttonItem.customView?.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        navigationItem.rightBarButtonItem = buttonItem
        navigationItem.title = chatPartnerName
        navigationItem.largeTitleDisplayMode = .never
        
        messageInputBar.inputTextView.tintColor = UIColor.lightGray
        messageInputBar.inputTextView.placeholder = "Nachricht eingeben"
        
        messageInputBar.sendButton.setTitleColor(UIColor.lightGray, for: .normal)
        messageInputBar.sendButton.setSize(CGSize(width: 70, height: 36), animated: false)
        messageInputBar.sendButton.title = "Senden"
        messageInputBar.setRightStackViewWidthConstant(to: 70.0, animated: false)
        
        messageInputBar.delegate = self
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        maintainPositionOnKeyboardFrameChanged = true
        
        self.loadChat()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if listener != nil {
            listener!.remove()
        }
    }
        
    // MARK: - Methods
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        if (gesture.view as? UIImageView) != nil {
            let backItem = UIBarButtonItem()
            backItem.title = "Zurück"
            navigationItem.backBarButtonItem = backItem
            
            let storyboard = UIStoryboard(name: "Neighbors", bundle: nil)
            let neighborTableViewController = storyboard.instantiateViewController(withIdentifier: "neighborTableVC") as! NeighborTableViewController
            neighborTableViewController.cameFromChat = true
            
            let chatPartner = MainController.allUsers.first(where: { $0.uid == chatPartnerUID})
            
            if chatPartner == nil {
                MainController.database.collection("users")
                    .document(chatPartnerUID!)
                    .getDocument { (querySnapshot, error) in
                        if error != nil {
                            print("Error getting document: \(error!.localizedDescription)")
                        } else {
                            do {
                                // get current user
                                neighborTableViewController.user = try User().mapData(uid: querySnapshot!.documentID, data: querySnapshot!.data()!)
                                
                                // get profile image if it exists
                                MainController.storage
                                    .reference(withPath: "profilePictures/\(String(describing: self.chatPartnerUID!))/profilePicture.jpg")
                                    .getData(maxSize: 4 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            print("Error while downloading profile image: \(error.localizedDescription)")
                                            // Using default image
                                            neighborTableViewController.user.profileImage = UIImage(named: "defaultProfilePicture")!
                                        } else {
                                            // Data for "profilePicture.jpg" is returned
                                            neighborTableViewController.user.profileImage = UIImage(data: data!)!
                                        }
                                        
                                        self.navigationController?.pushViewController(neighborTableViewController, animated: true)
                                }
                                
                            } catch UserError.mapDataError {
                                print("Error while mapping User!")
                                let alert = Utility.displayAlert(withMessage: nil, withSignOut: true)
                                self.present(alert, animated: true, completion: nil)
                            } catch {
                                print("Unexpected error: \(error)")
                            }
                        }
                }
            } else {
                neighborTableViewController.user = chatPartner
                self.navigationController?.pushViewController(neighborTableViewController, animated: true)
            }
        }
    }
    
    // MARK: - Custom messages handlers
    
    func createNewChat() {
        let users = [MainController.currentUser.uid, self.chatPartnerUID]
        let data: [String: Any] = [
            "users": users
        ]
        
        docReference = MainController.database.collection("Chats").document()
        batch.setData(data, forDocument: docReference!)
    }
    
    func loadChat() {
        // Fetch all the chats which has current user in it
        MainController.database.collection("Chats")
            .whereField("users", arrayContains: MainController.currentUser.uid)
            .getDocuments { (chatQuerySnap, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                } else {
                    // Count the no. of documents returned
                    let numberOfChats = chatQuerySnap!.documents.count
                    
                    if numberOfChats == 0 {
                        // If documents count is zero that means there is no chat available and we need to create a new instance
                        self.createNewChat()
                    }
                    else if numberOfChats >= 1 {
                        // Chat(s) found for currentUser
                        for loadedChat in chatQuerySnap!.documents {
                            // Get the chat with the chat partner
                            if (loadedChat.data()["users"] as! Array).contains(self.chatPartnerUID!) {
                                self.docReference = loadedChat.reference
                                // fetch it's thread collection
                                self.listener = loadedChat.reference.collection("thread")
                                    .order(by: "created", descending: false)
                                    .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                        if let error = error {
                                            print("Error: \(error)")
                                            return
                                        } else {
                                            self.messages.removeAll()
                                            for message in threadQuery!.documents {
                                                do {
                                                    let newMessage = try Message().mapData(data: message.data())
                                                    self.messages.append(newMessage!)
                                                } catch MessageError.mapDataError {
                                                    print("Error while mapping User!")
                                                    let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                                                    self.present(alert, animated: true, completion: nil)
                                                } catch {
                                                    print("Unexpected error: \(error)")
                                                    let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                                                    self.present(alert, animated: true, completion: nil)
                                                }
                                            }
                                            self.messagesCollectionView.reloadData()
                                            self.messagesCollectionView.scrollToBottom(animated: true)
                                        }
                                    })
                                return
                            }
                        }
                        self.createNewChat()
                    } else {
                        print("Let's hope this error never prints!")
                    }
                }
        }
    }
    
    private func insertNewMessage(_ message: Message) {
        messages.append(message)
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
    
    private func save(_ message: Message) {
        let data: [String: Any] = [
            "content": message.content,
            "created": message.created,
            "id": message.id,
            "senderID": message.senderUID
        ]
        if let docReference = docReference {
            let messageRef = docReference.collection("thread").document()
            batch.setData(data, forDocument: messageRef)
            batch.commit()
            batch = MainController.database.batch()
        }
        
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor
    {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, senderUID: MainController.currentUser.uid, created: Timestamp(), content: text)
        
        insertNewMessage(message)
        save(message)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        if MainController.currentUser == nil {
            return Sender(senderId: "User not found")
        } else {
            return Sender(senderId: MainController.currentUser.uid)
        }
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // MARK: - MessagesLayoutDelegate
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    // MARK: - MessagesDisplayDelegate
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .blue: .lightGray
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if MainController.currentUser != nil {
            if message.sender.senderId == MainController.currentUser.uid {
                avatarView.image = MainController.currentUser.profileImage
            } else {
                avatarView.image = chatPartnerProfileImage
            }
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
}
