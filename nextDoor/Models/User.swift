//
//  User.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

enum UserError: Error {
    case mapDataError
}

class User {

    // MARK: - Variables

    let uid: String
    var firstName: String
    var lastName: String
    var street: String
    var housenumber: String
    var zipcode: String
    var radius: Int
    var bio: String
    var skills: String
    var profileImage: UIImage

    // MARK: - Methods

    init(uid: String, firstName: String, lastName: String, street: String,
         housenumber: String, zipcode: String, radius: Int, bio: String, skills: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.street = street
        self.housenumber = housenumber
        self.zipcode = zipcode
        self.radius = radius
        self.bio = bio
        self.skills = skills
        self.profileImage = UIImage(named: "defaultProfilePicture")!
    }

    static func mapData(querySnapshot: DocumentSnapshot) throws -> User {

        let data = querySnapshot.data()

        // Data validation
        guard let firstName = data?["firstName"] as? String,
                let lastName = data?["lastName"] as? String,
                let street = data?["street"] as? String,
                let housenumber = data?["housenumber"] as? String,
                let zipcode = data?["zipcode"] as? String,
                let radius = data?["radius"] as? Int,
                let bio = data?["bio"] as? String,
                let skills = data?["skills"] as? String
        else {
            throw UserError.mapDataError
        }

        let user = User(uid: querySnapshot.documentID,
                        firstName: firstName,
                        lastName: lastName,
                        street: street,
                        housenumber: housenumber,
                        zipcode: zipcode,
                        radius: radius,
                        bio: bio,
                        skills: skills
        )

        return user
    }

}
