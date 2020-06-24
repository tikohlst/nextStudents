//
//  ProfileViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka
import ImageRow
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

class ProfileViewController: FormViewController {

    // MARK: - Variables

    var db = Firestore.firestore()
    var storage = Storage.storage()
    var currentUser: User?

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        LabelRow.defaultCellUpdate = { cell, row in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
        }

        TextRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }

        form
            +++ Section()
                <<< ImageRow() {
                    $0.tag = "profileImage"
                    $0.title = "Profilbild"
                    $0.placeholderImage = UIImage(named: "defaultProfilePicture")
                    $0.value = self.currentUser?.profileImage
                    $0.sourceTypes = .PhotoLibrary
                    $0.clearAction = .no
                }.cellUpdate { cell, row in
                    cell.accessoryView?.layer.cornerRadius = 17
                }

            +++ Section()

                <<< TextRow() {
                    $0.tag = "firstName"
                    $0.title = "Vorname"
                    $0.value = self.currentUser?.firstName
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                }
                
                <<< TextRow() {
                    $0.tag = "lastName"
                    $0.title = "Nachname"
                    $0.value = self.currentUser?.lastName
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                }
            
            +++ Section()
            
                <<< TextRow() {
                    $0.tag = "street"
                    $0.title = "Straße"
                    $0.value = self.currentUser?.street
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                }

                <<< TextRow() {
                    $0.tag = "housenumber"
                    $0.title = "Hausnummer"
                    $0.value = self.currentUser?.housenumber ?? ""
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                }
                
                <<< TextRow() {
                    $0.tag = "zipcode"
                    $0.title = "zipcode"
                    $0.value = self.currentUser?.zipcode ?? ""
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                }

            +++ Section()

                <<< SliderRow() {
                    $0.tag = "radius"
                    $0.title = "Radius"
                    $0.steps = 8
                    $0.value = Float(self.currentUser!.radius)
                }.cellSetup { cell, row in
                    cell.slider.minimumValue = 100
                    cell.slider.maximumValue = 500
                    cell.valueLabel.text = String(self.currentUser!.radius)
                }.cellUpdate { cell, row in
                    // Show radius as numeric number
                    cell.valueLabel.text = String(Int(row.value!)) + "m"
                }
            
            +++ Section("Biografie")

                <<< TextAreaRow() {
                    $0.tag = "bio"
                    $0.placeholder = "Erzähle etwas über dich selbst..."
                    $0.value = self.currentUser?.bio
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                }
            
            +++ Section("Fähigkeiten")

                <<< TextAreaRow() {
                    $0.tag = "skills"
                    $0.placeholder = "Deine Fähigkeiten..."
                    $0.value = self.currentUser?.skills
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                }

            +++ Section()
                <<< ButtonRow() {
                    $0.title = "Änderungen speichern"
                }.onCellSelection { cell, row in
                    if row.section?.form?.validate().isEmpty ?? false {
                        self.saveProfil()
                        self.navigationController?.popViewController(animated: true)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
        
            +++ Section()
                <<< ButtonRow() {
                    $0.title = "Profil löschen"
                }.cellUpdate { cell, row in
                    cell.textLabel!.textColor = .red
                }.onCellSelection { cell, row in
                    if row.section?.form?.validate().isEmpty ?? false {
                        self.presentDeletionFailsafe()
                    }
                }
    }
    
    func saveProfil() {
        let dict = form.values(includeHidden: true)
        if let user = currentUser {
            user.firstName = dict["firstName"] as! String
            user.lastName = dict["lastName"] as! String
            user.street = dict["street"] as! String
            user.housenumber = dict["housenumber"] as! String
            user.zipcode = dict["zipcode"] as! String
            user.radius = Int(dict["radius"] as! Float)
            user.bio = dict["bio"] as! String
            user.skills = dict["skills"] as! String

            self.db.collection("users").document(currentUser!.uid).setData([
                "firstName" : user.firstName,
                "lastName" : user.lastName,
                "street" : user.street,
                "housenumber" : user.housenumber,
                "zipcode" : user.zipcode,
                "radius" : user.radius,
                "bio" : user.bio,
                "skills" : user.skills
            ]) { err in
                if let err = err {
                    print("Error editing document: \(err.localizedDescription)")
                }
            }
            // profile image upload
            let storageRef = storage.reference(withPath: "profilePictures/\(String(describing: currentUser!.uid))/profilePicture.jpg")
            let profileImage = (dict["profileImage"] as? UIImage)
            if let imageData = profileImage?.jpegData(compressionQuality: 0.75) {
                let imageMetadata = StorageMetadata.init()
                imageMetadata.contentType = "image/jpeg"
                storageRef.putData(imageData, metadata: imageMetadata) { (storageMetadata, error) in
                    if let error = error {
                        print("Error while uploading profile image: \(error.localizedDescription)")
                        return
                    }
                    print("upload complete with metadata: \(String(describing: storageMetadata))")
                }
            } else {
                if profileImage == nil {
                    storageRef.delete { error in
                        if let error = error {
                            print("Error while deleting profile image: \(error.localizedDescription)")
                        } else {
                            print("File deleted successfully")
                        }
                    }
                }
            }
        }
    }

    func presentDeletionFailsafe() {
        let alert = UIAlertController(title: nil, message: "Are you sure you'd like to delete your account?", preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    func deleteUser() {
        let user = Auth.auth().currentUser

        // Delete user from the firebase database
        db.collection("users").document(user!.uid).delete { error in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
            } else {
                // Delete user from the firebase authentication
                user!.delete { error in
                    if let error = error {
                        // An error happened.
                        print(error.localizedDescription)
                    } else {
                        // Account was deleted. Go to login screen
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(identifier: "loginNavigationVC") as LoginViewController
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            }
        }
    }

}
