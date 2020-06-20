//
//  NeighborsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class NeighborTableViewCell: UITableViewCell {

    @IBOutlet weak var neighborNameLabel: UILabel!
    @IBOutlet weak var neighborRangeLabel: UILabel!
    @IBOutlet weak var neighborImageView: UIImageView!

}

class NeighborsTableViewController: UITableViewController {

    var db = Firestore.firestore()
    var storage = Storage.storage()
    let currentUserUID = Auth.auth().currentUser?.uid

    private let showNeighborDetailSegue = "showNeighborDetail"
    var usersInRangeArray: [User] = [] {
        didSet {
            searchedUsers = usersInRangeArray.map({$0})
        }
    }
    var searchedUsers : [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)

        db.collection("users")
            .whereField("radius", isGreaterThan: "0")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // Don't show currentUser as its own neighbor
                        if (self.currentUserUID != (document.documentID)) {
                            // Create User object for every neighbor in the radius and write it into an array
                            let newUser = User(uid: document.documentID,
                                            firstName: document.data()["givenName"] as! String,
                                            lastName: document.data()["name"] as! String,
                                            address: document.data()["address"] as! String,
                                            radius: document.data()["radius"] as! String,
                                            bio: document.data()["bio"] as? String ?? "")

                            // Get profile image of the neighbor
                            let storageRef = self.storage.reference(withPath: "profilePictures/\(newUser.uid)/profilePicture.jpg")
                            storageRef.getData(maxSize: 4 * 1024 * 1024) { data, error in
                                if let error = error {
                                    print("Error while downloading profile image: \(error.localizedDescription)")
                                    newUser.profileImage = UIImage(named: "defaultProfilePicture")
                                } else {
                                    // Data for "profilePicture.jpg" is returned
                                    newUser.profileImage = UIImage(data: data!)
                                }

                                self.usersInRangeArray.append(newUser)

                                // Sort the user by first name
                                self.usersInRangeArray.sort(by: { (firstUser: User, secondUser: User) in
                                    firstUser.firstName < secondUser.firstName
                                })
                                // Update the table
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            searchedUsers = usersInRangeArray.filter({$0.firstName.localizedCaseInsensitiveContains(searchText) || $0.lastName.localizedCaseInsensitiveContains(searchText)})
        } else {
            searchedUsers = usersInRangeArray.map({$0})
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedUsers.count
    }

    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "NeighborCell", for: indexPath) as! NeighborTableViewCell

        // Show all existing users
        if searchedUsers.count > 0 {
            let currentUser = searchedUsers[indexPath.row]

            // Write first name of the neighbor in the cell
            cell.textLabel?.text = currentUser.firstName

            // Write radius to actual user in cell
            cell.detailTextLabel?.text = currentUser.radius

            // Write profil image in cell
            cell.imageView?.image = currentUser.profileImage
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == showNeighborDetailSegue {
            // Show the selected User on the Detail view
            let indexPath = self.tableView.indexPathForSelectedRow!

            // Retrieve the selected user
            let currentUser = searchedUsers[indexPath.row]

            // Get an instance of the NeighborTableViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! NeighborTableViewController

            // Set the currentUser at the NeighborTableViewController.
            detailViewController.user = currentUser

            // Set the title of the navigation item on the NeighborTableViewController
            //detailViewController.navigationItem.title = "\(currentUser.firstName ), \(currentUser.radius )"
        }
    }

}

extension UITableViewController: UISearchResultsUpdating {
    func setupSearch() {
        if let searchController = navigationItem.searchController {
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchResultsUpdater = self
        }
        
    }
    
    public func updateSearchResults(for searchController: UISearchController) {}
}
