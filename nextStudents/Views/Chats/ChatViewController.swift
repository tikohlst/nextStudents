//
//  ChatViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    // MARK: - Variables
    
    var chatPartnerUID: String?
    var chatPartnerName: String?
    var chatPartnerProfileImage: UIImage?
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    var listener: ListenerRegistration?
    
    var batch = MainController.dataService.database.batch()
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let button = UIButton()
        button.setImage(chatPartnerProfileImage, for: .normal)
        button.addTarget(self, action: #selector(imageTapped), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        
        // Show profile image rounded
        button.imageView?.layer.cornerRadius = 15
        button.imageView?.layer.borderWidth = 0.5
        button.imageView?.layer.borderColor = UIColor(displayP3Red: 211.0/255.0, green: 211.0/255.0, blue: 211.0/255.0, alpha: 1.0).cgColor
        
        let buttonItem = UIBarButtonItem(customView: button)
        buttonItem.customView?.widthAnchor.constraint(equalToConstant: 30).isActive = true
        buttonItem.customView?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
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
    
    @objc func imageTapped() {
        let backItem = UIBarButtonItem()
        backItem.title = "Zurück"
        navigationItem.backBarButtonItem = backItem
        
        let storyboard = UIStoryboard(name: "Neighbors", bundle: nil)
        let neighborTableViewController = storyboard.instantiateViewController(withIdentifier: "neighborTableVC") as! NeighborTableViewController
        neighborTableViewController.cameFromChat = true
        
        let chatPartner = MainController.dataService.allUsers.first(where: { $0.uid == chatPartnerUID})
        
        if chatPartner == nil {
            MainController.dataService.getNeighbor(with: chatPartnerUID!, completion: {data, documentID in
                do {
                    // Get current user
                    neighborTableViewController.user = try User().mapData(uid: documentID, data: data)
                    
                    // Get profile image if it exists
                    MainController.dataService.getProfilePicture(for: self.chatPartnerUID!, completion: { image in
                        neighborTableViewController.user.profileImage = image
                        self.navigationController?.pushViewController(neighborTableViewController, animated: true)
                    })
                } catch UserError.mapDataError {
                    print("Error while mapping User!")
                    let alert = Utility.displayAlert(withMessage: nil, withSignOut: true)
                    self.present(alert, animated: true, completion: nil)
                } catch {
                    print("Unexpected error: \(error)")
                }
            })
        } else {
            neighborTableViewController.user = chatPartner
            self.navigationController?.pushViewController(neighborTableViewController, animated: true)
        }
    }
    
    // MARK: - Custom messages handlers
    
    func createNewChat() {
        let users = [MainController.dataService.currentUser.uid, self.chatPartnerUID]
        let data: [String: Any] = [
            "users": users
        ]
        
        docReference = MainController.dataService.database.collection("Chats").document()
        batch.setData(data, forDocument: docReference!)
    }
    
    func loadChat() {
        // Fetch all the chats which has current user in it
        MainController.dataService.getChats(for: MainController.dataService.currentUser.uid, completion: { chatQuerySnap in
            // Count the no. of documents returned
            let numberOfChats = chatQuerySnap.documents.count
            
            if numberOfChats == 0 {
                // If documents count is zero that means there is no chat available and we need to create a new instance
                self.createNewChat()
            }
            else if numberOfChats >= 1 {
                // Chat(s) found for currentUser
                for loadedChat in chatQuerySnap.documents {
                    // Get the chat with the chat partner
                    if (loadedChat.data()["users"] as! Array).contains(self.chatPartnerUID!) {
                        self.docReference = loadedChat.reference
                        // Fetch it's thread collection
                        self.listener = MainController.dataService.createListenerForChatThreadOrdered(snapshot: loadedChat, completion: { threadQuery in
                            self.messages.removeAll()
                            for message in threadQuery.documents {
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
                        })
                        return
                    }
                }
                // Only gets called, when the searched chat doesn't already exist
                self.createNewChat()
            }
        })
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
            batch = MainController.dataService.database.batch()
        }
        
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, senderUID: MainController.dataService.currentUser.uid, created: Timestamp(), content: text)
        
        insertNewMessage(message)
        save(message)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        if MainController.dataService.currentUser == nil {
            return Sender(senderId: "User not found")
        } else {
            return Sender(senderId: MainController.dataService.currentUser.uid)
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
        if MainController.dataService.currentUser != nil {
            if message.sender.senderId == MainController.dataService.currentUser.uid {
                avatarView.image = MainController.dataService.currentUser.profileImage
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
