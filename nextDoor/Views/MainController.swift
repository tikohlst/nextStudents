//
//  MainController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase

class MainController: UITabBarController {

    // MARK: - Variables

    static let database = Firestore.firestore()
    static let storage = Storage.storage()
    static var currentUserAuth: Firebase.User!
    static var currentUser: User!
    static var currentUserUpdated = true

    // MARK: - UIViewController events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if MainController.currentUser != nil {
            checkMissingUserData()
        }
    }

    override func viewDidLoad() {
        MainController.currentUserAuth = Auth.auth().currentUser!

        MainController.database.collection("users")
            .document(MainController.currentUserAuth.uid)
            .addSnapshotListener { (querySnapshot, error) in
            if error != nil {
                print("Error getting document: \(error!.localizedDescription)")
            } else {
                do {
                    // get current user
                    MainController.currentUser = try User.mapData(querySnapshot: querySnapshot!)

                    // get profile image if it exists
                    MainController.storage
                        .reference(withPath: "profilePictures/\(String(describing: MainController.currentUser.uid))/profilePicture.jpg")
                        .getData(maxSize: 4 * 1024 * 1024) { data, error in
                        if let error = error {
                            print("Error while downloading profile image: \(error.localizedDescription)")
                        } else {
                            // Data for "profilePicture.jpg" is returned
                            MainController.currentUser.profileImage = UIImage(data: data!)!
                        }
                    }

                    // check if userdata is complete
                    self.checkMissingUserData()

                } catch UserError.mapDataError {
                    print("Error while mapping User!")
                    let alert = MainController.displayAlert(withMessage: nil, withSignOut: true)
                    self.present(alert, animated: true, completion: nil)
                } catch {
                    print("Unexpected error: \(error)")
                }
            }
        }
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // MARK: - Helper methods

    func checkMissingUserData() {
        if MainController.currentUser.firstName.isEmpty || MainController.currentUser.lastName.isEmpty ||
            MainController.currentUser.street.isEmpty || MainController.currentUser.housenumber.isEmpty ||
            MainController.currentUser.zipcode.isEmpty || MainController.currentUser.radius == 0 {
            // prompt the registration screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(identifier: "registrationvc") as RegistrationViewController
            viewController.accountInfoMissing = true
            viewController.navigationItem.title = "Registrierung abschließen"

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .crossDissolve
            self.present(navigationController, animated: true, completion: nil)
        }
    }

    static func displayAlert(withMessage message: String?, withSignOut: Bool) -> UIAlertController {
        let alert = UIAlertController(
            title: "Interner Fehler",
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

    static func getCoordinate( addressString: String, completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
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

}
