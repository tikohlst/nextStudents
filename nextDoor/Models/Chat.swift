//
//  Chat.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase
import FirebaseFirestore

struct Chat {

    // MARK: - Variables

    var chatUID: String = ""
    var chatPartnerUID: String = ""
    var users: [String]
    var dictionary: [String:Any] {
        return [
            "users": users
        ]
    }
    var timestamp: Timestamp?
    var latestMessage: String = ""
    var chatPartnerProfileImage: UIImage? = nil
    var chatPartnerFirstName = "Gelöschter"
    var chatPartnerLastName = "Account"

}

extension Chat {

    // MARK: - Methods

    init?(dictionary: [String:Any]) {
        guard let chatUsers = dictionary["users"] as? [String] else {return nil}
        self.init(users: chatUsers)
    }

}
