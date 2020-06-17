//
//  User.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Foundation
import UIKit

struct User {

    let uid: String
    var firstName: String
    var lastName: String
    var address: String
    var radius: String
    var bio: String
    var profileImage: UIImage? = nil

    init(uid: String, firstName: String, lastName: String, address: String,
         radius: String, bio: String) { //image: UIImage
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.radius = radius
        self.bio = bio
    }

}
