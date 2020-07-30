//
//  MainController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class MainController: UITabBarController {
    
    // MARK: - Variables
    
    static let dataService = DataService()
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if MainController.dataService.currentUser != nil {
            checkMissingUserData()
        }
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        // This variable is set to true the first time the app is loaded, so
        // that all current users in the area are updated when you log in again
        MainController.dataService.currentUserUpdated = true
        
        MainController.dataService.currentUserAuth = Auth.auth().currentUser!
        
        MainController.dataService.addListenerForCurrentUser {data, docId in
            do {
                // get current user
                MainController.dataService.currentUser = try User().mapData(uid: docId, data: data)
                
                // get profile image if it exists
                MainController.dataService.getProfilePicture(for: MainController.dataService.currentUser.uid, completion: { image in
                    MainController.dataService.currentUser.profileImage = image
                })
                
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
    
    // MARK: - Helper methods
    
    func checkMissingUserData() {
        if MainController.dataService.currentUser.firstName.isEmpty || MainController.dataService.currentUser.lastName.isEmpty ||
            MainController.dataService.currentUser.street.isEmpty || MainController.dataService.currentUser.housenumber.isEmpty ||
            MainController.dataService.currentUser.zipcode.isEmpty || MainController.dataService.currentUser.radius == 0 {
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
