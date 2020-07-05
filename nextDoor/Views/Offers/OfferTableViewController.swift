//
//  OfferTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

class OfferTableViewController: UITableViewController {

    // MARK: - Variables

    var offer: Offer!

    private let showChatFromOfferSegue = "showChatFromOffer"

    // MARK: - IBOutlets

    @IBOutlet weak var offerImageView: UIImageView!
    @IBOutlet weak var offerNameLabel: UILabel!
    @IBOutlet weak var offerCreatorLabel: UILabel!
    @IBOutlet weak var offerDescriptionTextView: UITextView!
    @IBOutlet weak var offerDurationLabel: UILabel!
    @IBOutlet weak var offerCreationDateLabel: UILabel!
    @IBOutlet weak var offerContactNeighborButton: UIButton!

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

}
