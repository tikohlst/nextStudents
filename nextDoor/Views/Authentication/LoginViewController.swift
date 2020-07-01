//
//  LoginViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate, UITextFieldDelegate {

    // MARK: - Variables

    var handle: AuthStateDidChangeListenerHandle?
    var db = Firestore.firestore()
    var showRegistrationSegue = "showRegistrationSegue"

    // MARK: - IBOutlets

    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordView: UIView!

    // MARK: - UIViewController events

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self

        // Must be set for func textFieldShouldReturn()
        emailText.delegate = self
        passwordText.delegate = self

        // Shadow for email view
        emailView.layer.shadowColor = UIColor.black.cgColor
        emailView.layer.shadowRadius = 10
        emailView.layer.shadowOpacity = 0.1
        emailView.layer.shadowOffset.height = -3

        // Shadow for password view
        passwordView.layer.shadowColor = UIColor.black.cgColor
        passwordView.layer.shadowRadius = 10
        passwordView.layer.shadowOpacity = 0.1
        passwordView.layer.shadowOffset.height = -3
    }

    override func viewWillAppear(_ animated: Bool) {
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: true)

        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        // might need some optional value handling
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == showRegistrationSegue {
            let backItem = UIBarButtonItem()
            backItem.title = "Zurück"
            navigationItem.backBarButtonItem = backItem
        }
    }

    // MARK: - Methods

    @IBAction func googleSignInPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }

    // Sign in with Google account
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let auth = user.authentication else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        Auth.auth().signIn(with: credentials) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            self!.switchScreens(authResult, error, strongSelf)
        }
    }

    // Sign in with nextDoor account
    @IBAction func touchLogin(_ sender: UIButton) {
        if let email = emailText.text, let password = passwordText.text {
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                self!.switchScreens(authResult, error, strongSelf)
            }
        }
    }

    //
    func switchScreens(_ authResult: AuthDataResult?, _ error: Error?, _ strongSelf: LoginViewController) {
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
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainTabBarController = storyboard.instantiateViewController(identifier: "tabbarvc") as! UITabBarController
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(mainTabBarController)

            // show the offers screen after login
            mainTabBarController.selectedIndex = 1
        }
    }

    // This function is called when you click return key in the text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resign the first responder from textField to close the keyboard.
        textField.resignFirstResponder()
        return true
    }

}
