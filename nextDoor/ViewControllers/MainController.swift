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

    // MARK: - Methods

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
                let data = querySnapshot!.data()
                self.currentUser = User(uid: querySnapshot!.documentID,
                                        firstName: data?["firstName"] as? String ?? "",
                                        lastName: data?["lastName"] as? String ?? "",
                                        street: data?["street"] as? String ?? "",
                                        housenumber: data?["housenumber"] as? String ?? "",
                                        zipcode: data?["zipcode"] as? String ?? "",
                                        radius: data?["radius"] as? Int ?? 0,
                                        bio: data?["bio"] as? String ?? "",
                                        skills: data?["skills"] as? String ?? ""
                )

                let storageRef = Storage.storage().reference(withPath: "profilePictures/\(self.currentUser.uid)/profilePicture.jpg")
                storageRef.getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                    if let error = error {
                        print("Error while downloading profile image: \(error.localizedDescription)")
                        self.currentUser.profileImage = UIImage(named: "defaultProfilePicture")!
                    } else {
                        self.currentUser.profileImage = UIImage(data: data!)!
                    }
                }
                // check if userdata is complete
                self.checkMissingUserData()
            }
        }
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

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

}
