//
//  MainController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase

class MainController: UITabBarController {
    
    // MARK: - Variables
    
    static let database = Firestore.firestore()
    static let storage = Storage.storage()
    static var currentUserAuth: Firebase.User!
    static var currentUser: User!
    static var currentUserUpdated = true
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if MainController.currentUser != nil {
            checkMissingUserData()
        }
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        MainController.currentUserAuth = Auth.auth().currentUser!
        
        MainController.database.collection("users")
            .document(MainController.currentUserAuth.uid)
            .addSnapshotListener { (querySnapshot, error) in
                if error != nil {
                    print("Error getting document: \(error!.localizedDescription)")
                } else {
                    do {
                        // get current user
                        MainController.currentUser = try User().mapData(uid: querySnapshot!.documentID, data: querySnapshot!.data()!)
                        
                        // get profile image if it exists
                        MainController.storage
                            .reference(withPath: "profilePictures/\(String(describing: MainController.currentUser.uid))/profilePicture.jpg")
                            .getData(maxSize: 4 * 1024 * 1024) { data, error in
                                if let error = error {
                                    print("Error while downloading profile image: \(error.localizedDescription)")
                                } else {
                                    // Data for "profilePicture.jpg" is returned
                                    MainController.currentUser.profileImage = UIImage(data: data!)!
                                }
                        }
                        
                        // check if userdata is complete
                        self.checkMissingUserData()
                        
                        // show the offers screen after login
                        self.selectedIndex = 1
                        
                    } catch UserError.mapDataError {
                        print("Error while mapping User!")
                        let alert = Utility.displayAlert(withMessage: nil, withSignOut: true)
                        self.present(alert, animated: true, completion: nil)
                    } catch {
                        print("Unexpected error: \(error)")
                    }
                }
        }
    }
    
    // MARK: - Helper methods
    
    func checkMissingUserData() {
        if MainController.currentUser.firstName.isEmpty || MainController.currentUser.lastName.isEmpty ||
            MainController.currentUser.street.isEmpty || MainController.currentUser.housenumber.isEmpty ||
            MainController.currentUser.zipcode.isEmpty || MainController.currentUser.radius == 0 {
            // prompt the registration screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(identifier: "registrationvc") as RegistrationViewController
            viewController.accountInfoMissing = true
            viewController.navigationItem.title = "Registrierung abschließen"
            
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .crossDissolve
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
}
