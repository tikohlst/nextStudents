//
//  SettingsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseStorage

class SettingsTableViewController: UITableViewController {

    // MARK: - Variables

    var db = Firestore.firestore()
    var storage = Storage.storage()

    var currentUser : User!

    // MARK: - IBOutlets

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userBioLabel: UILabel!
    @IBOutlet weak var signOutTableViewCell: UITableViewCell!

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = (parent?.parent as! MainController).currentUser
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        db.collection("users")
            .document("\(String(describing: Auth.auth().currentUser!.uid))")
            .getDocument{(document, error) in
            if let document = document, document.exists {
                let data = document.data()

                self.currentUser.firstName = data?["firstName"] as! String
                self.currentUser.lastName = data?["lastName"] as! String

                // get profile image if it exists
                let storageRef = self.storage.reference(withPath: "profilePictures/\(String(describing: Auth.auth().currentUser!.uid))/profilePicture.jpg")

                storageRef.getData(maxSize: 4 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error while downloading profile image: \(error.localizedDescription)")
                        self.userImageView.image = nil
                    } else {
                        // Data for "profilePicture.jpg" is returned
                        let image = UIImage(data: data!)
                        self.currentUser.profileImage = image!
                        self.userImageView.image = image
                    }
                }

                self.userNameLabel.text = self.currentUser.firstName + " " + self.currentUser.lastName

            } else {
                print("Document doesn't exist.")
            }
        }

        userNameLabel.text = currentUser.firstName + " " + currentUser.lastName
        self.userImageView.image = currentUser.profileImage
        self.userImageView.layer.cornerRadius = self.userImageView.frame.width/2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == self.tableView.indexPath(for: signOutTableViewCell) {
            signOut()
        }
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "loginVC") as LoginViewController
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(vc)
            //self.present(vc, animated: true, completion: nil)
        } catch {
            print("Something went wrong signing out the user")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
            case 0: return 1
            case 1: return 2
            case 2: return 1
            default: return 1
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let backItem = UIBarButtonItem()
        backItem.title = "Einstellungen"
        navigationItem.backBarButtonItem = backItem

        if let identifier = segue.identifier {
            switch identifier {
            case "userProfileSegue":
                if let vc = segue.destination as? ProfileViewController {
                    vc.currentUser = currentUser
                }
            default:
                break
            }
        }
    }

}
