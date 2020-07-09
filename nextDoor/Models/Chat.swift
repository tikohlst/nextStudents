//
//  Chat.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase

enum ChatError: Error {
    case mapDataError
}

struct Chat {
    
    // MARK: - Variables
    
    var localChatID: String
    var chatPartner: User
    var latestMessage: String
    var timestampOfTheLatestMessage: Timestamp
    
    // MARK: - Methods
    
    init(localChatID: String, chatPartner: User, latestMessage: String, timestampOfTheLatestMessage: Timestamp) {
        self.localChatID = localChatID
        self.chatPartner = chatPartner
        self.latestMessage = latestMessage
        self.timestampOfTheLatestMessage = timestampOfTheLatestMessage
    }
    
    static func mapData(querySnapshot: DocumentSnapshot, chatPartner: User) throws -> Chat? {
        
        let data = querySnapshot.data()
        
        // Data validation
        guard let localChatID = data?["id"] as? String,
            let latestMessage = data?["content"] as? String,
            let timestampOfTheLatestMessage = data?["created"] as? Timestamp
            else {
                throw ChatError.mapDataError
        }
        
        return Chat(localChatID: localChatID,
                    chatPartner: chatPartner,
                    latestMessage: latestMessage,
                    timestampOfTheLatestMessage: timestampOfTheLatestMessage
        )
    }
    
}
