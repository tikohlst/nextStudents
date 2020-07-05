//
//  Offer.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase

enum OfferError: Error {
    case mapDataError
}

struct Offer {

    // MARK: - Variables

    var uid: String
    var title: String
    var description: String
    var duration: String
    var date: Date
    var type: String
    var ownerUID: String
    var ownerFirstName: String
    var ownerLastName: String
    var offerImage: UIImage

    // MARK: - Methods

    init(uid: String, ownerUID: String, ownerFirstName: String, ownerLastName: String, title: String, description: String,
         date: Date, duration: String, type: String) {
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
    }

    static func mapData(querySnapshotOffer: DocumentSnapshot,
                        querySnapshotOwner: DocumentSnapshot) throws -> Offer {

        let dataOffer = querySnapshotOffer.data()
        let dataOwner = querySnapshotOwner.data()

        // Data validation
        guard let title = dataOffer?["title"] as? String,
            let description = dataOffer?["description"] as? String,
            let date = dataOffer?["date"] as? Timestamp,
            let duration = dataOffer?["duration"] as? String,
            let type = dataOffer?["type"] as? String
        else {
            throw OfferError.mapDataError
        }

        // Data validation
        guard let ownerFirstName = dataOwner?["firstName"] as? String,
            let ownerLastName = dataOwner?["lastName"] as? String
        else {
            throw UserError.mapDataError
        }

        return Offer(uid: querySnapshotOffer.documentID,
                     ownerUID: querySnapshotOwner.documentID,
                     ownerFirstName: ownerFirstName,
                     ownerLastName: ownerLastName,
                     title: title,
                     description: description,
                     date: date.dateValue(),
                     duration: duration,
                     type: type
        )
    }

}
