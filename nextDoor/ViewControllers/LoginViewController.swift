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
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var handle: AuthStateDidChangeListenerHandle?
    var db = Firestore.firestore()

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self

        // Must be set for func textFieldShouldReturn()
        emailText.delegate = self
        passwordText.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            //self.checkMissingUserData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        // might need some optional value handling
        Auth.auth().removeStateDidChangeListener(handle!)
        //self.checkMissingUserData()
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
            }
        }
        self.checkMissingUserData()
    }

    @IBAction func googleSignInPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }

    @IBAction func touchLogin(_ sender: UIButton) {
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
                    //self?.checkMissingUserData()
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let mainTabBarController = storyboard.instantiateViewController(identifier: "tabbarvc")
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(mainTabBarController)
                }
            }
        }
    }

    func checkMissingUserData() {
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.db.collection("users")
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for user in querySnapshot!.documents {
                            if auth.currentUser?.uid == user.documentID {
                                let firstName = user.data()["firstName"] as! String
                                let lastName = user.data()["lastName"] as! String
                                let street = user.data()["street"] as! String
                                let housenumber = user.data()["housenumber"] as! String
                                let plz = user.data()["plz"] as! String
                                let radius = user.data()["radius"] as! Int

                                // If a user is logged in but user data is still missing (Example: Login via Google Account)
                                if (firstName.isEmpty ||
                                    lastName.isEmpty ||
                                    street.isEmpty ||
                                    housenumber.isEmpty ||
                                    plz.isEmpty ||
                                    radius == 0
                                    ) {
                                    // Show registration screen to enter the missing data
                                    let vc = storyboard.instantiateViewController(identifier: "registrationvc") as RegistrationViewController
                                    vc.modalPresentationStyle = .fullScreen
                                    vc.modalTransitionStyle = .crossDissolve
                                    vc.varHeaderLabel = "Account vervollständigen"
                                    vc.varRegisterButton = "Speichern"
                                    vc.hideMailAndPassword = true
                                    self.present(vc, animated: true, completion: nil)
                                } else {
                                    let vc = storyboard.instantiateViewController(identifier: "tabbarvc") as MainController
                                    vc.modalPresentationStyle = .fullScreen
                                    vc.modalTransitionStyle = .crossDissolve
                                    self.present(vc, animated: true, completion: nil)
                                }
                            }
                        }
                    }
            }
        })
    }

    // This function is called when you click return key in the text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resign the first responder from textField to close the keyboard.
        textField.resignFirstResponder()
        return true
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
