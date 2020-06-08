//
//  User.swift
//  nextDoor
//
//  Created by Tim Kohlstadt on 22.05.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import Foundation

struct User {
    private static var identifierCounter = 0
    
    private let identifier: Int
    var firstName: String
    var lastName: String
    var address: String
    
    
    private static func getUniqueIdentifier() -> Int {
        // Inside of the struct/class the Classname for the static var isnt needed
        // Card.identifierCounter += 1
        identifierCounter += 1
        return identifierCounter
    }
    
    init() {
        self.identifier = User.getUniqueIdentifier()
        self.firstName = ""
        self.lastName = ""
        self.address = ""
    }
}
