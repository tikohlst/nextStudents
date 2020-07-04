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
    var offerImage: UIImage

    // MARK: - Methods

    init(uid: String, ownerUID: String, title: String, description: String,
         date: Date, duration: String, type: String) {
        self.uid = uid
        self.ownerUID = ownerUID
        self.title = title
        self.description = description
        self.date = date
        self.duration = duration
        self.type = type
        self.offerImage = UIImage(named: "defaultOfferImage")!
    }

    static func mapData(querySnapshot: DocumentSnapshot,
                        ownerUID: String) throws -> Offer {

        let data = querySnapshot.data()

        // Data validation
        guard let title = data?["title"] as? String,
            let description = data?["description"] as? String,
            let date = data?["date"] as? Timestamp,
            let duration = data?["duration"] as? String,
            let type = data?["type"] as? String
        else {
            throw OfferError.mapDataError
        }

        return Offer(uid: querySnapshot.documentID,
                          ownerUID: ownerUID,
                          title: title,
                          description: description,
                          date: date.dateValue(),
                          duration: duration,
                          type: type
        )
    }

}
