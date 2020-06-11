//
//  Chat.swift
//  nextDoor
//
//  Created by Tim Kohlstadt on 10.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit

struct Chat {
    var users: [String]
    var dictionary: [String:Any] {
        return [
            "users": users
        ]
    }
}

extension Chat {
    init?(dictionary: [String:Any]) {
        guard let chatUsers = dictionary["users"] as? [String] else {return nil}
        self.init(users: chatUsers)
    }
}
