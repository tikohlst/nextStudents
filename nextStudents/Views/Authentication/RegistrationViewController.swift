//
//  RegistrationViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka
import Firebase
import CoreLocation

class RegistrationViewController: FormViewController, CLLocationManagerDelegate {
    
    // MARK: - Variables
    
    var accountInfoMissing = false
    
    private var locationManager = CLLocationManager()
    var popUpShown = false
    
    var userGpsCoordinates: GeoPoint?
    var formGpsCoordinates: GeoPoint?
    
    let defaultRadius = 300.0
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startLocationManager()
        
        // call the 'keyboardWillShow' function from eureka when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_ :)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        // call the 'keyboardWillHide' function from eureka when the view controller receive notification that a keyboard is going to be hidden
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_ :)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        // Show navigation bar
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Show validation error in each case in the row below the error
        LabelRow.defaultCellUpdate = { cell, row in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
        }
        
        EmailRow.defaultCellUpdate = {cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        EmailRow.defaultOnRowValidationChanged = { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.textLabel?.backgroundColor = .red
                        $0.cell.textLabel?.backgroundColor = UIColor.red
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section!.insert(labelRow, at: indexPath)
                }
            }
        }
        
        PasswordRow.defaultCellUpdate = {cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        PasswordRow.defaultOnRowValidationChanged = { cell, row in
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
        
        form
            
            +++ Section("Accountinfo") {
                $0.tag = "accountTag"
                $0.hidden = .function(["accountTag"], { section in
                    return self.accountInfoMissing
                })
            }
            
            <<< EmailRow() {
                $0.tag = "email"
                $0.title = "E-Mail Adresse"
                $0.add(rule: RuleRequired(msg: "Du musst deine E-Mail-Adresse eingeben."))
                $0.add(rule: RuleEmail(msg: "Du musst eine gültige E-Mail-Adresse eingeben."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< PasswordRow() {
                $0.tag = "password"
                $0.title = "Passwort"
                $0.add(rule: RuleRequired(msg: "Du musst ein Passwort eingeben."))
                $0.add(rule: RuleMinLength(minLength: UInt(8), msg:  "Dein Passwort muss mindestens 8 Zeichen enthalten."))
                $0.add(rule: RuleMaxLength(maxLength: 16, msg: "Dein Passwort darf maximal 16 Zeichen enthalten."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< PasswordRow() {
                $0.tag = "passwordCheck"
                $0.title = "Passwort bestätigen"
                $0.add(rule: RuleRequired(msg: "Du musst dein Passwort bestätigen."))
                $0.add(rule: RuleEqualsToRow(form: form, tag: "password", msg: "Die Passwörter stimmen nicht überein."))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section("Name")
            
            <<< NameRow() {
                $0.tag = "firstName"
                $0.title = "Vorname"
                $0.add(rule: RuleRequired(msg: "Gib deinen Vornamen für dein Profil ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< NameRow() {
                $0.tag = "lastName"
                $0.title = "Nachname"
                $0.add(rule: RuleRequired(msg: "Gib deinen Nachnamen für dein Profil ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section("Wohnort")
            
            <<< NameRow() {
                $0.tag = "street"
                $0.title = "Straße"
                $0.add(rule: RuleRequired(msg: "Gib die Straße ein, in der du wohnst."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< TextRow() {
                $0.tag = "housenumber"
                $0.title = "Hausnummer"
                $0.add(rule: RuleRequired(msg: "Gib deine Hausnummer ein."))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< IntRow() {
                $0.tag = "zipcode"
                $0.title = "Postleitzahl"
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
            
            +++ Section("Weitere Informationen")
            
            <<< PickerRow<String>("Hochschule/Universität") {
                $0.tag = "hs"
                $0.options = ["keine Angabe", "Hochschule RheinMain", "Uni Mainz", "Uni2"]
            }
            
            +++ Section("Studiengang")
            
            <<< TextRow() {
                $0.tag = "degreeProgram"
                $0.title = "Studiengang"
            }
            
            +++ Section()
            
            <<< ButtonRow() {
                if accountInfoMissing {
                    $0.title = "Speichern"
                } else {
                    $0.title = "Registrieren"
                }
            }.onCellSelection {cell, row in
                if row.section?.form?.validate().isEmpty ?? false {
                    self.callGPSValidation()
                }
        }
        
        if accountInfoMissing, let user = MainController.dataService.currentUser {
            form.rowBy(tag: "firstName")?.baseValue = user.firstName
            form.rowBy(tag: "lastName")?.baseValue = user.lastName
            form.rowBy(tag: "street")?.baseValue = user.street
            form.rowBy(tag: "housenumber")?.baseValue = user.housenumber
            form.rowBy(tag: "zipcode")?.baseValue = user.zipcode
        }
    }
    
    // MARK: - Methods for GPS
    
    func startLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    func locationManager(_ locationManager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let coordinates: CLLocationCoordinate2D = locationManager.location?.coordinate else { return }
        
        self.userGpsCoordinates = GeoPoint(latitude: coordinates.latitude,
                                           longitude: coordinates.longitude)
        
        if popUpShown != true {
            Utility.lookUpCurrentLocation(locationManager: locationManager,
                                          completionHandler: { (placemark) in
                                            
                                            // Just show this pop up once
                                            self.popUpShown = true
                                            
                                            let street = (placemark?.thoroughfare)! as String
                                            let housenumber = (placemark?.subThoroughfare)! as String
                                            let zipcode = (placemark?.postalCode)! as String
                                            let city = (placemark?.locality)! as String
                                            
                                            let message = "Ist dies deine aktuelle Adresse?\n\n"
                                                + "\(street) \(housenumber)\n"
                                                + "\(zipcode) \(city)"
                                            
                                            let alert = UIAlertController(title: "Aktuelle Adresse?",
                                                                          message: message,
                                                                          preferredStyle: .alert)
                                            
                                            let acceptAction = UIAlertAction(title: "Ja", style: .default) { _ in
                                                // Write address in textfields
                                                self.form.rowBy(tag: "street")?.value = street
                                                self.form.rowBy(tag: "street")?.reload()
                                                self.form.rowBy(tag: "housenumber")?.value = housenumber
                                                self.form.rowBy(tag: "housenumber")?.reload()
                                                self.form.rowBy(tag: "zipcode")?.value = Int(zipcode)
                                                self.form.rowBy(tag: "zipcode")?.reload()
                                            }
                                            let rejectAction = UIAlertAction(title: "Nein", style: .cancel, handler: nil)
                                            
                                            alert.addAction(acceptAction)
                                            alert.addAction(rejectAction)
                                            
                                            self.present(alert, animated: true, completion: nil)
            })
        }
        
    }
    
    // MARK: - Methods
    
    func callGPSValidation() {
        let dict = self.form.values(includeHidden: true)
        
        let street = dict["street"] as! String
        let housenumber = dict["housenumber"] as! String
        let zipcode = dict["zipcode"] as! Int
        
        let addressString = "\(street) \(housenumber), \(zipcode), Deutschland"
        
        Utility.getCoordinate(addressString: addressString,
                              completionHandler: { (coordinates, error) in
                                
                                self.formGpsCoordinates = GeoPoint(
                                    latitude: coordinates.latitude,
                                    longitude: coordinates.longitude)
                                
                                if self.checkAddress() {
                                    if self.accountInfoMissing {
                                        self.updateAccount()
                                    } else {
                                        self.createAccount()
                                    }
                                } else {
                                    let alert = Utility.displayAlert(withMessage: "Die eingegebene Adresse und die GPS-Daten stimmen nicht überein.", withSignOut: false)
                                    self.present(alert, animated: true, completion: nil)
                                }
        })
    }
    
    func checkAddress() -> Bool {
        // Compare the current GPS position of the mobile phone with the GPS data of the entered address for a difference of more than 50m
        let gpsDifferenceInMeter = Utility.getGPSDifference(self.userGpsCoordinates!, self.formGpsCoordinates!)
        
        if gpsDifferenceInMeter < 100 {
            return true
        } else {
            return false
        }
    }
    
    func createAccount() {
        // Get values from the registration form
        let dict = form.values(includeHidden: true)
        
        MainController.dataService.createUser(from: dict, completion: { success, error in
            if success {
                MainController.dataService.setUserData(from: dict,
                                                       radius: self.defaultRadius,
                                                       gpsCoordinates: self.formGpsCoordinates,
                                                       completion: {
                                                        let alert = Utility.displayAlert(
                                                            withTitle: "Registrierung erfolgreich",
                                                            withMessage: "Sie können sich mit Ihrer bei der Registrierung eingegebenen E-Mail-Adresse und dem Passwort anmelden.",
                                                            withSignOut: false,
                                                            withOwnAction: true)
                                                        alert.addAction(
                                                            UIAlertAction(
                                                                title: NSLocalizedString("Ok", comment: ""),
                                                                style: .default,
                                                                handler: { action in
                                                                    self.presentLoginViewController()
                                                            })
                                                        )
                                                        self.present(alert, animated: true, completion: nil)
                })
            } else if error?.localizedDescription == "The email address is already in use by another account." {
                let alert = Utility.displayAlert(withTitle: "Fehler", withMessage: "Für die eingegebene E-Mail-Adresse existiert bereits ein Account.", withSignOut: false)
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = Utility.displayAlert(withTitle: "Fehler", withMessage: "Die eingegebene Adresse und die aktuellen GPS-Daten stimmen nicht überein.", withSignOut: false)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func updateAccount() {
        // Get values from the registration form
        let dict = form.values(includeHidden: true)
        
        // Write userdata to firestore
        MainController.dataService.updateUserData(from: dict, radius: self.defaultRadius, gpsCoordinates: self.formGpsCoordinates) {
            self.presentTabBarViewController()
        }
    }
    
    func presentLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let startViewController = storyboard.instantiateViewController(identifier: "loginNavigationVC")
        
        startViewController.modalPresentationStyle = .fullScreen
        startViewController.modalTransitionStyle = .crossDissolve
        
        present(startViewController, animated: true, completion: nil)
    }
    
    func presentTabBarViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let containerController = storyboard.instantiateViewController(identifier: "containervc")
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(containerController)
    }
    
}
