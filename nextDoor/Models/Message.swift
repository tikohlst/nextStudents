//
//  Message.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase
import MessageKit

enum MessageError: Error {
    case mapDataError
}

struct Message {

    // MARK: - Variables

    var id: String
    var senderUID: String
    var created: Timestamp
    var content: String

    // MARK: - Methods

    init(id: String, senderUID: String, created: Timestamp, content: String){
        self.id = id
        self.senderUID = senderUID
        self.created = created
        self.content = content
    }

    static func mapData(querySnapshot: DocumentSnapshot) throws -> Message? {

        let data = querySnapshot.data()

        // Data validation
        guard let id = data?["id"] as? String,
            let senderUID = data?["senderID"] as? String,
            let created = data?["created"] as? Timestamp,
            let content = data?["content"] as? String
        else {
            throw MessageError.mapDataError
        }

        return Message(id: id,
                    senderUID: senderUID,
                    created: created,
                    content: content
        )
    }

}

extension Message: MessageType {

    var sender: SenderType {
        return Sender(id: senderUID, displayName: "")
    }

    var messageId: String {
        return id
    }

    var sentDate: Date {
        return created.dateValue()
    }

    var kind: MessageKind {
        return .text(content)
    }

}
