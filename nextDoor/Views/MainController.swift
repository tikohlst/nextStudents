//
//  MainController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

class MainController: UITabBarController {

    // MARK: - Variables

    static let database = Firestore.firestore()
    static let storage = Storage.storage()
    static let currentUserAuth = Auth.auth().currentUser!
    static var currentUser: User!

    // MARK: - UIViewController events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if MainController.currentUser != nil {
            checkMissingUserData()
        }
    }

    override func viewDidLoad() {
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

                } catch UserError.mapDataError {
                    let alert = MainController.displayAlert(withMessage: "Error while mapping User!", withSignOut: true)
                    self.present(alert, animated: true, completion: nil)
                } catch {
                    print("Unexpected error: \(error)")
                }
                // check if userdata is complete
                self.checkMissingUserData()
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
            let vc = storyboard.instantiateViewController(identifier: "registrationvc") as RegistrationViewController
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            vc.accountInfoMissing = true
            vc.user = MainController.currentUser
            self.present(vc, animated: true, completion: nil)
        }
    }

    static func displayAlert(withMessage message: String, withSignOut: Bool) -> UIAlertController {
        let alert = UIAlertController(
            title: "Internal error",
            message: "Please contact support",
            preferredStyle: .alert)

        if withSignOut {
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Sign out", comment: ""),
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

}
