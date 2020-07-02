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

    // MARK: - IBOutlets

    @IBOutlet weak var neighborNameLabel: UILabel!
    @IBOutlet weak var neighborRangeLabel: UILabel!
    @IBOutlet weak var neighborImageView: UIImageView!
    @IBOutlet weak var neighborView: UIView!

    // MARK: - Methods

    // Inside UITableViewCell subclass
    override func layoutSubviews() {
        super.layoutSubviews()

        // Show the profile image without whitespace
        if neighborImageView.frame.width > neighborImageView.frame.height {
            neighborImageView.contentMode = .scaleAspectFit
        } else {
            neighborImageView.contentMode = .scaleAspectFill
        }

        // Show profile image rounded
        neighborImageView.layer.cornerRadius = neighborImageView.frame.width/2

        neighborView.backgroundColor = UIColor.white
        neighborView.layer.cornerRadius = 10
        neighborView.layer.masksToBounds = false
        neighborView.layer.shouldRasterize = true
        neighborView.layer.rasterizationScale = UIScreen.main.scale

        neighborView.layer.borderWidth = 0.5
        neighborView.layer.borderColor = UIColor.init(displayP3Red: 211.0/255.0, green: 211.0/255.0, blue: 211.0/255.0, alpha: 1.0).cgColor

        neighborView.layer.shadowOffset = CGSize(width: 3, height: 3)
        neighborView.layer.shadowRadius  = 3
        neighborView.layer.shadowOpacity = 0.2
        neighborView.layer.shadowColor   = UIColor.black.cgColor
    }

}

class NeighborsTableViewController: SortableTableViewController {

    // MARK: - Variables

    var db = Firestore.firestore()
    var storage = Storage.storage()

    let currentUserUID = Auth.auth().currentUser?.uid
    private let showNeighborDetailSegue = "showNeighborDetail"
    var usersInRangeArray: [User] = []
    var searchedUsers : [User] = []
    
    override var sortingOption: SortOption? {
        didSet {
            if let sortingOption = sortingOption {
                if isFiltering {
                    searchedUsers = super.sort(searchedUsers, by: sortingOption)
                } else {
                    usersInRangeArray = super.sort(usersInRangeArray, by: sortingOption)
                }
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - UIViewController events

    override func viewDidLoad() {
        super.viewDidLoad()

        // Don't view the lines between the cells
        tableView.separatorStyle = .none

        navigationItem.searchController = UISearchController(searchResultsController: nil)
        // Change placeholder for search field
        navigationItem.searchController?.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Suche", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
        // Change the title of the Cancel button on the search bar
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "Abbrechen"

        db.collection("users")
            .whereField("radius", isGreaterThan: 0)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for currentNeighbor in querySnapshot!.documents {
                        // Don't show currentUser as its own neighbor
                        if (self.currentUserUID != (currentNeighbor.documentID)) {
                            // Create User object for every neighbor in the radius and write it into an array
                            do {
                                let newUser = try User.mapData(querySnapshot: currentNeighbor)
                                // Get profile image of the neighbor
                                Storage.storage()
                                    .reference(withPath: "profilePictures/\(newUser.uid)/profilePicture.jpg")
                                    .getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                                        if let error = error {
                                            print("Error while downloading profile image: \(error.localizedDescription)")
                                            newUser.profileImage = UIImage(named: "defaultProfilePicture")!
                                        } else {
                                            // Data for "profilePicture.jpg" is returned
                                            newUser.profileImage = UIImage(data: data!)!
                                        }

                                        self.usersInRangeArray.append(newUser)

                                        // Sort the user by first name
                                        self.usersInRangeArray.sort(by: { (firstUser: User, secondUser: User) in
                                            firstUser.firstName < secondUser.firstName
                                        })

                                        // Update the table
                                        self.tableView.reloadData()
                                }
                            } catch UserError.mapDataError {
                                return self.displayAlert("Error: Wrong action handler!")
                            } catch {
                                print("Unexpected error: \(error)")
                                return
                            }
                        }
                    }
                }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
        if let container = self.navigationController?.tabBarController?.parent as? ContainerViewController {
            containerController = container
            containerController!.tabViewController = self
            containerController!.setupSortingCellsAndDelegate()
        }
    }

    override func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }

