//
//  SettingsTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import SafariServices

class SettingsTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var helpTableViewCell: UITableViewCell!
    @IBOutlet weak var signOutTableViewCell: UITableViewCell!
    @IBOutlet weak var changePasswordCell: UITableViewCell!
    
    var providerID: String?
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let container = self.navigationController?.tabBarController?.parent as? ContainerViewController {
            if container.sortMenuVisible {
                container.toggleSortMenu(from: self)
            }
        }
        
        userNameLabel.text = MainController.dataService.currentUser.firstName + " " + MainController.dataService.currentUser.lastName
        self.userImageView.image = MainController.dataService.currentUser.profileImage
        
        // Show the profile image without whitespace
        if userImageView.frame.width > userImageView.frame.height {
            userImageView.contentMode = .scaleAspectFit
        } else {
            userImageView.contentMode = .scaleAspectFill
        }
        
        // Show profile image rounded
        self.userImageView.layer.cornerRadius = self.userImageView.frame.width/2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let authUser = Auth.auth().currentUser {
            providerID = authUser.providerData[0].providerID
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case self.tableView.indexPath(for: helpTableViewCell):
            showReadme()
        case self.tableView.indexPath(for: signOutTableViewCell):
            SettingsTableViewController.signOut()
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1, indexPath.row == 0, providerID != nil, providerID != "password" {
            return super.tableView(tableView, cellForRowAt: IndexPath(row: indexPath.row + 1, section: indexPath.section))
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    func showReadme() {
        let url = URL(string: "https://github.com/tikohlst/nextStudents")!
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            if providerID != nil, providerID != "password" {
                return 1
            }
            return 2
        default: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let backItem = UIBarButtonItem()
        backItem.title = "Einstellungen"
        navigationItem.backBarButtonItem = backItem
    }
    
    // MARK: - Methods
    
    static func signOut() {
        do {
            // Remove all active listeners
            for listener in MainController.dataService.listeners {
                listener.remove()
            }
            for listener in ChatsTableViewController.threadListeners.values {
                listener.remove()
            }
            try Auth.auth().signOut()
            MainController.dataService.currentUserAuth = nil
            MainController.dataService.currentUser = nil
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "loginNavigationVC") as UINavigationController
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(vc)
        } catch {
            print("Something went wrong signing out the user")
        }
    }
    
}
