//
//  OfferTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class OfferTableViewController: UITableViewController {

    // MARK: - Variables
    @IBOutlet weak var offerImageView: UIImageView!
    @IBOutlet weak var offerNameLabel: UILabel!
    @IBOutlet weak var offerCreatorLabel: UILabel!
    @IBOutlet weak var offerDescriptionTextView: UITextView!
    @IBOutlet weak var offerDurationLabel: UILabel!
    @IBOutlet weak var offerCreationDateLabel: UILabel!
    @IBOutlet weak var offerContactNeighborButton: UIButton!

    var db = Firestore.firestore()
    var storage = Storage.storage()

    var offer: Offer!
    var neighborFirstName = ""
    var neighborLastName = ""
    var neighborImage: UIImage!

    private let showChatFromOfferSegue = "showChatFromOffer"

    // MARK: - Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Show kind of the offer: "Suche" or "Biete"
        navigationItem.title = offer.type

        // Show image of the offer
        offerImageView.image = offer.offerImage

        // Show title of the offer
        offerNameLabel.text = offer.title

        // Show the first and last name of the neighbor who created the offer
        db.document("users/\(offer.ownerUID)")
            .getDocument { (document, error) in
            if error != nil {
                print("error getting document: \(error!.localizedDescription)")
            } else {
                let ownerData = document?.data()
                self.neighborFirstName = ownerData!["firstName"] as! String
                self.neighborLastName = ownerData!["lastName"] as! String
                self.offerCreatorLabel.text = self.neighborFirstName + " " + self.neighborLastName
            }
        }

        // Get profile image of the neighbor
        self.storage
            .reference(withPath: "profilePictures/\(offer.ownerUID)/profilePicture.jpg")
            .getData(maxSize: 4 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error while downloading profile image: \(error.localizedDescription)")
                self.neighborImage = UIImage(named: "defaultProfilePicture")!
            } else {
                // Data for "profilePicture.jpg" is returned
                self.neighborImage = UIImage(data: data!)
            }
        }

        // Show the description of the offer
        offerDescriptionTextView.text = offer.description

        // Show duration of the offer
        offerDurationLabel.text = offer.duration + " Min."

        // Show creation date
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy hh:mm:ss"
        offerCreationDateLabel.text = df.string(from: offer.date)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showChatFromOfferSegue {
            // Get an instance of the ChatViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! ChatViewController

            // Set the title of the navigation item on the ChatViewController
            detailViewController.navigationItem.title = "\(neighborFirstName) \(neighborLastName)"

            // Set the user ID at the ChatViewController
            detailViewController.user2UID = offer!.ownerUID

            // Get first and last name of the chat partner and write it in the correct label
            detailViewController.user2Name = "\(neighborFirstName) \(neighborLastName)"

            // Get the user image
            detailViewController.user2Img = neighborImage
        }
    }

}
