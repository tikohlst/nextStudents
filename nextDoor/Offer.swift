//
//  Offer.swift
//  nextDoor
//
//  Created by Tim Kohlstadt on 03.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import Foundation

struct Offer {    
    private static var identifierCounter = 0
    
    private let identifier: Int
    var name: String
    var description: String
    var duration: String
    
    
    private static func getUniqueIdentifier() -> Int {
        // Inside of the struct/class the Classname for the static var isnt needed
        // Offer.identifierCounter += 1
        identifierCounter += 1
        return identifierCounter
    }
    
    init() {
        self.identifier = Offer.getUniqueIdentifier()
        self.name = ""
        self.description = ""
        self.duration = ""
    }
}