    func filterContentForSearchText(_ searchText: String) {
        searchedUsers = usersInRangeArray.filter { (user: User) -> Bool in
            return user.firstName.localizedCaseInsensitiveContains(searchText) ||
                user.lastName.localizedCaseInsensitiveContains(searchText)
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? searchedUsers.count : usersInRangeArray.count
    }

    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "NeighborCell", for: indexPath) as! NeighborTableViewCell
        let usersToDisplay = isFiltering ? searchedUsers : usersInRangeArray
        
        // Show all existing users
        if usersToDisplay.count > 0 {
            let currentUser = usersToDisplay[indexPath.row]

            // Write first name of the neighbor in the cell
            cell.neighborNameLabel.text = currentUser.firstName
            cell.neighborNameLabel.textColor = UIColor.init(displayP3Red: 100.0/255.0, green: 100.0/255.0, blue: 100.0/255.0, alpha: 1.0)

            // Write radius to actual user in cell
            cell.neighborRangeLabel.text = "\(currentUser.street) \(currentUser.housenumber)"

            // Write profil image in cell
            cell.neighborImageView.image = currentUser.profileImage
            // Set profile image rounded
            cell.imageView!.layer.cornerRadius = cell.imageView!.frame.height/2
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if let identifier = segue.identifier {
            switch identifier {
            case showNeighborDetailSegue:
                if let vc = containerController, vc.sortMenuVisible {
                    vc.toggleSortMenu(from: self)
                }
                // Show the selected User on the Detail view
                let indexPath = self.tableView.indexPathForSelectedRow!

                // Retrieve the selected user
                let displayedUsers = isFiltering ? searchedUsers : usersInRangeArray
                let currentUser = displayedUsers[indexPath.row]

                // Get an instance of the NeighborTableViewController with asking the segue for it's destination.
                let detailViewController = segue.destination as! NeighborTableViewController

                // Set the currentUser at the NeighborTableViewController.
                detailViewController.user = currentUser

                // Set the title of the navigation item on the NeighborTableViewController
                //detailViewController.navigationItem.title = "\(currentUser.firstName ), \(currentUser.radius )"
            default:
                break
            }
        }
    }

    @IBAction func touchSortButton(_ sender: UIBarButtonItem) {
        if let vc = containerController {
            vc.toggleSortMenu(from: self)
        }
    }

    // MARK: Helper methods

    fileprivate func displayAlert(_ msg: String) {
        let alert = UIAlertController(
            title: "Internal error", message: "Please contact support",
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Ok", comment: ""),
                style: .default,
                handler: { action in
                    switch action.style {
                    case .default:
                        SettingsTableViewController.signOut()
                    default:
                        print(msg)
                    }
            })
        )
        self.present(alert, animated: true, completion: nil)
    }

}

extension UITableViewController: UISearchResultsUpdating {
    var isFiltering: Bool {
        return (navigationItem.searchController?.isActive ?? false) && !isSearchbarEmpty
    }
    var isSearchbarEmpty: Bool {
        return navigationItem.searchController?.searchBar.text?.isEmpty ?? true
    }
    func setupSearch() {
        if let searchController = navigationItem.searchController {
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchResultsUpdater = self
        }
    }

    public func updateSearchResults(for searchController: UISearchController) {}

}

extension NeighborsTableViewController: SortTableViewControllerDelegate {
    func forward(data: SortOption?) {
        sortingOption = data
    }
}

enum SortOption: String {
    case firstName = "Vorname"
    case lastName = "Nachname"
    case distance = "Entfernung"
    case title = "Titel"
    case type = "Typ"
    case time = "Zeit"
    case duration = "Dauer"
    case date = "Datum"
}
