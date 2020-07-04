//
//  SettingsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

class SettingsTableViewController: UITableViewController {
    
    // MARK: - IBOutlets

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userBioLabel: UILabel!
    @IBOutlet weak var signOutTableViewCell: UITableViewCell!

    // MARK: - UIViewController events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let container = self.navigationController?.tabBarController?.parent as? ContainerViewController {
            if container.sortMenuVisible {
                container.toggleSortMenu(from: self)
            }
        }

        userNameLabel.text = MainController.currentUser.firstName + " " + MainController.currentUser.lastName
        self.userImageView.image = MainController.currentUser.profileImage

        // Show the profile image without whitespace
        if userImageView.frame.width > userImageView.frame.height {
            userImageView.contentMode = .scaleAspectFit
        } else {
            userImageView.contentMode = .scaleAspectFill
        }

        // Show profile image rounded
        self.userImageView.layer.cornerRadius = self.userImageView.frame.width/2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == self.tableView.indexPath(for: signOutTableViewCell) {
            SettingsTableViewController.signOut()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
            case 0: return 1
            case 1: return 2
            case 2: return 1
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
            try Auth.auth().signOut()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "loginNavigationVC") as UINavigationController
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewControllerTo(vc)
        } catch {
            print("Something went wrong signing out the user")
        }
    }

}
