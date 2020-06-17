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
    var timestamp: Timestamp?
    var latestMessage: String = ""
    var chatUID: String = ""
    var chatPartnerUID: String = ""
    var chatPartnerProfileImage: UIImage? = nil
    var chatPartnerFirstName = "Gelöschter"
    var chatPartnerLastName = "Account"

}

extension Chat {

    init?(dictionary: [String:Any]) {
        guard let chatUsers = dictionary["users"] as? [String] else {return nil}
        self.init(users: chatUsers)
    }

}
