//
//  User.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Foundation
import UIKit

class User {

    // MARK: - Variables

    let uid: String
    var firstName: String
    var lastName: String
    var street: String
    var housenumber: String
    var plz: String
    var radius: Int
    var bio: String
    var skills: String
    var profileImage: UIImage

    // MARK: - Methods

    init(uid: String, firstName: String, lastName: String, street: String,
         housenumber: String, plz: String, radius: Int, bio: String, skills: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.street = street
        self.housenumber = housenumber
        self.plz = plz
        self.radius = radius
        self.bio = bio
        self.skills = skills
        self.profileImage = UIImage(named: "defaultProfilePicture")!
    }

}
