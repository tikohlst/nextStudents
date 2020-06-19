//
//  RegistrationViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

class RegistrationViewController: UIViewController {

    // MARK: - Variables
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var givennameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!

    private var passwordsMatch: Bool {
        return newPasswordTextField.text == repeatPasswordTextField.text
    }

    var db: Firestore!
    var varHeaderLabel = "Registrierung"
    var varRegisterButton = "Registrieren"
    var hideMailAndPassword = false
    let radiusComponent = SliderTextComponent()

    override func viewWillAppear(_ animated: Bool) {
        headerLabel.text = varHeaderLabel
        registerButton.setTitle(varRegisterButton, for: [])
        emailTextField.isHidden = hideMailAndPassword
        newPasswordTextField.isHidden = hideMailAndPassword
        repeatPasswordTextField.isHidden = hideMailAndPassword
    }

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radiusComponent.slider = radiusSlider
        radiusComponent.textField = radiusTextField
        
        db = Firestore.firestore()

        // Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))

            view.addGestureRecognizer(tap)
        }

        // Calls this function when the tap is recognized.
        @objc func dismissKeyboard() {
            // Causes the view (or one of its embedded text fields) to resign the first responder status.
            view.endEditing(true)
    }
    
    @IBAction func radiusChanged(_ sender: Any) {
        radiusComponent.radiusChanged(sender)
    }
    
    @IBAction func touchRegister(_ sender: Any) {
        if hideMailAndPassword == false {
            if passwordsMatch {
                if isValidEmail(emailTextField.text!) {
                    // TODO: require all textfields to be filled
                    signUp()
                    self.presentLoginViewController()
                } else {
                    // TODO: refactor this copy pasta
                    let alert = UIAlertController(
                        title: "Fehler", message: "Bitte geben Sie eine gültige E-Mail Adresse ein",
                        preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("OK", comment: "Default Action"),
                            style: .default)
                    )
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                // TODO: refactor this copy pasta
                let alert = UIAlertController(
                    title: "Fehler", message: "Passwörter stimmen nicht überein",
                    preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: NSLocalizedString("OK", comment: "Default Action"),
                        style: .default)
                )
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            signUp()
        }
    }
    
    @IBAction func presentLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let startViewController = storyboard.instantiateViewController(identifier: "loginVC")

        startViewController.modalPresentationStyle = .fullScreen
        startViewController.modalTransitionStyle = .crossDissolve

        present(startViewController, animated: true, completion: nil)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func signUp() {
        // If the registration is not via Google Account
        if hideMailAndPassword == false {
            if let email = emailTextField.text,
                let password = newPasswordTextField.text {
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    // error handling
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
                        // Write userdata to firestore
                    } else if authResult != nil {
                        if let givenName = self.givennameTextField.text,
                            let name = self.nameTextField.text,
                            let address = self.addressTextField.text,
                            let radius = self.radiusTextField.text,
                            let user = Auth.auth().currentUser {
                            self.db.collection("users")
                                .document(user.uid)
                                .setData([
                                    "uid" : user.uid,
                                    "givenName" : givenName,
                                    "name" : name,
                                    "address" : address,
                                    "radius" : radius
                                ]) { err in
                                    if let err = err {
                                        print("Error adding document: \(err)")
                                    } else {
                                        print("Document added with ID: \(user.uid)")
                                        self.dismiss(animated: true) {}
                                    }
                            }
                        } else {
                           print("something went wrong")
                        }
                    }
                }
            }
        }
        // If the registration is via Google Account and the missing user data must be set
        else {
            if let givenName = self.givennameTextField.text,
                let name = self.nameTextField.text,
                let address = self.addressTextField.text,
                let radius = self.radiusTextField.text,
                let user = Auth.auth().currentUser {
                self.db.collection("users")
                    .document(user.uid)
                    .setData([
                        "uid" : user.uid,
                        "givenName" : givenName,
                        "name" : name,
                        "address" : address,
                        "radius" : radius
                    ]) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            print("Document added with ID: \(user.uid)")
                            self.dismiss(animated: true) {}
                        }
                }
            } else {
                print("something went wrong")
            }
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
