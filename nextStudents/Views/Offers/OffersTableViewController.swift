//
//  OffersTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class OfferTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var offerImageView: UIImageView!
    @IBOutlet weak var offerView: UIView!
    
    // MARK: - Methods
    
    // Inside UITableViewCell subclass
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // show profile image rounded
        offerImageView.layer.cornerRadius = offerImageView.frame.width/2
        
        offerView.layer.cornerRadius = 10
        offerView.layer.masksToBounds = false
        offerView.layer.shouldRasterize = true
        offerView.layer.rasterizationScale = UIScreen.main.scale
        
        offerView.layer.borderWidth = 0.5
        offerView.layer.borderColor = UIColor.init(displayP3Red: 211.0/255.0, green: 211.0/255.0, blue: 211.0/255.0, alpha: 1.0).cgColor
        
        offerView.layer.shadowOffset = CGSize(width: 3, height: 3)
        offerView.layer.shadowRadius  = 3
        offerView.layer.shadowOpacity = 0.2
        offerView.layer.shadowColor   = UIColor.black.cgColor
    }
}

class OffersTableViewController: SortableTableViewController {
    
    // MARK: - Variables
    
    private let showOfferDetailSegue = "showOfferDetails"
    private let editOfferSegue = "editOffer"
    
    static var offersArray: [Offer] = []
    var allOffers = [Offer]() {
        didSet {
            OffersTableViewController.offersArray = allOffers
        }
    }
    var searchedOffers: [Offer] = []
    override var sortingOption: SortOption? {
        didSet {
            if let sortingOption = sortingOption {
                if isSorting {
                    searchedOffers = super.sort(searchedOffers, by: sortingOption)
                } else {
                    OffersTableViewController.offersArray = super.sort(OffersTableViewController.offersArray, by: sortingOption)
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
        
        MainController.database.collection("users")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for currentNeighbor in querySnapshot!.documents {
                        let differenceInMeter = Utility.getGPSDifference(currentNeighbor.data()["gpsCoordinates"] as! GeoPoint, MainController.currentUser.gpsCoordinates)
                        // Only show neighbors in the defined range
                        if (differenceInMeter) < Double(MainController.currentUser.radius) {
                            // Create User object for every neighbor in the radius and write it into an array
                            MainController.listeners.append(MainController.database.collection("offers")
                                .document(currentNeighbor.documentID)
                                .collection("offer")
                                .addSnapshotListener() { (querySnapshot, error) in
                                    guard let documents = querySnapshot?.documents else {
                                        print("Error fetching documents: \(error!.localizedDescription)")
                                        return
                                    }
                                    
                                    // Remove all existing Offer objects from this user
                                    if let existingOffer = self.allOffers.firstIndex(where: { $0.ownerUID == currentNeighbor.documentID }) {
                                        self.allOffers.remove(at: existingOffer)
                                    }
                                    // Update the table
                                    self.tableView.reloadData()
                                    
                                    // Create Offer object and write it into an array
                                    for offer in documents {
                                        do {
                                            var newOffer = try Offer().mapData(uidOffer: offer.documentID,
                                                                               dataOffer: offer.data(),
                                                                               uidOwner: currentNeighbor.documentID,
                                                                               dataOwner: currentNeighbor.data())
                                            // Get image of the offer
                                            MainController.storage
                                                .reference().child("offers/\(offer.documentID)")
                                                .listAll { (result, error) in
                                                    if let error = error {
                                                        print("Error while listing data: \(error.localizedDescription)")
                                                    } else {
                                                        if result.items.count > 0 {
                                                            let item = result.items[0]
                                                            item.getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                                                                if let error = error {
                                                                    print("Error while downloading profile image: \(error.localizedDescription)")
                                                                    newOffer.offerImage = UIImage(named: "defaultOfferImage")!
                                                                } else {
                                                                    // Data for "profilePicture.jpg" is returned
                                                                    newOffer.offerImage = UIImage(data: data!)!
                                                                }
                                                                
                                                                // Remove old Offer object if exists
                                                                if let existingOffer = self.allOffers.firstIndex(where: { $0.uid == offer.documentID }) {
                                                                    self.allOffers.remove(at: existingOffer)
                                                                }
                                                                self.allOffers.append(newOffer)
                                                                // Update the table
                                                                self.tableView.reloadData()
                                                            }
                                                        } else {
                                                            // Remove old Offer object if exists
                                                            if let existingOffer = self.allOffers.firstIndex(where: { $0.uid == offer.documentID }) {
                                                                self.allOffers.remove(at: existingOffer)
                                                            }
                                                            
                                                            self.allOffers.append(newOffer)
                                                            // Update the table
                                                            self.tableView.reloadData()
                                                        }
                                                    }
                                            }
                                        } catch OfferError.mapDataError {
                                            print("Error while mapping Offer!")
                                            let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                                            self.present(alert, animated: true, completion: nil)
                                        } catch {
                                            print("Unexpected error: \(error.localizedDescription)")
                                            let alert = Utility.displayAlert(withMessage: nil, withSignOut: false)
                                            self.present(alert, animated: true, completion: nil)
                                        }
                                    }
                            })
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
        searchedOffers = OffersTableViewController.offersArray.filter { (offer: Offer) -> Bool in
            return offer.title.localizedCaseInsensitiveContains(searchText) ||
                offer.ownerFirstName.localizedCaseInsensitiveContains(searchText) ||
                offer.ownerLastName.localizedCaseInsensitiveContains(searchText) ||
                offer.description.localizedCaseInsensitiveContains(searchText)
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displayedOffers = isSorting ? searchedOffers : OffersTableViewController.offersArray
        if displayedOffers.count > 0 {
            let selectedOffer = displayedOffers[indexPath.row]
            if selectedOffer.ownerUID == MainController.currentUser.uid {
                // selected offer is owned by current user
                performSegue(withIdentifier: editOfferSegue, sender: nil)
            } else {
                performSegue(withIdentifier: showOfferDetailSegue, sender: nil)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSorting ? searchedOffers.count : OffersTableViewController.offersArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfferCell", for: indexPath) as! OfferTableViewCell
        let offersToDisplay = isSorting ? searchedOffers : OffersTableViewController.offersArray
        
        // show all existing offers
        if offersToDisplay.count > 0 {
            let currentOffer = offersToDisplay[indexPath.row]
            
            if currentOffer.ownerUID == MainController.currentUser.uid {
                cell.offerView.backgroundColor = #colorLiteral(red: 0.9844052196, green: 0.5142533779, blue: 0.005369255785, alpha: 1)
            } else {
                cell.offerView.backgroundColor = UIColor(named: "White-Grey")
            }
            
            // Write the title of the current offer in the cell
            cell.titleLabel.text = currentOffer.title
            
            // Write the type of the current offer in the cell
            cell.typeLabel.text = currentOffer.type
            
            // Write the name of the owner of the current offer in the cell
            cell.ownerLabel.text = currentOffer.ownerFirstName + " " +  currentOffer.ownerLastName
            
            // Write profil image in cell
            cell.offerImageView.image = currentOffer.offerImage
            // Set profile image rounded
            cell.imageView!.layer.cornerRadius = cell.imageView!.frame.height/2
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            let backItem = UIBarButtonItem()
            backItem.title = "Angebote"
            navigationItem.backBarButtonItem = backItem
            if let vc = containerController, vc.sortMenuVisible {
                vc.toggleSortMenu(from: self)
            }
            let displayedOffers = isSorting ? searchedOffers : OffersTableViewController.offersArray
            switch identifier {
            case showOfferDetailSegue:
                if let vc = segue.destination as? OfferTableViewController {
                    let selectedIndex = self.tableView.indexPathForSelectedRow!
                    let selectedOffer = displayedOffers[selectedIndex.row]
                    vc.offer = selectedOffer
                }
            case editOfferSegue:
                if let vc = segue.destination as? OfferEditTableViewController {
                    let selectedIndex = self.tableView.indexPathForSelectedRow!
                    let selectedOffer = displayedOffers[selectedIndex.row]
                    vc.currentOffer = selectedOffer
                }
            case "createNewOffer":
                if let vc = segue.destination as? OfferEditTableViewController {
                    vc.pickerDataShown = vc.pickerData[0]
                }
            case "showFilterOptions":
                if let vc = segue.destination as? OfferPopOverController, let ppc = vc.popoverPresentationController {
                    ppc.delegate = self
                    vc.delegate = self
                    vc.offers = isSorting ? searchedOffers : allOffers
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Helper methods
    
    @IBAction func touchSortButton(_ sender: UIBarButtonItem) {
        if let vc = containerController {
            vc.toggleSortMenu(from: self)
        }
    }
    
    // unwind segue
    @IBAction func goBack(segue: UIStoryboardSegue) {
    }
    
}

// MARK: - Extensions

extension OffersTableViewController: SortTableViewControllerDelegate {
    func forward(data: SortOption?) {
        sortingOption = data
    }
}

extension OffersTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension OffersTableViewController: OfferFilterControllerDelegate {
    func forward(data: [Offer]) {
        OffersTableViewController.offersArray = data
        tableView.reloadData()
    }
}
