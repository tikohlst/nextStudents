//
//  ProfileViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka
import ImageRow
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

class ProfileViewController: FormViewController {
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var countNeighborsInRange = [Float: Int]()
        countNeighborsInRange[100.0] = 0
        countNeighborsInRange[150.0] = 0
        countNeighborsInRange[200.0] = 0
        countNeighborsInRange[250.0] = 0
        countNeighborsInRange[300.0] = 0
        countNeighborsInRange[350.0] = 0
        countNeighborsInRange[400.0] = 0
        countNeighborsInRange[450.0] = 0
        countNeighborsInRange[500.0] = 0
        
        MainController.dataService.getRawNeighborData(completion: { documents in
            for currentNeighbor in documents {
                let differenceInMeter = Utility.getGPSDifference(currentNeighbor.data()["gpsCoordinates"] as! GeoPoint, MainController.dataService.currentUser.gpsCoordinates)
                
                // Don't show currentUser as its own neighbor
                if currentNeighbor.documentID != MainController.dataService.currentUser.uid {
                    // Count neighbors in the different ranges
                    if (differenceInMeter) < 500.0 {
                        countNeighborsInRange[500.0]! += 1
                        if (differenceInMeter) < 450.0 {
                            countNeighborsInRange[450.0]! += 1
                            if (differenceInMeter) < 400.0 {
                                countNeighborsInRange[400.0]! += 1
                                if (differenceInMeter) < 350.0 {
                                    countNeighborsInRange[350.0]! += 1
                                    if (differenceInMeter) < 300.0 {
                                        countNeighborsInRange[300.0]! += 1
                                        if (differenceInMeter) < 250.0 {
                                            countNeighborsInRange[250.0]! += 1
                                            if (differenceInMeter) < 200.0 {
                                                countNeighborsInRange[200.0]! += 1
                                                if (differenceInMeter) < 150.0 {
                                                    countNeighborsInRange[150.0]! += 1
                                                    if (differenceInMeter) < 100.0 {
                                                        countNeighborsInRange[100.0]! += 1
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            self.form.rowBy(tag: "numberOfNeighbors")?.title = "Bei diesem Radius gibt es \(countNeighborsInRange[Float(MainController.dataService.currentUser.radius)] ?? 0) Nachbarn in der Nähe."
            self.form.rowBy(tag: "numberOfNeighbors")?.reload()
        } )
        
        // Call the 'keyboardWillShow' function from eureka when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_ :)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        // Call the 'keyboardWillHide' function fro eureka when the view controller receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_ :)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        // Show validation error in each case in the row below the error
        LabelRow.defaultCellUpdate = { cell, row in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
        }
        
        NameRow.defaultCellUpdate = {cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        NameRow.defaultOnRowValidationChanged = { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section!.insert(labelRow, at: indexPath)
                }
            }
        }
        
        TextRow.defaultCellUpdate = {cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        TextRow.defaultOnRowValidationChanged = { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section!.insert(labelRow, at: indexPath)
                }
            }
        }
        
        IntRow.defaultCellUpdate = {cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        IntRow.defaultOnRowValidationChanged = { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section!.insert(labelRow, at: indexPath)
                }
            }
        }
        
        SliderRow.defaultCellUpdate = {cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        SliderRow.defaultOnRowValidationChanged = { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section!.insert(labelRow, at: indexPath)
                }
            }
        }
        
        form
            
            +++ Section()
            
            <<< ImageRow() {
                $0.tag = "profileImage"
                $0.title = "Profilbild"
                $0.placeholderImage = UIImage(named: "defaultProfilePicture")
                $0.value = MainController.dataService.currentUser.profileImage
                $0.sourceTypes = .PhotoLibrary
                $0.clearAction = .no
            }.cellUpdate { cell, row in
                cell.accessoryView?.layer.cornerRadius = 17
            }
            
            +++ Section()
            
            <<< NameRow() {
                $0.tag = "firstName"
                $0.title = "Vorname"
                $0.value = MainController.dataService.currentUser.firstName
                $0.add(rule: RuleRequired(msg: "Gib deinen Vornamen für dein Profil ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< NameRow() {
                $0.tag = "lastName"
                $0.title = "Nachname"
                $0.value = MainController.dataService.currentUser.lastName
                $0.add(rule: RuleRequired(msg: "Gib deinen Nachnamen für dein Profil ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section()
            
            <<< TextRow() {
                $0.tag = "street"
                $0.title = "Straße"
                $0.value = MainController.dataService.currentUser.street
                $0.add(rule: RuleRequired(msg: "Gib die Straße ein, in der du wohnst."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< TextRow() {
                $0.tag = "housenumber"
                $0.title = "Hausnummer"
                $0.value = MainController.dataService.currentUser.housenumber
                $0.add(rule: RuleRequired(msg: "Gib deine Hausnummer ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< IntRow() {
                $0.tag = "zipcode"
                $0.title = "Postleitzahl"
                $0.value = Int(MainController.dataService.currentUser.zipcode)
                $0.add(rule: RuleRequired(msg: "Gib deine Postleitzahl ein."))
                $0.add(rule: RuleGreaterOrEqualThan(min: 10000, msg: "Die Postleitzahl ist zu klein."))
                $0.add(rule: RuleSmallerOrEqualThan(max: 99999, msg: "Die Postleitzahl ist zu groß."))
                $0.validationOptions = .validatesOnChange
            }.cellSetup { cell, row in
                row.formatter = nil
            }.cellUpdate { cell, row in
                row.useFormatterOnDidBeginEditing = false
                row.useFormatterDuringInput = false
                row.formatter = nil
            }
            
            +++ Section() {
                $0.tag = "slider"
            }
            
            <<< SliderRow() {
                $0.tag = "radius"
                $0.title = "Radius"
                $0.steps = 8
                $0.value = Float(MainController.dataService.currentUser.radius)
            }.cellSetup { cell, row in
                cell.slider.minimumValue = 100
                cell.slider.maximumValue = 500
                cell.valueLabel.text = String(MainController.dataService.currentUser.radius)
            }.cellUpdate { cell, row in
                // Show radius as numeric number
                cell.valueLabel.text = String(Int(row.value!)) + "m"
                self.form.rowBy(tag: "numberOfNeighbors")?.title = "Bei diesem Radius gibt es \(countNeighborsInRange[row.value!] ?? 0) Nachbarn in der Nähe."
                self.form.sectionBy(tag: "slider")?.reload()
            }
            
            <<< LabelRow() {
                $0.tag = "numberOfNeighbors"
            }.cellSetup { cell, row in
                cell.contentView.backgroundColor = UIColor(named: "White-Gray6")
                cell.textLabel?.textColor = UIColor(named: "Black-White")
                cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
                cell.textLabel?.textAlignment = .right
            }.cellUpdate { cell, row in
                cell.contentView.backgroundColor = UIColor(named: "White-Gray6")
                cell.textLabel?.textColor = UIColor(named: "Black-White")
                cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
                cell.textLabel?.textAlignment = .right
            }
            
            +++ Section("Hochschule/Universität")
            
            <<< PickerRow<String>() {
                $0.tag = "school"
                $0.options = ["keine Angabe", "Hochschule RheinMain", "Uni Mainz", "Uni2"]
                $0.value = $0.options[$0.options.firstIndex(of: MainController.dataService.currentUser.school)!]
            }
            
            <<< TextRow() {
                $0.tag = "degreeProgram"
                $0.title = "Studiengang"
                $0.value = MainController.dataService.currentUser.degreeProgram
                $0.add(rule: RuleRequired(msg: "Gib deinen Studiengang ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section("Biografie")
            
            <<< TextAreaRow() {
                $0.tag = "bio"
                $0.placeholder = "Erzähle etwas über dich selbst..."
                $0.value = MainController.dataService.currentUser.bio
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }
            
            +++ Section("Fähigkeiten")
            
            <<< TextAreaRow() {
                $0.tag = "skills"
                $0.placeholder = "Deine Fähigkeiten..."
                $0.value = MainController.dataService.currentUser.skills
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }
            
            +++ Section()
            
            <<< ButtonRow() {
                $0.title = "Änderungen speichern"
            }.onCellSelection { cell, row in
                if row.section?.form?.validate().isEmpty ?? false {
                    do {
                        try self.saveProfile()
                    } catch UserError.mapDataError {
                        print("Error while mapping User!")
                        let alert = Utility.displayAlert(withMessage: nil, withSignOut: true)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.flashScrollIndicators()
    }
    
    // MARK: - Methods
    
    func saveProfile() throws {
        // Show an animated waiting circle
        let indicatorView = self.activityIndicator(style: .medium,
                                                   center: self.view.center)
        self.view.addSubview(indicatorView)
        self.view.bringSubviewToFront(indicatorView)
        indicatorView.startAnimating()
        
        let data = form.values(includeHidden: true)
        
        // Data validation
        guard let firstName = data["firstName"] as? String,
            let lastName = data["lastName"] as? String,
            let street = data["street"] as? String,
            let housenumber = data["housenumber"] as? String,
            let zipcode = data["zipcode"] as? Int,
            let radius = Optional(Int(data["radius"] as! Float)),
            let bio = data["bio"] as? String,
            let skills = data["skills"] as? String,
            let profileImage = data["profileImage"] as? UIImage,
            let school = data["school"] as? String,
            let degreeProgram = data["degreeProgram"] as? String
            else {
                throw UserError.mapDataError
        }
        
        let addressString = "\(street) \(housenumber), \(zipcode), Deutschland"
        
        Utility.getCoordinate(addressString: addressString,
                              completionHandler: { (coordinates, error) in
                                
                                let numberRange = (-90.0)...(90.0)
                                if numberRange.contains(coordinates.latitude) && numberRange.contains(coordinates.longitude) {
                                    let gpsCoordinates = GeoPoint(latitude: coordinates.latitude,
                                                                  longitude: coordinates.longitude)
                                    
                                    if let user = MainController.dataService.currentUser {
                                        user.firstName = firstName
                                        user.lastName = lastName
                                        user.street = street
                                        user.housenumber = housenumber
                                        user.zipcode = String(zipcode)
                                        user.radius = radius
                                        user.bio = bio
                                        user.skills = skills
                                        user.profileImage = profileImage
                                        user.gpsCoordinates = gpsCoordinates
                                        user.school = school
                                        user.degreeProgram = degreeProgram
                                        
                                        let dict: [String: Any] = [
                                            "firstName": user.firstName,
                                            "lastName": user.lastName,
                                            "street": user.street,
                                            "housenumber": user.housenumber,
                                            "zipcode": user.zipcode,
                                            "bio": user.bio,
                                            "skills": user.skills,
                                            "school": user.school,
                                            "degreeProgram": user.degreeProgram
                                        ]
                                        
                                        MainController.dataService.setUserData(from: dict, radius: Double(user.radius), gpsCoordinates: user.gpsCoordinates, completion: {})
                                        
                                        // This variable is set to true to update the neighbors shown in NeighborsTableView
                                        MainController.dataService.currentUserUpdated = true
                                        
                                        // Profile image upload
                                        MainController.dataService.setProfilePicture(image: profileImage, completion: {
                                            // Don't go back until the new image has been completely uploaded
                                            self.navigationController?.popViewController(animated: true)
                                            self.dismiss(animated: true, completion: nil)
                                        })
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
        let alert = UIAlertController(
            title: nil,
            message: "Möchten Sie Ihr Konto wirklich löschen? Zum Bestätigen müssen Sie Ihr Passwort eingeben",
            preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Ja", style: .default) { _ in
            if let textFields = alert.textFields {
                let password = textFields[0].text
                
                
                if let info = Auth.auth().currentUser?.providerData[0].providerID, info == "password", let password = password {
                    // user with email and password
                    let credential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser!.email!, password: password)
                    
                    Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (authResult, error) in
                        if let error = error {
                            print("Error reauthenticating the user: \(error.localizedDescription)")
                        } else {
                            self.deleteUser()
                        }
                    })
                }
            } else {
                // Google user
                let auth = GIDSignIn.sharedInstance()!.currentUser.authentication!
                Auth.auth().currentUser!.getIDToken { (token, error) in
                    if let error = error {
                        print("Error getting IdToken: \(error.localizedDescription)")
                    } else if let token = token {
                        let credential = GoogleAuthProvider.credential(withIDToken: token, accessToken: auth.accessToken)
                        Auth.auth().currentUser!.reauthenticate(with: credential, completion: { (authResult, error) in
                            if let error = error {
                                print("Error reauthenticating the user: \(error.localizedDescription)")
                            } else {
                                self.deleteUser()
                            }
                        })
                    }
                }
            }
        }
        if let info = Auth.auth().currentUser?.providerData[0].providerID, info == "password" {
            alert.addTextField(configurationHandler: {textField in
                textField.placeholder = "Passwort"
                textField.isSecureTextEntry = true
            })
        }
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteUser() {
        // Delete user from the firebase database
        MainController.dataService.deleteUser {
            // Delete user from the firebase authentication
            MainController.dataService.deleteUserAuth {
                // Account was deleted. Go to login screen
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(identifier: "loginNavigationVC")
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
}
