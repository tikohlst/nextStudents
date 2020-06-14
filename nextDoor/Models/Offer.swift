//
//  Offer.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct Offer {
    
    var id: String
    var title: String
    var description: String
    var duration: String
    var date: Date
    var type: String
    var owner: String
    
    
    init(from dictionary: [String:Any], with id: String, owner: String) {
        self.title = dictionary["title"] as! String
        self.description = dictionary["description"] as! String
        self.date = (dictionary["date"] as! Timestamp).dateValue()
        self.duration = dictionary["duration"] as! String
        self.type = dictionary["type"] as! String
        self.id = id
        self.owner = owner
    }
}
