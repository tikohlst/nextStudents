//
//  ContainerViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ContainerViewController: UIViewController {
    
    // MARK: - Variables
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var sortingContainer: UIView!
    @IBOutlet weak var contentView: UIView!
    
    var sortViewController: SortTableViewController?
    var tabViewController: UITableViewController?
    var mainController: MainController?
    
    
    var sortMenuVisible = false
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomConstraint.constant = self.sortingContainer.frame.size.height
        
        // This variable is set to true the first time the app is loaded, so
        // that all current users in the area are updated when you log in again
        MainController.dataService.currentUserUpdated = true
        
        MainController.dataService.currentUserAuth = Auth.auth().currentUser!
        
        MainController.dataService.addListenerForCurrentUser {data, docId in
            do {
                // Get current user
                MainController.dataService.currentUser = try User().mapData(uid: docId, data: data)
                
                // Get profile image if it exists
                MainController.dataService.getProfilePicture(for: MainController.dataService.currentUser.uid, completion: { image in
                    MainController.dataService.currentUser.profileImage = image
                })
                
                // Check if userdata is complete
                self.checkMissingUserData()
                
            } catch UserError.mapDataError {
                print("Error while mapping User!")
                let alert = Utility.displayAlert(withMessage: nil, withSignOut: true)
                self.present(alert, animated: true, completion: nil)
            } catch {
                print("Unexpected error: \(error)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if MainController.dataService.currentUser != nil {
            checkMissingUserData()
        }
    }
    
    // MARK: - Helper methods
    
    func toggleSortMenu(from viewController: UIViewController) {
        if sortMenuVisible {
            // Hide sort menu
            UIView.animate(withDuration: 0.5, animations: {
                self.bottomConstraint.constant = self.sortingContainer.frame.size.height
                self.view.layoutIfNeeded()
            })
        } else {
            // Show sort menu
            self.view.bringSubviewToFront(sortingContainer)
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.bottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
        sortMenuVisible = !sortMenuVisible
    }
    
    func checkMissingUserData() {
        if MainController.dataService.currentUser.firstName.isEmpty || MainController.dataService.currentUser.lastName.isEmpty ||
            MainController.dataService.currentUser.street.isEmpty || MainController.dataService.currentUser.housenumber.isEmpty ||
            MainController.dataService.currentUser.zipcode.isEmpty || MainController.dataService.currentUser.radius == 0 {
            // Prompt the registration screen
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
    
    // TODO: refactor copy pasted code
    func setupSortingCellsAndDelegate() {
        if let sortController = sortViewController, let tabViewController = tabViewController {
            if tabViewController is NeighborsTableViewController {
                sortController.delegate = tabViewController as! NeighborsTableViewController
                let options = [SortOption.firstName, SortOption.lastName, SortOption.distance]
                if let indexPaths = sortController.tableView.indexPathsForRows(in: sortController.tableView.frame) {
                    for i in 0..<indexPaths.count {
                        if let cell = sortController.tableView.cellForRow(at: indexPaths[i]) {
                            cell.textLabel?.text = options[i].rawValue
                        }
                    }
                }
            } else if tabViewController is ChatsTableViewController {
                sortController.delegate = tabViewController as! ChatsTableViewController
                let cells = sortController.tableView.visibleCells
                let options = [SortOption.firstName, SortOption.lastName, SortOption.date]
                for i in 0..<cells.count {
                    cells[i].textLabel?.text = options[i].rawValue
                }
            } else if tabViewController is OffersTableViewController {
                sortController.delegate = tabViewController as! OffersTableViewController
                let cells = sortController.tableView.visibleCells
                let options = [SortOption.title, SortOption.date, SortOption.duration]
                for i in 0..<cells.count {
                    cells[i].textLabel?.text = options[i].rawValue
                }
            }
        }
    }
    
}
