//
//  Utilities.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import CoreLocation
import Firebase
import UIKit

enum SortOption: String {
    case firstName = "Vorname"
    case lastName = "Nachname"
    case distance = "Entfernung"
    case title = "Alphabetisch"
    case date = "Neuste zuerst"
    case duration = "Kürzeste Dauer"
    case type = "Typ"
}

class Utility {
    
    static func displayAlert(withTitle title: String = "Interner Fehler", withMessage message: String?, withSignOut: Bool) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: message ?? "Bitte wenden Sie sich an den Support.",
            preferredStyle: .alert)
        
        if withSignOut {
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Ausloggen", comment: ""),
                    style: .default,
                    handler: { action in
                        SettingsTableViewController.signOut()
                })
            )
        } else {
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Ok", comment: ""),
                    style: .default
                )
            )
        }
        
        return alert
    }
    
    static func lookUpCurrentLocation(locationManager: CLLocationManager, completionHandler: @escaping (CLPlacemark?) -> Void ) {
        // Use the last reported location.
        if let lastLocation = locationManager.location {
            let geocoder = CLGeocoder()
            
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                                            completionHandler: { (placemarks, error) in
                                                if error == nil {
                                                    let firstLocation = placemarks?[0]
                                                    completionHandler(firstLocation)
                                                }
                                                else {
                                                    // An error occurred during geocoding.
                                                    completionHandler(nil)
                                                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
    
    static func getCoordinate( addressString: String,
                               completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
            
            completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
        }
    }
    
    static func getGPSDifference(_ gpsCoordinates1: GeoPoint,_ gpsCoordinates2: GeoPoint) -> Double {
        
        let radius = 6371 // Earth's radius in kilometers
        let latDelta = degreesToRadians(gpsCoordinates2.latitude - gpsCoordinates1.latitude)
        let lonDelta = degreesToRadians(gpsCoordinates2.longitude - gpsCoordinates1.longitude)
        
        let a = (sin(latDelta / 2) * sin(latDelta / 2)) +
            (cos(degreesToRadians(gpsCoordinates1.latitude)) * cos(degreesToRadians(gpsCoordinates2.latitude)) *
                sin(lonDelta / 2) * sin(lonDelta / 2))
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        let differenceInKilometer = Double(radius) * c
        let differenceInMeter = differenceInKilometer * 1000
        return differenceInMeter
    }
    
    static func degreesToRadians(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
}
