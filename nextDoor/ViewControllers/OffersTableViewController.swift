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

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var offerImageView: UIImageView!

}

class OffersTableViewController: UITableViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        // Change placeholder for search field
        navigationItem.searchController?.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Suche", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
        // Change the title of the Cancel button on the search bar
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "Abbrechen"

        // TODO: query all offers from users in range
        db.collection("offers")
            .getDocuments { (querySnapshot, error) in
            if error != nil {
                print("Error getting documents: \(error!.localizedDescription)")
            } else {
                for document in querySnapshot!.documents {
                    // TODO: extract offers from every user
                    self.db.collection("offers")
                        .document(document.documentID)
                        .collection("offer")
                        .addSnapshotListener() { (querySnapshot, error) in
                            guard let documents = querySnapshot?.documents else {
                                print("Error fetching documents: \(error!)")
                                return
                            }

                            for offer in documents {
                                let newOffer = Offer(from: offer.data(),
                                                      with: offer.documentID,
                                                      ownerUID: document.documentID)
                                self.offersArray.append(newOffer)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "offerCell", for: indexPath) as! OfferTableViewCell

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
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

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
            switch identifier {
                case showOfferDetailSegue:
                    if let vc = segue.destination as? OfferViewController {
                        let selectedIndex = self.tableView.indexPathForSelectedRow!
                        let selectedOffer = searchedOffers[selectedIndex.row]
                        vc.offer = selectedOffer
                    }
                case editOfferSegue:
                    if let vc = segue.destination as? OfferEditController {
                        let selectedIndex = self.tableView.indexPathForSelectedRow!
                        let selectedOffer = searchedOffers[selectedIndex.row]
                        vc.currentOffer = selectedOffer
                    }
                default:
                    break
            }
        }
    }
    
    // unwind segue
    @IBAction func goBack(segue: UIStoryboardSegue) {
    }

}
