//
//  PasswordViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

class PasswordViewController: UIViewController {
    
    @IBOutlet weak var newPasswordText: UITextField!
    @IBOutlet weak var repeatPasswordText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    private var passwordsMatch: Bool{
        return newPasswordText.text == repeatPasswordText.text
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
    
    

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
    
}
