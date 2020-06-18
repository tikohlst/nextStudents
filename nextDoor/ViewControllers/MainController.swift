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

    var currentUser : User!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if currentUser != nil {
            checkMissingUserData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        let db = Firestore.firestore()
        db.collection("users").document(Auth.auth().currentUser!.uid).addSnapshotListener { (querySnapshot, error) in
            if error != nil {
                print("Error getting document: \(error!.localizedDescription)")
            } else {
                let data = querySnapshot!.data()
                print("\ntest\n")
                self.currentUser = User(uid: querySnapshot!.documentID, firstName: data?["givenName"] as? String ?? "", lastName: data?["name"] as? String ?? "", address: data?["address"] as? String ?? "", radius: data?["radius"] as? String ?? "", bio: data?["bio"] as? String ?? "")
                let storageRef = Storage.storage().reference(withPath: "profilePictures/\(self.currentUser.uid)/profilePicture.jpg")
                storageRef.getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                    if let error = error {
                        print("Error while downloading profile image: \(error.localizedDescription)")
                        self.currentUser.profileImage = UIImage(named: "defaultProfilePicture")
                    } else {
                        self.currentUser.profileImage = UIImage(data: data!)
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
        if self.currentUser.firstName.isEmpty || self.currentUser.lastName.isEmpty || self.currentUser.address.isEmpty ||
            self.currentUser.radius.isEmpty {
            // prompt the registration screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "registrationvc") as RegistrationViewController
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            vc.varHeaderLabel = "Account vervollständigen"
            vc.varRegisterButton = "Speichern"
            vc.hideMailAndPassword = true
            self.present(vc, animated: true, completion: nil)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
