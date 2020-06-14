//
//  LoginViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate {

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
    }

    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.checkMissingUserData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        // might need some optional value handling
        Auth.auth().removeStateDidChangeListener(handle!)
        self.checkMissingUserData()
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
                    self?.checkMissingUserData()
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
                                let givenName = user.data()["givenName"] as! String
                                let name = user.data()["name"] as! String
                                let address = user.data()["address"] as! String
                                let radius = user.data()["radius"] as! String

                                // If a user is logged in but user data is still missing (Example: Login via Google Account)
                                if (givenName.isEmpty ||
                                    name.isEmpty ||
                                    address.isEmpty ||
                                    radius.isEmpty) {
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
