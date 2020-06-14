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

class OfferTableViewCell: UITableViewCell{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var offerImageView: UIImageView!
}

class OffersTableViewController: UITableViewController {
    var db: Firestore!
    var offersArray: [Offer] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        db = Firestore.firestore()
        offersArray.removeAll(keepingCapacity: false)
        if let currentUserUID = Auth.auth().currentUser?.uid {
            
            // TODO: query all offers from users in range
            
            db.collection("offers").getDocuments { (querySnapshot, error) in
                if error != nil {
                    print("Error getting documents: \(error!.localizedDescription)")
                } else {
                    for document in querySnapshot!.documents {
                        // TODO: extract offers from every user
                        self.db.collection("offers").document(document.documentID).collection("offer").getDocuments() { (querySnapshot, error) in
                            if error != nil {
                                print("Error getting documents: \(error!.localizedDescription)")
                            } else {
                                for offer in querySnapshot!.documents {
                                    let offerData = Offer(from: offer.data(), with: offer.documentID, owner: document.documentID)
                                    self.offersArray.append(offerData)
                                }
                                // Update the table
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offersArray.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "offerCell", for: indexPath) as! OfferTableViewCell
        
        // show all existing offers
        if offersArray.count > 0 {
            // TODO: only show offers that match range constraints set with radius
            let currentOffer = offersArray[indexPath.row]
            
            cell.titleLabel.text = currentOffer.title
            cell.typeLabel.text = currentOffer.type
            // get the owner of the offer
            db.document("users/\(currentOffer.owner)").getDocument { (document, error) in
                if error != nil {
                    print("error getting document: \(error!.localizedDescription)")
                } else {
                    if let ownerData = document?.data(), let ownerGivenName = ownerData["givenName"] as? String, let ownerName = ownerData["name"] as? String {
                        cell.ownerLabel.text = ownerGivenName + " " +  ownerName
                    }
                    // Update the table
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        return cell
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
}
