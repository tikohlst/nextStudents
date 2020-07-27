//
//  Offer.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase

enum OfferError: Error {
    case mapDataError
}

protocol OfferService {
    func mapData(uidOffer: String, dataOffer: [String:Any]?,
                 uidOwner: String, dataOwner: [String:Any]?) throws -> Offer
}

struct Offer: OfferService {
    
    
    // MARK: - Variables
    
    var uid: String
    var title: String
    var description: String
    var duration: String
    var timeFormat: String
    var date: Date
    var type: String
    var ownerUID: String
    var ownerFirstName: String
    var ownerLastName: String
    var offerImage: UIImage
    
    // MARK: - Methods
    
    init(uid: String, ownerUID: String, ownerFirstName: String,
         ownerLastName: String, title: String, description: String,
         date: Date, duration: String, type: String, timeFormat: String) {
        self.uid = uid
        self.ownerUID = ownerUID
        self.ownerFirstName = ownerFirstName
        self.ownerLastName = ownerLastName
        self.title = title
        self.description = description
        self.date = date
        self.duration = duration
        self.type = type
        self.offerImage = UIImage(named: "defaultOfferImage")!
        self.timeFormat = timeFormat
    }
    
    init() {
        self.init(uid: "", ownerUID: "", ownerFirstName: "", ownerLastName: "",
                  title: "", description: "", date: Date(),
                  duration: "15", type: "", timeFormat: "Min.")
    }
    
    func mapData(uidOffer: String, dataOffer: [String:Any]?,
                 uidOwner: String, dataOwner: [String:Any]?) throws -> Offer {
        
        // Data validation
        guard let title = dataOffer?["title"] as? String,
            let description = dataOffer?["description"] as? String,
            let date = dataOffer?["date"] as? Timestamp,
            let duration = dataOffer?["duration"] as? String,
            let type = dataOffer?["type"] as? String,
            let timeFormat = dataOffer?["timeFormat"] as? String
            else {
                throw OfferError.mapDataError
        }
        
        // Data validation
        guard let ownerFirstName = dataOwner?["firstName"] as? String,
            let ownerLastName = dataOwner?["lastName"] as? String
            else {
                throw UserError.mapDataError
        }
        
        return Offer(uid: uidOffer,
                     ownerUID: uidOwner,
                     ownerFirstName: ownerFirstName,
                     ownerLastName: ownerLastName,
                     title: title,
                     description: description,
                     date: date.dateValue(),
                     duration: duration,
                     type: type,
                     timeFormat: timeFormat
        )
    }
    
}
