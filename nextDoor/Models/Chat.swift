//
//  Chat.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

struct Chat {

    var users: [String]
    var dictionary: [String:Any] {
        return [
            "users": users
        ]
    }
    var timestamp: Timestamp

}

extension Chat {

    init?(dictionary: [String:Any], timestamp: Timestamp) {
        guard let chatUsers = dictionary["users"] as? [String] else {return nil}
        self.init(users: chatUsers, timestamp: timestamp)
    }

}
