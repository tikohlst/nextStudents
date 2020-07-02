//
//  MainController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

class MainController: UITabBarController {

    // MARK: - Variables

    let db = Firestore.firestore()
    var currentUser : User!

    // MARK: - UIViewController events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if currentUser != nil {
            checkMissingUserData()
        }
    }

    override func viewDidLoad() {
        db.collection("users")
            .document(Auth.auth().currentUser!.uid)
            .addSnapshotListener { (querySnapshot, error) in
            if error != nil {
                print("Error getting document: \(error!.localizedDescription)")
            } else {
                do {
                    self.currentUser = try User.mapData(querySnapshot: querySnapshot!)
                } catch UserError.mapDataError {
                    return self.displaySignOutAlert("Error: Wrong action handler!")
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
        if self.currentUser.firstName.isEmpty || self.currentUser.lastName.isEmpty ||
            self.currentUser.street.isEmpty || self.currentUser.housenumber.isEmpty ||
            self.currentUser.zipcode.isEmpty || self.currentUser.radius == 0 {
            // prompt the registration screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "registrationvc") as RegistrationViewController
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            vc.accountInfoMissing = true
            vc.user = currentUser
            self.present(vc, animated: true, completion: nil)
        }
    }

    fileprivate func displaySignOutAlert(_ msg: String) {
        let alert = UIAlertController(
            title: "Internal error", message: "Please contact support",
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Sign out", comment: ""),
                style: .default,
                handler: { action in
                    switch action.style {
                    case .default:
                        SettingsTableViewController.signOut()
                    default:
                        print(msg)
                    }
            })
        )
        self.present(alert, animated: true, completion: nil)
    }

}
