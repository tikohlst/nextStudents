//
//  User.swift
//  nextDoor
//
//  Created by Tim Kohlstadt on 22.05.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import Foundation

struct User {
    
    let uid: String
    var firstName: String
    var lastName: String
    var address: String
    var radius: String
    //var image: UIImage
    
    init(uid: String, firstName: String, lastName: String, address: String, radius: String) { //image: UIImage
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.radius = radius
        //self.image = image
    }
}
