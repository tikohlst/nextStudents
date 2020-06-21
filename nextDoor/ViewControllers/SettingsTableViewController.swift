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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var signOutCell: UITableViewCell!
    var db = Firestore.firestore()
    var currentUser : User!
    var storage: Storage!

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = (parent?.parent as! MainController).currentUser
        storage = Storage.storage()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        let user = db.collection("users")
//            .document("\(String(describing: Auth.auth().currentUser!.uid))")
//
//        user.getDocument{(document, error) in
//            if let document = document, document.exists {
//                let data = document.data()
//
//                self.currentUser.address = data?["address"] as? String
//                self.currentUser.firstName = data?["givenName"] as? String
//                self.currentUser.lastName = data?["name"] as? String
//                self.currentUser.radius = data?["radius"] as? String
//                self.currentUser.bio = data?["bio"] as? String
//
//                // get profile image if it exists
//                let storageRef = self.storage.reference(withPath: "profilePictures/\(String(describing: Auth.auth().currentUser!.uid))/profilePicture.jpg")
//
//                storageRef.getData(maxSize: 4 * 1024 * 1024) { data, error in
//                    if let error = error {
//                        print("Error while downloading profile image: \(error.localizedDescription)")
//                        self.imageView.image = nil
//                    } else {
//                        // Data for "profilePicture.jpg" is returned
//                        let image = UIImage(data: data!)
//                        self.currentUser.profileImage = image
//                        self.imageView.image = image
//                    }
//                }
//
//                if self.currentUser.firstName != nil && self.currentUser.lastName != nil {
//                    self.nameLabel.text = self.currentUser.firstName! + " " + self.currentUser.lastName!
//                }
//
//            } else {
//                print("Document doesn't exist.")
//            }
//        }
        nameLabel.text = currentUser.firstName + " " + currentUser.lastName
        self.imageView.image = currentUser.profileImage
        self.imageView.layer.cornerRadius = self.imageView.frame.width/2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == self.tableView.indexPath(for: signOutCell) {
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        }
        else {
            return 3
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
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
