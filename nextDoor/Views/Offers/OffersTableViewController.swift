//
//  OffersTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseAuth

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

        offerView.backgroundColor = UIColor.white
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

    var db = Firestore.firestore()
    let currentUserUID = Auth.auth().currentUser?.uid

    private let showOfferDetailSegue = "showOfferDetails"
    private let editOfferSegue = "editOffer"
    var offersArray: [Offer] = [] {
        didSet {
            searchedOffers = offersArray.map({$0})
        }
    }
    var searchedOffers: [Offer] = []
    override var sortingOption: SortOption? {
        didSet {
            if let sortingOption = sortingOption {
                if isFiltering {
                    searchedOffers = super.sort(searchedOffers, by: sortingOption)
                } else {
                    offersArray = super.sort(offersArray, by: sortingOption)
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

        // TODO: query all offers from users in range
        db.collection("offers")
            .addSnapshotListener() { (querySnapshot, error) in
            if error != nil {
                print("Error getting documents: \(error!.localizedDescription)")
            } else {
                for neighbor in querySnapshot!.documents {
                    // TODO: extract offers from every user
                    self.db.collection("offers")
                        .document(neighbor.documentID)
                        .collection("offer")
                        .addSnapshotListener() { (querySnapshot, error) in
                            guard let documents = querySnapshot?.documents else {
                                print("Error fetching documents: \(error!)")
                                return
                            }
                            // Create Offer object for every offer in the radius and write it into an array
                            for offer in documents {
                                // Skip already existing offers of this user
                                if self.offersArray.firstIndex(where: { $0.uid == offer.documentID }) == nil
                                {
                                    do {
                                        let newOffer = try Offer.mapData(querySnapshot: offer,
                                                                         ownerUID: neighbor.documentID)
                                        self.offersArray.append(newOffer)
                                    } catch OfferError.mapDataError {
                                        return self.displayAlert("Error while mapping Offer!")
                                    } catch {
                                        print("Unexpected error: \(error)")
                                        return
                                    }
                                }
                            }

                            // Update the table
                            self.tableView.reloadData()
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
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            searchedOffers = offersArray.filter({$0.title.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText)})
        } else {
            searchedOffers = offersArray.map({$0})
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchedOffers.count > 0 {
            let selectedOffer = searchedOffers[indexPath.row]
            if selectedOffer.ownerUID == currentUserUID {
                // selected offer is owned by current user
                performSegue(withIdentifier: editOfferSegue, sender: nil)
            } else {
                performSegue(withIdentifier: showOfferDetailSegue, sender: nil)
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedOffers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfferCell", for: indexPath) as! OfferTableViewCell

        // show all existing offers
        if searchedOffers.count > 0 {
            // TODO: only show offers that match range constraints set with radius
            let currentOffer = searchedOffers[indexPath.row]

            // Write the title of the current offer in the cell
            cell.titleLabel.text = currentOffer.title
            
            // Write the type of the current offer in the cell
            cell.typeLabel.text = currentOffer.type

            // owner must be saved with the offer
            // get the owner of the offer
            db.document("users/\(currentOffer.ownerUID)").getDocument { (document, error) in
                if error != nil {
                    print("error getting document: \(error!.localizedDescription)")
                } else {
                    if let ownerData = document?.data(), let ownerGivenName = ownerData["firstName"] as? String, let ownerName = ownerData["lastName"] as? String {
                        cell.ownerLabel.text = ownerGivenName + " " +  ownerName
                    }
                }
            }

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

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == showOfferDetailSegue {
            let selectedIndex = self.tableView.indexPathForSelectedRow!
            let selectedOffer = searchedOffers[selectedIndex.row]
            if selectedOffer.ownerUID == currentUserUID {
                return false
            }
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            let backItem = UIBarButtonItem()
            backItem.title = "Angebote"
            navigationItem.backBarButtonItem = backItem
            if let vc = containerController, vc.sortMenuVisible {
                vc.toggleSortMenu(from: self)
            }
            switch identifier {
                case showOfferDetailSegue:
                    if let vc = segue.destination as? OfferTableViewController {
                        let selectedIndex = self.tableView.indexPathForSelectedRow!
                        let selectedOffer = searchedOffers[selectedIndex.row]
                        vc.offer = selectedOffer
                    }
                case editOfferSegue:
                    if let vc = segue.destination as? OfferEditTableViewController {
                        let selectedIndex = self.tableView.indexPathForSelectedRow!
                        let selectedOffer = searchedOffers[selectedIndex.row]
                        vc.currentOffer = selectedOffer
                    }
                default:
                    break
            }
        }
    }

    // MARK: - Helper methods

    func getCoordinate( addressString : String, completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                        
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
                
            completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
        }
    }
    
    @IBAction func touchSortButton(_ sender: UIBarButtonItem) {
        if let vc = containerController {
            vc.toggleSortMenu(from: self)
        }
    }

    // unwind segue
    @IBAction func goBack(segue: UIStoryboardSegue) {
    }

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

extension OffersTableViewController: SortTableViewControllerDelegate {
    func forward(data: SortOption?) {
        sortingOption = data
    }
}
