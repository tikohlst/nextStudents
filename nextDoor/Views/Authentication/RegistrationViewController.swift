//
//  RegistrationViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka
import Firebase
import CoreLocation

class RegistrationViewController: FormViewController, CLLocationManagerDelegate {

    // MARK: - Variables

    var accountInfoMissing = false

    private var locationManager: CLLocationManager?
    var popUpShown = false

    // MARK: - Functions

    func startLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        locationManager?.delegate = self
    }

    func locationManager(_ locationManager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if popUpShown != true {
            MainController.lookUpCurrentLocation(locationManager: locationManager,
                                                 completionHandler: { (placemark) in

                                                    // Just show this pop up once
                                                    self.popUpShown = true

                                                    let street = (placemark?.thoroughfare)! as String
                                                    let housenumber = (placemark?.subThoroughfare)! as String
                                                    let zipcode = (placemark?.postalCode)! as String
                                                    let city = (placemark?.locality)! as String

                                                    let message = "Is this your actual address?\n\n"
                                                        + "\(street) \(housenumber)\n"
                                                        + "\(zipcode) \(city)"

                                                    let alert = UIAlertController(title: "Actual address",
                                                                                  message: message,
                                                                                  preferredStyle: .alert)

                                                    let deleteAction = UIAlertAction(title: "Yes", style: .default) { _ in
                                                        // Write address in textfields
                                                        self.form.rowBy(tag: "street")?.value = street
                                                        self.form.rowBy(tag: "street")?.reload()
                                                        self.form.rowBy(tag: "housenumber")?.value = housenumber
                                                        self.form.rowBy(tag: "housenumber")?.reload()
                                                        self.form.rowBy(tag: "zipcode")?.value = Int(zipcode)
                                                        self.form.rowBy(tag: "zipcode")?.reload()
                                                    }
                                                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

                                                    alert.addAction(deleteAction)
                                                    alert.addAction(cancelAction)

                                                    self.present(alert, animated: true, completion: nil)
            })
        }

    }

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

            +++ Section()

            <<< ButtonRow() {
                if accountInfoMissing {
                    $0.title = "Speichern"
                } else {
                    $0.title = "Registrieren"
                }
            }.onCellSelection {cell, row in
                if row.section?.form?.validate().isEmpty ?? false {
                    if self.accountInfoMissing {
                        self.updateAccount()
                    } else {
                        self.createAccount()
                    }
                }
            }

        if accountInfoMissing, let user = MainController.currentUser {
            form.rowBy(tag: "firstName")?.baseValue = user.firstName
            form.rowBy(tag: "lastName")?.baseValue = user.lastName
            form.rowBy(tag: "street")?.baseValue = user.street
            form.rowBy(tag: "housenumber")?.baseValue = user.housenumber
            form.rowBy(tag: "zipcode")?.baseValue = user.zipcode
        }
    }

    // MARK: - Methods

    func createAccount() {
        // Get values from the registration form
        let dict = form.values(includeHidden: true)
        let radius = 300.0

        Auth.auth().createUser(
            withEmail: (dict["email"] as! String),
            password: dict["password"] as! String) { authResult, error in
                // Error handling
                if error != nil {
                    let alert = UIAlertController(
                        title: nil, message: error!.localizedDescription,
                        preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("OK", comment: "Default Action"),
                            style: .default)
                    )
                    self.present(alert, animated: true, completion: nil)
                } else if authResult != nil {
                    // Write userdata to firestore
                    if let firstName = dict["firstName"] as? String,
                        let lastName = dict["lastName"] as? String,
                        let street = dict["street"] as? String,
                        let housenumber = dict["housenumber"] as? String,
                        let zipcode = dict["zipcode"] as? Int {

                        let addressString = "\(street) \(housenumber), \(zipcode), Deutschland"

                        MainController.getCoordinate(addressString: addressString,
                                                     completionHandler: { (coordinates, error) in

                                                        let gpsCoordinates = GeoPoint(latitude: coordinates.latitude,
                                                                                      longitude: coordinates.longitude)

                                                        MainController.database.collection("users")
                                                            .document(Auth.auth().currentUser!.uid)
                                                            .setData([
                                                                "firstName": firstName,
                                                                "lastName": lastName,
                                                                "street": street,
                                                                "housenumber": housenumber,
                                                                "zipcode": String(zipcode),
                                                                "radius": radius,
                                                                "gpsCoordinates": gpsCoordinates,
                                                                "bio": "",
                                                                "skills": ""
                                                            ]) { err in
                                                                if let err = err {
                                                                    print("Error adding document: \(err)")
                                                                }
                                                                else {
                                                                    self.presentLoginViewController()
                                                                }
                                                        }
                        })
                    } else {
                        print("Something went wrong.")
                    }
                }
        }
    }

    func updateAccount() {
        // Get values from the registration form
        let dict = form.values(includeHidden: true)
        let radius = 300.0

        // Write userdata to firestore
        if let firstName = dict["firstName"] as? String,
            let name = dict["lastName"] as? String,
            let street = dict["street"] as? String,
            let housenumber = dict["housenumber"] as? String,
            let zipcode = dict["zipcode"] as? String {

            let addressString = "\(street) \(housenumber), \(zipcode), Deutschland"

            MainController.getCoordinate(addressString: addressString,
                                         completionHandler: { (coordinates, error) in

                                            let gpsCoordinates = GeoPoint(latitude: coordinates.latitude,
                                                                          longitude: coordinates.longitude)

                                            MainController.database.collection("users")
                                                .document(MainController.currentUser.uid)
                                                .updateData([
                                                    "firstName": firstName,
                                                    "lastName": name,
                                                    "street": street,
                                                    "housenumber": housenumber,
                                                    "zipcode": zipcode,
                                                    "radius": radius,
                                                    "gpsCoordinates": gpsCoordinates
                                                ]) { err in
                                                    if let err = err {
                                                        print("Error adding document: \(err)")
                                                    } else {
                                                        self.presentTabBarViewController()
                                                    }
                                            }
            })
        } else {
            print("something went wrong.")
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
