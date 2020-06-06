//
//  LoginViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 05.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    // MARK: - Variables
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var handle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
          // ...
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // might need some optional value handling
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    private func signIn() {
        if let email = emailText.text, let password = passwordText.text {
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
              guard let strongSelf = self else { return }
                if error != nil {
                    let alert = UIAlertController(
                        title: nil, message: error!.localizedDescription,
                        preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("OK", comment: "Default Action"),
                            style: .default)
                    )
                    strongSelf.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func touchLogin(_ sender: UIButton) {
        signIn()
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
