//
//  NeighborTableViewController.swift
//  nextDoor
//
//  Created by Tim Kohlstadt on 03.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

struct NeighborsInRange {
    var name: String
    var radius: String
    //var image: UIImage

    init(name: String, radius: String) { //image: UIImage
        self.name = name
        self.radius = radius
        //self.image = image
    }
}

class NeighborTableViewCell: UITableViewCell {
    @IBOutlet weak var neighborNameLabel: UILabel!
    @IBOutlet weak var neighborRangeLabel: UILabel!
    @IBOutlet weak var neighborImageView: UIImageView!
}

class NeighborTableViewController: UITableViewController {

    var db: Firestore!
    var neighborsInRangeArray: [NeighborsInRange] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        db = Firestore.firestore()
        db.collection("users").whereField("radius", isEqualTo: "200")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // Create NeighborsInRange objects for every neighbor in the radius and write them in an array
                        let neighbor: NeighborsInRange = NeighborsInRange(name: document.data()["name"] as! String, radius: document.data()["radius"] as! String)
                        self.neighborsInRangeArray.append(neighbor)

                        // Update the table
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.neighborsInRangeArray.count
    }

    // The tableView(cellForRowAt:)-method is called to create UITableViewCell objects
    // for visible table cells.
    override func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // With dequeueReusableCell, cells are created according to the prototypes defined in the storyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "NeighborCell", for: indexPath) as! NeighborTableViewCell

        if neighborsInRangeArray.count > 0 {
            let actualNeighbor = neighborsInRangeArray[indexPath.row]
            cell.neighborNameLabel?.text = actualNeighbor.name
            cell.neighborRangeLabel?.text = actualNeighbor.radius
            //cell.neighborImageView?.image = UIImage(named: fruit)
        }

        return cell
    }
}
