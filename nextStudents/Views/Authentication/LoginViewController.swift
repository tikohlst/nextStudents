//
//  LoginViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate, UITextFieldDelegate {
    
    // MARK: - Variables
    
    var handle: AuthStateDidChangeListenerHandle?
    var showRegistrationSegue = "showRegistrationSegue"
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var signInButton: UIButton!
    
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
        
        signInButton.setImage(UIImage(named: "Google Logo"), for: .normal)
        signInButton.imageEdgeInsets = UIEdgeInsets(
            top: 10,
            left: 10,
            bottom: 10,
            right: 20
        )
        signInButton.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: 10,
            bottom: 0,
            right: -10
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if let identifier = segue.identifier, identifier == showRegistrationSegue {
            let backItem = UIBarButtonItem()
            backItem.title = "Zurück"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    // MARK: - Methods
    
    @IBAction func forgotPassword(_ sender: Any) {
        if let email = emailText.text {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print("Error while resetting password: \(error)")
                    let alert = Utility.displayAlert(withTitle: "Zurücksetzen des Passworts fehlgeschlagen", withMessage: "Bitte überprüfe nochmal deine E-Mail-Adresse.", withSignOut: false)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = Utility.displayAlert(withTitle: "Passwort zurücksetzen", withMessage: "Es wurde ein Link zum Zurücksetzen Ihres Passworts an Ihre E-Mail-Adresse gesendet.", withSignOut: false)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
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
    
    // Sign in with nextStudents account
    @IBAction func touchLogin(_ sender: UIButton) {
        if let email = emailText.text, let password = passwordText.text {
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                
                if let error = error {
                    print("Error while login: \(error)")
                    let alert = Utility.displayAlert(withTitle: "Anmeldung fehlgeschlagen", withMessage: "Bitte überprüfe nochmal deine E-Mail-Adresse und dein Passwort.", withSignOut: false)
                    self!.present(alert, animated: true, completion: nil)
                } else {
                    self!.switchScreens(authResult, error, strongSelf)
                }
            }
        }
    }
    
    func switchScreens(_ authResult: AuthDataResult?, _ error: Error?, _ strongSelf: LoginViewController) {
        if error != nil {
            print("Error while switching screens!")
            let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
            strongSelf.present(alert, animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let containerController = storyboard.instantiateViewController(identifier: "containervc")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(containerController)
            
        }
    }
    
    // This function is called when you click return key in the text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resign the first responder from textField to close the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
}
