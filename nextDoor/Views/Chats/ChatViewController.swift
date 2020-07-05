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

    // MARK: - UIViewController events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.title = chatPartnerName
        navigationItem.title = chatPartnerName
        navigationItem.largeTitleDisplayMode = .never
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = UIColor.lightGray
        messageInputBar.sendButton.setTitleColor(UIColor.lightGray, for: .normal)

        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        self.loadChat()
    }

    // MARK: - Custom messages handlers

    func createNewChat() {
        let users = [MainController.currentUser.uid, self.chatPartnerUID]
        let data: [String: Any] = [
             "users":users
        ]

        MainController.database.collection("Chats")
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
                            loadedChat.reference.collection("thread")
                            .order(by: "created", descending: false)
                            .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                if let error = error {
                                    print("Error: \(error)")
                                    return
                                } else {
                                    self.messages.removeAll()
                                    for message in threadQuery!.documents {
                                        do {
                                            let newMessage = try Message.mapData(querySnapshot: message)
                                            self.messages.append(newMessage!)
                                        } catch MessageError.mapDataError {
                                            let alert = MainController.displayAlert(withMessage: "Error while mapping User!", withSignOut: false)
                                            self.present(alert, animated: true, completion: nil)
                                        } catch {
                                            let alert = MainController.displayAlert(withMessage: "Unexpected error: \(error)", withSignOut: false)
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
        let message = Message(id: UUID().uuidString, senderUID: MainController.currentUser.uid, created: Timestamp(), content: text)

        insertNewMessage(message)
        save(message)

        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }

    // MARK: - MessagesDataSource

    func currentSender() -> SenderType {
        return Sender(id: MainController.currentUser.uid, displayName: MainController.currentUserAuth.displayName ?? "Name not found")
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

        if message.sender.senderId == MainController.currentUser.uid {
            avatarView.image = MainController.currentUser.profileImage
        } else {
            avatarView.image = chatPartnerProfileImage
        }
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
    }

}
