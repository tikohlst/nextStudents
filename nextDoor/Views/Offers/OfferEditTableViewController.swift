//
//  OfferEditTableViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase

class OfferEditTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    // MARK: - Variables

    var pickerData = [String]()
    var currentOffer: Offer?

    // MARK: - IBOutlets

    @IBOutlet weak var offerNeedControl: UISegmentedControl!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var timePickerView: UIPickerView!
    @IBOutlet weak var createBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var deleteOfferCell: UITableViewCell!
    
    // MARK: - UIViewController events

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
            deleteOfferCell.isHidden = false
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
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    @IBAction func touchCancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "backToOffers", sender: nil)
    }
    
    @IBAction func touchDelete(_ sender: UIButton) {
        let alert = UIAlertController(title: "Wollen Sie das Angebot wirklich löschen?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (UIAlertAction) in
            MainController.database.collection("offers").document(MainController.currentUser.uid).collection("offer").document(self.currentOffer!.uid).delete()
            self.performSegue(withIdentifier: "backToOffers", sender: nil)
        }))
        alert.addAction(UIAlertAction(title: "Nein", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    

    // MARK: - Methods

    private func create() {
        MainController.database.collection("offers")
            .document(MainController.currentUser.uid)
            .collection("offer")
            .document(UUID.init().uuidString)
            .setData([
            "date": Timestamp.init(),
            "title": titleTextField.text ?? "",
            "type": offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
            "description": descriptionTextField.text ?? "",
            "duration": pickerData[timePickerView.selectedRow(inComponent: 0)]
        ]) { err in
            if let err = err {
                print("Error creating document: \(err.localizedDescription)")
            }
        }
    }
    
    private func save() {
        MainController.database.collection("offers")
            .document(MainController.currentUser.uid)
            .collection("offer")
            .document(currentOffer!.uid)
            .updateData([
            "title": titleTextField.text ?? "",
            "type": offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
            "description": descriptionTextField.text ?? "",
            "duration": pickerData[timePickerView.selectedRow(inComponent: 0)]
        ]) { err in
            if let err = err {
                print("Error editing document: \(err.localizedDescription)")
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

}
