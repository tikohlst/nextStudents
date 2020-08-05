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
    
    var offerOwnerProfileImage: UIImage!
    var offerOwnerFriendStatus: Bool!
    
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
        
        MainController.dataService.getFriendList(uid: MainController.dataService.currentUser!.uid, completion: { (userFriendList) in
            if let userFriendStatus = userFriendList[self.offer.ownerUID], userFriendStatus == 1 {
                self.offerOwnerFriendStatus = true
                // Show the first and last name of the neighbor who created the offer
                self.offerCreatorLabel.text = self.offer.ownerFirstName + " " + self.offer.ownerLastName
            } else {
                self.offerOwnerFriendStatus = false
                // Show the first name of the neighbor who created the offer
                self.offerCreatorLabel.text = self.offer.ownerFirstName
            }
        })
        
        // Show the description of the offer
        offerDescriptionTextView.text = offer.description
        
        // Show duration of the offer
        offerDurationLabel.text = offer.duration + " Min."
        
        // Show creation date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        offerCreationDateLabel.text = formatter.string(from: offer.date)
    }
    
    override func viewDidLoad() {
        MainController.dataService.getOfferPicturesReferences(for: offer.uid, completion: { references in
            var removedFirstImage = false
            for reference in references {
                MainController.dataService.getOfferPicture(from: reference, completion: { image in
                    let newView = UIImageView(image: image)
                    
                    newView.frame.size.width = self.firstOfferImageView.frame.size.width
                    newView.frame.size.height = self.firstOfferImageView.frame.size.height
                    newView.contentMode = .scaleAspectFit
                    
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
                        self.firstOfferImageView.frame.origin.y = self.imageScrollView.frame.origin.y + (self.imageScrollView.frame.size.height - self.firstOfferImageView.frame.size.height) / 2
                        }
                        removedFirstImage = !removedFirstImage
                    }
                    self.layoutImages(animated: false)
                })
            }
            self.imagesCell.isHidden = false
        })
        
        MainController.dataService.getProfilePicture(for: offer.ownerUID, completion: {image in
            self.offerOwnerProfileImage = image
        })
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
            
            // Set the label on the ChatViewController
            if offerOwnerFriendStatus {
                // Get first and last name of the chat partner and write it in the correct label
                detailViewController.chatPartnerName = self.offer.ownerFirstName + " " + self.offer.ownerLastName
            } else {
                // Get first name of the chat partner and write it in the correct label
                detailViewController.chatPartnerName = self.offer.ownerFirstName
            }
            
            // Get profile image of the neighbor
            detailViewController.chatPartnerProfileImage = offerOwnerProfileImage
        }
    }
    
    // MARK: - Methods
    
    private func layoutImages(animated: Bool) {
        var latestView = firstOfferImageView
        for view in imageViews {
            let newX = latestView!.frame.origin.x + latestView!.frame.size.width + 5.0
            let newY: CGFloat = imageScrollView.frame.origin.y + (imageScrollView.frame.size.height - view.frame.size.height) / 2
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
    
    @IBAction func showFullScreen(_ sender: UITapGestureRecognizer) {
        let iVC = FullScreenImageViewController()
        iVC.imageToShow = offer.offerImage
        
        let backItem = UIBarButtonItem()
        backItem.title = "Zurück"
        navigationItem.backBarButtonItem = backItem
        
        self.navigationController?.pushViewController(iVC, animated: true)
    }
}
