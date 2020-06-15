//
//  OffersViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class OfferViewController: UIViewController {
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var offerNavBarItem: UINavigationItem!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var offerImageView: UIImageView!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var offerDurationLabel: UILabel!
    @IBOutlet weak var offerTypeLabel: UILabel!
    var offer: Offer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        if let offer = offer {
            offerNavBarItem.title = offer.title
            descriptionTextView.text = offer.description
            offerDurationLabel.text = "Dauer des Angebots: " + offer.duration + " Min."
            offerTypeLabel.text = "Art des Angebots: " + offer.type
            
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yyyy hh:mm:ss"
            creationDateLabel.text = "Erstellt am " + df.string(from: offer.date)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "showChatFromOffer":
                    let detailViewController = segue.destination as! ChatViewController
                    
                    // Set the user ID at the ChatViewController
                    detailViewController.user2UID = offer!.owner
                    
                    var firstName = ""
                    var lastName = ""
                    let db = Firestore.firestore()
                    let user = db.collection("users").document(offer!.owner)
                    user.getDocument { (document, error) in
                        if error != nil {
                            print("Error getting documents: \(error!.localizedDescription)")
                        } else if let document = document, document.exists {
                            let data = document.data()
                            // Get first and last name of the chat partner
                            firstName = data?["givenName"] as! String
                            lastName = data?["name"] as! String
                            
                            // Get first and last name of the chat partner and write it in the correct label
                            detailViewController.user2Name = "\(firstName) \(lastName)"
                            
                            detailViewController.user2ImgUrl = "https://image.flaticon.com/icons/svg/21/21104.svg"
                            
                            // Set the title of the navigation item on the ChatViewController
                            detailViewController.navigationItem.title = "\(firstName) \(lastName)"
                        }
                }
                default:
                    break
            }
        }
    }
    
}
