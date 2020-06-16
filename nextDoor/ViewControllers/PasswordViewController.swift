//
//  PasswordViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

class PasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var newPasswordText: UITextField!
    @IBOutlet weak var repeatPasswordText: UITextField!
    @IBOutlet weak var saveButton: UIButton!

    private var passwordsMatch: Bool{
        return newPasswordText.text == repeatPasswordText.text
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // Must be set for func textFieldShouldReturn()
        newPasswordText.delegate = self
        repeatPasswordText.delegate = self
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func touchSave(_ sender: UIButton) {
        if passwordsMatch {
            //TODO: set new password
        } else {
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
    }

    // This function is called when you click return key in the text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resign the first responder from textField to close the keyboard.
        textField.resignFirstResponder()
        return true
    }

}
