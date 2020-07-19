//
//  User.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase
import CoreLocation

enum UserError: Error {
    case mapDataError
}

protocol UserService {
    func mapData(uid: String, data: [String:Any]?) throws -> User
}

class User: UserService {
    
    // MARK: - Variables
    
    let uid: String
    var firstName: String
    var lastName: String
    var street: String
    var housenumber: String
    var zipcode: String
    var gpsCoordinates: GeoPoint
    var radius: Int
    var bio: String
    var skills: String
    var profileImage: UIImage
    
    // MARK: - Methods
    
    init(uid: String, firstName: String, lastName: String, street: String,
         housenumber: String, zipcode: String, gpsCoordinates: GeoPoint,
         radius: Int, bio: String, skills: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.street = street
        self.housenumber = housenumber
        self.zipcode = zipcode
        self.gpsCoordinates = gpsCoordinates
        self.radius = radius
        self.bio = bio
        self.skills = skills
        self.profileImage = UIImage(named: "defaultProfilePicture")!
    }
    
    convenience init(){
        self.init(uid: "", firstName: "", lastName: "", street: "",
                  housenumber: "", zipcode: "", gpsCoordinates: GeoPoint(latitude: 0, longitude: 0),
                  radius: 0, bio: "", skills: "")
    }
    
    func mapData(uid: String, data: [String: Any]?) throws -> User {
        
        // Data validation
        guard let firstName = data?["firstName"] as? String,
            let lastName = data?["lastName"] as? String,
            let street = data?["street"] as? String,
            let housenumber = data?["housenumber"] as? String,
            let zipcode = data?["zipcode"] as? String,
            let gpsCoordinates = data?["gpsCoordinates"] as? GeoPoint,
            let radius = data?["radius"] as? Int,
            let bio = data?["bio"] as? String,
            let skills = data?["skills"] as? String
            else {
                throw UserError.mapDataError
        }
        
        return User(uid: uid,
                    firstName: firstName,
                    lastName: lastName,
                    street: street,
                    housenumber: housenumber,
                    zipcode: zipcode,
                    gpsCoordinates: gpsCoordinates,
                    radius: radius,
                    bio: bio,
                    skills: skills
        )
    }
    
}
