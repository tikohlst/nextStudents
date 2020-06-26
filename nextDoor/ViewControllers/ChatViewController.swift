//
//  ChatViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import MessageKit
import InputBarAccessoryView
import SDWebImage
import FirebaseStorage

class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {

    // MARK: - Variables

    var db = Firestore.firestore()
    var storage = Storage.storage()
    let currentUserUID = Auth.auth().currentUser!.uid
    var currentUserProfileImage: UIImage? = nil

    var chatsArray: [Chat] = []
    private let showChatDetailSegue = "showChatDetail"

    var user2UID: String?
    var user2Name: String?
    var user2Img: UIImage? = nil

    private var docReference: DocumentReference?

    var messages: [Message] = []

    // MARK: - UIViewController events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.title = user2Name
        navigationItem.title = user2Name
        navigationItem.largeTitleDisplayMode = .never
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = UIColor.lightGray
        messageInputBar.sendButton.setTitleColor(UIColor.lightGray, for: .normal)

        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        // Get profile image of the current user
        let storageRef = self.storage.reference(withPath: "profilePictures/\(currentUserUID)/profilePicture.jpg")
        storageRef.getData(maxSize: 4 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error while downloading profile image: \(error.localizedDescription)")
                self.currentUserProfileImage = UIImage(named: "defaultProfilePicture")
            } else {
                // Data for "profilePicture.jpg" is returned
                self.currentUserProfileImage = UIImage(data: data!)
            }
            self.loadChat()
        }
    }

    // MARK: - Custom messages handlers

    func createNewChat() {
        let users = [self.currentUserUID, self.user2UID]
        let data: [String: Any] = [
             "users":users
        ]

        db.collection("Chats")
            .addDocument(data: data) { (error) in
                if let error = error {
                    print("Unable to create chat! \(error)")
                    return
                } else {
                    self.loadChat()
                }
        }
    }

    func loadChat() {
        // Fetch all the chats which has current user in it
        db.collection("Chats")
            .whereField("users", arrayContains: currentUserUID)
            .getDocuments { (chatQuerySnap, error) in
            if let error = error {
                print("Error: \(error)")
                return
            } else {
                // Count the no. of documents returned
                let queryCount = chatQuerySnap!.documents.count

                if queryCount == 0 {
                    // If documents count is zero that means there is no chat available and we need to create a new instance
                    self.createNewChat()
                }
                else if queryCount >= 1 {
                    // Chat(s) found for currentUser
                    for doc in chatQuerySnap!.documents {
                        let chat = Chat(dictionary: doc.data())
                        // Get the chat which has user2 id
                        if chat!.users.contains(self.user2UID ?? "") {
                            self.docReference = doc.reference
                            // fetch it's thread collection
                             doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                if let error = error {
                                    print("Error: \(error)")
                                    return
                                } else {
                                    self.messages.removeAll()
                                    for message in threadQuery!.documents {
                                        let msg = Message(dictionary: message.data())
                                        self.messages.append(msg!)
                                        //print("Data: \(msg?.content ?? "No message found")")
                                    }
                                    self.messagesCollectionView.reloadData()
                                    self.messagesCollectionView.scrollToBottom(animated: true)
                                }
                            })
                            return
                        } //end of if
                    } //end of for
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
            "senderID": message.senderID,
            "senderName": message.senderName
        ]

        docReference?.collection("thread").addDocument(data: data, completion: { (error) in
            if let error = error {
                print("Error sending message: \(error)")
                return
            }
            self.messagesCollectionView.scrollToBottom()
        })
    }

    // MARK: - InputBarAccessoryViewDelegate

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: currentUserUID, senderName: "sender")

        insertNewMessage(message)
        save(message)

        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }

    // MARK: - MessagesDataSource

    func currentSender() -> SenderType {
        return Sender(id: currentUserUID, displayName: Auth.auth().currentUser?.displayName ?? "Name not found")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        if messages.count == 0 {
            print("No messages to display")
            return 0
        } else {
            return messages.count
        }
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

        if message.sender.senderId == currentUserUID {
            avatarView.image = currentUserProfileImage
        } else {
            avatarView.image = user2Img
        }
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
    }

}
