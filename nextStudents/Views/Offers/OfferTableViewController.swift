//
//  OfferTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

class OfferTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var offer: Offer!
    var imageViews = [UIImageView]()
    
    private let showChatFromOfferSegue = "showChatFromOffer"
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var offerImageView: UIImageView!
    @IBOutlet weak var offerNameLabel: UILabel!
    @IBOutlet weak var offerCreatorLabel: UILabel!
    @IBOutlet weak var offerDescriptionTextView: UITextView!
    @IBOutlet weak var offerDurationLabel: UILabel!
    @IBOutlet weak var offerCreationDateLabel: UILabel!
    @IBOutlet weak var offerContactNeighborButton: UIButton!
    @IBOutlet weak var firstOfferImageView: UIImageView!
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imagesCell: UITableViewCell!
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show kind of the offer: "Suche" or "Biete"
        navigationItem.title = offer.type
        
        // Show image of the offer
        offerImageView.image = offer.offerImage
        
        // Show title of the offer
        offerNameLabel.text = offer.title
        
        // Show the first and last name of the neighbor who created the offer
        offerCreatorLabel.text = offer.ownerFirstName + " " + offer.ownerLastName
        
        // Show the description of the offer
        offerDescriptionTextView.text = offer.description
        
        // Show duration of the offer
        offerDurationLabel.text = offer.duration + " Min."
        
        // Show creation date
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy hh:mm:ss"
        offerCreationDateLabel.text = df.string(from: offer.date)
        
        let storageRef = MainController.storage.reference().child("offers/\(offer.uid)")
        storageRef.listAll { (result, error) in
            if let error = error {
                print("Error while listing data: \(error.localizedDescription)")
            } else {
                var removedFirstImage = false
                for item in result.items {
                    item.getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                        if let error = error {
                            print("Error while downloading image: \(error.localizedDescription)")
                        } else {
                            let image = UIImage(data: data!)
                            let newView = UIImageView(image: image)
                            
                            newView.frame.size.width = self.firstOfferImageView.frame.size.width
                            newView.frame.size.height = self.firstOfferImageView.frame.size.height
                            
                            self.imageViews.insert(newView, at: 0)
                            self.imageScrollView.insertSubview(newView, at: 0)
                            
                            self.imageScrollView.contentSize.width = self.imageScrollView.frame.size.width + CGFloat(self.imageViews.count - 1) * self.firstOfferImageView.frame.size.width + CGFloat(self.imageViews.count - 1) * 5.0
                            if !removedFirstImage {
                                let firstOrigin = self.firstOfferImageView.bounds.origin
                                self.firstOfferImageView.removeFromSuperview()
                                self.firstOfferImageView = newView
                                self.imageScrollView.insertSubview(self.firstOfferImageView, at: 0)
                                self.firstOfferImageView.bounds.origin = firstOrigin
                                if let index = self.imageViews.firstIndex(of: self.firstOfferImageView) {
                                    self.imageViews.remove(at: index)
                                }
                                removedFirstImage = !removedFirstImage
                            }
                            self.layoutImages(animated: false)
                        }
                    }
                }
                self.imagesCell.isHidden = false
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showChatFromOfferSegue {
            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController
            
            // Set the title of the navigation item on the ChatViewController
            detailViewController.navigationItem.title = offer.ownerFirstName + " " + offer.ownerLastName
            
            // Set the user ID at the ChatViewController
            detailViewController.chatPartnerUID = offer.ownerUID
            
            // Get first and last name of the chat partner and write it in the correct label
            detailViewController.chatPartnerName = offer.ownerFirstName + " " + offer.ownerLastName
            
            // Get profile image of the neighbor
            MainController.storage
                .reference(withPath: "profilePictures/\(offer.ownerUID)/profilePicture.jpg")
                .getData(maxSize: 4 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error while downloading profile image: \(error.localizedDescription)")
                        detailViewController.chatPartnerProfileImage = UIImage(named: "defaultProfilePicture")!
                    } else {
                        // Data for "profilePicture.jpg" is returned
                        detailViewController.chatPartnerProfileImage = UIImage(data: data!)
                    }
            }
        }
    }
    
    // MARK: - Methods
    private func layoutImages(animated: Bool) {
        var latestView = firstOfferImageView
        for view in imageViews {
            let newX = latestView!.frame.origin.x + latestView!.frame.size.width + 5.0
            let newY = latestView!.frame.origin.y
            if animated {
                UIView.animate(withDuration: 0.5) {
                    view.frame.origin = CGPoint(x: newX, y: newY)
                }
            } else {
                view.frame.origin = CGPoint(x: newX, y: newY)
            }
            latestView = view
        }
    }
    
}
