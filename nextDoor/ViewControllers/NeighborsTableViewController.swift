//
//  NeighborsTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class NeighborTableViewCell: UITableViewCell {
    @IBOutlet weak var neighborNameLabel: UILabel!
    @IBOutlet weak var neighborRangeLabel: UILabel!
    @IBOutlet weak var neighborImageView: UIImageView!
}

class NeighborsTableViewController: UITableViewController {

    var db = Firestore.firestore()
    var usersInRangeArray: [User] = []
    private let showNeighborDetailSegue = "showNeighborDetail"
    let currentUserUID = Auth.auth().currentUser?.uid

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        db.collection("users")
            .whereField("radius", isGreaterThan: "0")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // Don't show currentUser as its own neighbor
                        if (self.currentUserUID != (document.documentID)) {
                            // Create User object for every neighbor in the radius and write it into an array
                            let user = User(uid: document.documentID,
                                            firstName: document.data()["givenName"] as! String,
                                            lastName: document.data()["name"] as! String,
                                            address: document.data()["address"] as! String,
                                            radius: document.data()["radius"] as! String,
                                            bio: document.data()["bio"] as! String)
                            self.usersInRangeArray.append(user)

                            // Update the table
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usersInRangeArray.count
    }

    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "NeighborCell", for: indexPath) as! NeighborTableViewCell

        if usersInRangeArray.count > 0 {
            let currentUser = usersInRangeArray[indexPath.row]
            cell.neighborNameLabel?.text = currentUser.firstName
            cell.neighborRangeLabel?.text = currentUser.radius
            //cell.neighborImageView?.image = UIImage(named: fruit)
        }

        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == showNeighborDetailSegue {
            // Show the selected User on the Detail view
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }

            // Retrieve the selected User
            let selectedEntity = usersInRangeArray[indexPath.row]

            // Get an instance of the NeighborViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! NeighborViewController

            // Set the customer ID at the NeighborViewController.
            detailViewController.user = selectedEntity

            // Set the title of the navigation item on the NeighborViewController
            detailViewController.navigationItem.title = "\(usersInRangeArray[indexPath.row].firstName ), \(usersInRangeArray[indexPath.row].radius )"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showNeighborDetailSegue, sender: tableView.cellForRow(at: indexPath))
    }
}