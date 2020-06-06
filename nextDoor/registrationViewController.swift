//
//  registrationViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 06.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit
import Firebase

class registrationViewController: UIViewController {
    // MARK: - Variables
    @IBOutlet weak var givenNameText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var addressText: UITextField!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var radiusText: UITextField!
    @IBOutlet weak var newPasswordText: UITextField!
    @IBOutlet weak var repeatPasswordText: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailText: UITextField!
    private var passwordsMatch: Bool{
        return newPasswordText.text == repeatPasswordText.text
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))

            view.addGestureRecognizer(tap)
        }

        //Calls this function when the tap is recognized.
        @objc func dismissKeyboard() {
            //Causes the view (or one of its embedded text fields) to resign the first responder status.
            view.endEditing(true)
    }
    
    @IBAction func touchRegister(_ sender: Any) {
        if passwordsMatch {
            if isValidEmail(emailText.text!) {
                // TODO: require all textfields to be filled
                signUp()
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
        // TODO: do firebase signup process
        // TODO: after succsessful signup, segue to the main scene
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func signUp() {
        if let email = emailText.text, let password = newPasswordText.text {
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
                }
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
