//
//  OfferEditController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 13.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class OfferEditController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var offerNeedControl: UISegmentedControl!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var timePickerView: UIPickerView!
    @IBOutlet weak var createBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    var pickerData = [String]()
    var db = Firestore.firestore()
    var currentOffer: Offer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Must be set for func textFieldShouldReturn()
        titleTextField.delegate = self
        descriptionTextField.delegate = self

        // if we edit an existing offer
        if currentOffer != nil {
            titleTextField.text = currentOffer!.title
            createBarButtonItem.title = "Speichern"
            navigationItem.title = currentOffer!.title
            offerNeedControl.selectedSegmentIndex = currentOffer!.type == "Biete" ? 0 : 1
            descriptionTextField.text = currentOffer!.description
            timePickerView.selectRow(pickerData.firstIndex(of: currentOffer!.duration)!, inComponent: 0, animated: true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerData = ["5", "10", "15", "30", "60"]
        timePickerView.delegate = self
        timePickerView.dataSource = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    @IBAction func touchCancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "backToOffers", sender: nil)
    }
    
    private func create() {
        if let user = Auth.auth().currentUser {
            self.db.collection("offers").document(user.uid).setData([:])
            self.db.collection("offers").document(user.uid).collection("offer").document(UUID.init().uuidString).setData([
                "date" : FieldValue.serverTimestamp(),
                "title" : titleTextField.text ?? "",
                "type" : offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
                "description" : descriptionTextField.text ?? "",
                "duration" : pickerData[timePickerView.selectedRow(inComponent: 0)]
            ]) { err in
                if let err = err {
                    print("Error creating document: \(err.localizedDescription)")
                }
            }
        }
    }
    
    private func save() {
        if let user = Auth.auth().currentUser {
            self.db.collection("offers").document(user.uid).collection("offer").document(currentOffer!.id).updateData([
                "title" : titleTextField.text ?? "",
                "type" : offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
                "description" : descriptionTextField.text ?? "",
                "duration" : pickerData[timePickerView.selectedRow(inComponent: 0)]
            ]) { err in
                if let err = err {
                    print("Error editing document: \(err.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func touchCreate(_ sender: UIBarButtonItem) {
        if currentOffer != nil {
            save()
        } else {
            create()
        }
        performSegue(withIdentifier: "backToOffers", sender: nil)
    }

    // This function is called when you click return key in the text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resign the first responder from textField to close the keyboard.
        textField.resignFirstResponder()
        return true
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
