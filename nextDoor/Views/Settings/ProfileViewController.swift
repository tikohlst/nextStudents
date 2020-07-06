//
//  ProfileViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka
import ImageRow
import Firebase
import CoreLocation

class ProfileViewController: FormViewController {

    // MARK: - UIViewController events

    override func viewDidLoad() {
        super.viewDidLoad()

        // call the 'keyboardWillShow' function from eureka when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_ :)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        // call the 'keyboardWillHide' function fro eureka when the view controller receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_ :)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)

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
                $0.value = MainController.currentUser.profileImage
                $0.sourceTypes = .PhotoLibrary
                $0.clearAction = .no
            }.cellUpdate { cell, row in
                cell.accessoryView?.layer.cornerRadius = 17
            }

            +++ Section()

            <<< TextRow() {
                $0.tag = "firstName"
                $0.title = "Vorname"
                $0.value = MainController.currentUser.firstName
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

            <<< TextRow() {
                $0.tag = "lastName"
                $0.title = "Nachname"
                $0.value = MainController.currentUser.lastName
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

            +++ Section()

            <<< TextRow() {
                $0.tag = "street"
                $0.title = "Straße"
                $0.value = MainController.currentUser.street
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

            <<< TextRow() {
                $0.tag = "housenumber"
                $0.title = "Hausnummer"
                $0.value = MainController.currentUser.housenumber
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

            <<< TextRow() {
                $0.tag = "zipcode"
                $0.title = "zipcode"
                $0.value = MainController.currentUser.zipcode
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

            +++ Section()

            <<< SliderRow() {
                $0.tag = "radius"
                $0.title = "Radius"
                $0.steps = 8
                $0.value = Float(MainController.currentUser.radius)
            }.cellSetup { cell, row in
                cell.slider.minimumValue = 100
                cell.slider.maximumValue = 500
                cell.valueLabel.text = String(MainController.currentUser.radius)
            }.cellUpdate { cell, row in
                // Show radius as numeric number
                cell.valueLabel.text = String(Int(row.value!)) + "m"
            }

            +++ Section("Biografie")

            <<< TextAreaRow() {
                $0.tag = "bio"
                $0.placeholder = "Erzähle etwas über dich selbst..."
                $0.value = MainController.currentUser.bio
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }

            +++ Section("Fähigkeiten")

            <<< TextAreaRow() {
                $0.tag = "skills"
                $0.placeholder = "Deine Fähigkeiten..."
                $0.value = MainController.currentUser.skills
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }

            +++ Section()

            <<< ButtonRow() {
                $0.title = "Änderungen speichern"
            }.onCellSelection { cell, row in
                if row.section?.form?.validate().isEmpty ?? false {
                    do {
                        try self.saveProfil()
                    } catch UserError.mapDataError {
                        let alert = MainController.displayAlert(withMessage: "Error while mapping User!", withSignOut: true)
                        self.present(alert, animated: true, completion: nil)
                    } catch {
                        print("Unexpected error: \(error)")
                    }
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

    // MARK: - Methods

    func saveProfil() throws {
        // Show an animated waiting circle
        let indicatorView = self.activityIndicator(style: .medium,
                                                   center: self.view.center)
        self.view.addSubview(indicatorView)
        indicatorView.startAnimating()

        let data = form.values(includeHidden: true)

        // Data validation
        guard let firstName = data["firstName"] as? String,
                let lastName = data["lastName"] as? String,
                let street = data["street"] as? String,
                let housenumber = data["housenumber"] as? String,
                let zipcode = data["zipcode"] as? String,
                let radius = Optional(Int(data["radius"] as! Float)),
                let bio = data["bio"] as? String,
                let skills = data["skills"] as? String,
                let profileImage = data["profileImage"] as? UIImage
        else {
            throw UserError.mapDataError
        }

        let addressString = street + " "
                            + housenumber + ", "
                            + zipcode + ", Deutschland"

        MainController.getCoordinate(addressString: addressString,
                                     completionHandler: { (coordinates, error) in

                                        let numberRange = (-90.0)...(90.0)
                                        if numberRange.contains(coordinates.latitude) && numberRange.contains(coordinates.longitude){
                                            let gpsCoordinates = GeoPoint(latitude: coordinates.latitude,
                                                                          longitude: coordinates.longitude)

                                            if let user = MainController.currentUser {
                                                user.firstName = firstName
                                                user.lastName = lastName
                                                user.street = street
                                                user.housenumber = housenumber
                                                user.zipcode = zipcode
                                                user.radius = radius
                                                user.bio = bio
                                                user.skills = skills
                                                user.profileImage = profileImage
                                                user.gpsCoordinates = gpsCoordinates

                                                MainController.database.collection("users")
                                                    .document(MainController.currentUser.uid)
                                                    .setData([
                                                        "firstName": user.firstName,
                                                        "lastName": user.lastName,
                                                        "street": user.street,
                                                        "housenumber": user.housenumber,
                                                        "zipcode": user.zipcode,
                                                        "radius": user.radius,
                                                        "bio": user.bio,
                                                        "skills": user.skills,
                                                        "gpsCoordinates": user.gpsCoordinates
                                                    ]) { err in
                                                        if let err = err {
                                                            print("Error editing document: \(err.localizedDescription)")
                                                        }
                                                }

                                                // This variable is set to true to update the neighbors shown in NeighborsTableView
                                                MainController.currentUserUpdated = true

                                                // profile image upload
                                                let storageRef = MainController.storage
                                                    .reference(withPath: "profilePictures/\(String(describing: MainController.currentUser.uid))/profilePicture.jpg")
                                                if let imageData = profileImage.jpegData(compressionQuality: 0.75) {
                                                    let imageMetadata = StorageMetadata.init()
                                                    imageMetadata.contentType = "image/jpeg"
                                                    storageRef.putData(imageData, metadata: imageMetadata) { (storageMetadata, error) in
                                                        if let error = error {
                                                            print("Error while uploading profile image: \(error.localizedDescription)")
                                                            return
                                                        }
                                                        print("upload complete with metadata: \(String(describing: storageMetadata))")
                                                        // Don't go back until the new image has been completely uploaded
                                                        self.navigationController?.popViewController(animated: true)
                                                        self.dismiss(animated: true, completion: nil)
                                                    }
                                                } else {
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
        })
    }

    private func activityIndicator(style: UIActivityIndicatorView.Style = .medium,
                                       frame: CGRect? = nil,
                                       center: CGPoint? = nil) -> UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(style: style)
        if let frame = frame {
            activityIndicatorView.frame = frame
        }
        if let center = center {
            activityIndicatorView.center = center
        }
        return activityIndicatorView
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
        // Delete user from the firebase database
        MainController.database.collection("users").document(MainController.currentUser.uid).delete { error in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
            } else {
                // Delete user from the firebase authentication
                MainController.currentUserAuth.delete { error in
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
