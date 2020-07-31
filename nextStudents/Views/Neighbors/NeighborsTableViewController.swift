//
//  NeighborsTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class NeighborTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var neighborNameLabel: UILabel!
    @IBOutlet weak var neighborRangeLabel: UILabel!
    @IBOutlet weak var neighborImageView: UIImageView!
    @IBOutlet weak var neighborView: UIView!
    @IBOutlet weak var friendshipStatusImageView: UIImageView!
    
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
    
    private let showNeighborDetailSegue = "showNeighborDetail"
    var searchedUsers = [User]()
    
    override var sortingOption: SortOption? {
        didSet {
            if let sortingOption = sortingOption {
                if isSorting {
                    searchedUsers = super.sort(searchedUsers, by: sortingOption)
                } else {
                    MainController.dataService.usersInRangeArray = super.sort(MainController.dataService.usersInRangeArray, by: sortingOption)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    var rawRequests = Dictionary<String, Int>()
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
        if let container = self.navigationController?.tabBarController?.parent as? ContainerViewController {
            containerController = container
            containerController!.tabViewController = self
            containerController!.setupSortingCellsAndDelegate()
        }
        
            MainController.dataService.getFriendList(uid: MainController.dataService.currentUser!.uid, completion: { (data) in
                self.rawRequests = data
            })
        
        if MainController.dataService.currentUserUpdated {
            MainController.dataService.currentUserUpdated = false
            MainController.dataService.allUsers = []
            // Update the table if there are no neighbors in range
            self.tableView.reloadData()
            MainController.dataService.getNeighbors {newUser in
                // Get profile image of the neighbor
                if let newUser = newUser {
                    MainController.dataService.getProfilePicture(for: newUser.uid, completion: { image in
                        newUser.profileImage = image
                        
                        MainController.dataService.allUsers.append(newUser)
                        
                        // Sort the user by first name
                        MainController.dataService.allUsers.sort(by: { (firstUser: User, secondUser: User) in
                            firstUser.firstName < secondUser.firstName
                        })
                        // Update the table
                        self.tableView.reloadData()
                    })
                } else {
                    let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        searchedUsers = MainController.dataService.usersInRangeArray.filter { (user: User) -> Bool in
            return user.firstName.localizedCaseInsensitiveContains(searchText) ||
                user.lastName.localizedCaseInsensitiveContains(searchText)
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSorting ? searchedUsers.count : MainController.dataService.usersInRangeArray.count
    }
    
    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "NeighborCell", for: indexPath) as! NeighborTableViewCell
        let usersToDisplay = isSorting ? searchedUsers : MainController.dataService.usersInRangeArray
        
        // Show all existing users
        if usersToDisplay.count > 0 {
            let currentUser = usersToDisplay[indexPath.row]
            
            // Write first name of the neighbor in the cell
            cell.neighborNameLabel.text = currentUser.firstName
            
            // Write radius to actual user in cell
            cell.neighborRangeLabel.text = "\(currentUser.street) \(currentUser.housenumber)"
            
            // Write profil image in cell
            cell.neighborImageView.image = currentUser.profileImage
            // Set profile image rounded
            cell.imageView!.layer.cornerRadius = cell.imageView!.frame.height/2
            
            if let status = rawRequests[currentUser.uid] {
                switch status {
                    case 0:
                        cell.friendshipStatusImageView.image = UIImage(systemName: "person.crop.circle.badge.exclam")
                    case 1:
                        cell.friendshipStatusImageView.image = UIImage(systemName: "person.crop.circle.badge.checkmark")
                    default:
                        break
                }
            } else {
                // no request nor friendship
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if let identifier = segue.identifier {
            let displayedUsers = isSorting ? searchedUsers : MainController.dataService.usersInRangeArray
            switch identifier {
            case showNeighborDetailSegue:
                if let vc = containerController, vc.sortMenuVisible {
                    vc.toggleSortMenu(from: self)
                }
                // Show the selected User on the Detail view
                let indexPath = self.tableView.indexPathForSelectedRow!
                
                // Retrieve the selected user
                let currentUser = displayedUsers[indexPath.row]
                
                // Get an instance of the NeighborTableViewController with asking the segue for it's destination.
                let detailViewController = segue.destination as! NeighborTableViewController
                
                // Set the currentUser at the NeighborTableViewController.
                detailViewController.user = currentUser
                
                detailViewController.userFriendList = rawRequests
            case "showFilterOptions":
                if let vc = segue.destination as? NeighborPopOverController, let ppc = vc.popoverPresentationController {
                    ppc.delegate = self
                    vc.delegate = self
                    vc.users = isSorting ? searchedUsers : MainController.dataService.allUsers
                }
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
    
    @IBAction func touchFilterButton(_ sender: UIBarButtonItem) {
        
    }
    
}

// MARK: - Extensions

extension UITableViewController: UISearchResultsUpdating {
    var isSorting: Bool {
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

extension NeighborsTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension NeighborsTableViewController: NeighborFilterControllerDelegate {
    func forward(data: [User]) {
        MainController.dataService.usersInRangeArray = data
        tableView.reloadData()
    }
}
