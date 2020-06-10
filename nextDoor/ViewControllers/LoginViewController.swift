//
//  LoginViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 05.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate {
    
    // MARK: - Variables
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var handle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        
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
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let auth = user.authentication else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        Auth.auth().signIn(with: credentials) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Login Successful.")
                //This is where you should add the functionality of successful login
                //i.e. dismissing this view or push the home view controller etc
            }
        }
    }
    
    @IBAction func googleSignInPressed(_ sender: Any) {
         GIDSignIn.sharedInstance().signIn()
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
                else {
                    self!.presentTabBarViewController()
                }
            }
        }
    }
    
    @IBAction func presentTabBarViewController() {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let tabBarViewController = storyboard.instantiateViewController(identifier: "tabbarvc")
//
//        tabBarViewController.modalPresentationStyle = .fullScreen
//        tabBarViewController.modalTransitionStyle = .crossDissolve
//
//        present(tabBarViewController, animated: true, completion: nil)
        //self.presentingViewController!.dismiss(animated: true) {}
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
