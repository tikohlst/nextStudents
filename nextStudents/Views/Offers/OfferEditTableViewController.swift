//
//  OfferEditTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import ImagePicker

class OfferEditTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // MARK: - Variables
    
    var pickerData = [String]()
    var currentOffer: Offer?
    var imageViews = [UIImageView]()
    var deletedImages = [String]()
    var addedImages = [UIImageView]()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var offerNeedControl: UISegmentedControl!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var timePickerView: UIPickerView!
    @IBOutlet weak var createBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var deleteOfferCell: UITableViewCell!
    @IBOutlet weak var newOfferImageView: UIImageView!
    @IBOutlet weak var imageScrollView: UIScrollView!
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Must be set for func textFieldShouldReturn()
        titleTextField.delegate = self
        descriptionTextField.delegate = self
        
        if currentOffer != nil {
            titleTextField.text = currentOffer!.title
            createBarButtonItem.title = "Speichern"
            navigationItem.title = currentOffer!.title
            offerNeedControl.selectedSegmentIndex = currentOffer!.type == "Biete" ? 0 : 1
            descriptionTextField.text = currentOffer!.description
            timePickerView.selectRow(pickerData.firstIndex(of: currentOffer!.duration)!, inComponent: 0, animated: true)
            deleteOfferCell.isHidden = false
            
            MainController.storage
                .reference()
                .child("offers/\(currentOffer!.uid)")
                .listAll { (result, error) in
                    if let error = error {
                        print("Error while listing data: \(error.localizedDescription)")
                    } else {
                        for item in result.items {
                            item.getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                                if let error = error {
                                    print("Error while downloading image: \(error.localizedDescription)")
                                } else {
                                    let image = UIImage(data: data!)
                                    let newView = UIImageView(image: image)
                                    newView.accessibilityIdentifier = item.name
                                    
                                    newView.frame.size.width = self.newOfferImageView.frame.size.width
                                    newView.frame.size.height = self.newOfferImageView.frame.size.height
                                    
                                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(OfferEditTableViewController.imageTappedDelete(gesture:)))
                                    newView.addGestureRecognizer(tapGesture)
                                    newView.isUserInteractionEnabled = true
                                    
                                    self.imageViews.insert(newView, at: 0)
                                    self.imageScrollView.insertSubview(newView, at: 0)
                                    
                                    self.imageScrollView.contentSize.width = self.imageScrollView.frame.size.width
                                        + CGFloat(self.imageViews.count - 1)
                                        * self.newOfferImageView.frame.size.width
                                        + CGFloat(self.imageViews.count - 1) * 5.0
                                    
                                    self.layoutImages(animated: false)
                                }
                            }
                        }
                    }
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerData = ["5", "10", "15", "30", "60"]
        timePickerView.delegate = self
        timePickerView.dataSource = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(OfferEditTableViewController.imageTapped(gesture:)))
        // add it to the image view
        newOfferImageView.addGestureRecognizer(tapGesture)
        // make sure imageView can be interacted with by user
        newOfferImageView.isUserInteractionEnabled = true
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
        return 6
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    @IBAction func touchCancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "backToOffers", sender: nil)
    }
    
    @IBAction func touchDelete(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Wollen Sie das Angebot wirklich löschen?",
            message: nil,
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: "Ja",
            style: .default,
            handler: { (UIAlertAction) in
                MainController.database
                    .collection("offers")
                    .document(MainController.currentUser.uid)
                    .collection("offer")
                    .document(self.currentOffer!.uid)
                    .delete()
                MainController.storage
                    .reference(withPath: "offers/\(self.currentOffer!.uid)")
                    .delete()
                // Remove Offer object from array
                if let existingOffer = OffersTableViewController.offersArray.firstIndex(where: { $0.uid == self.currentOffer!.uid }) {
                    OffersTableViewController.offersArray.remove(at: existingOffer)
                }
                self.performSegue(withIdentifier: "backToOffers", sender: nil)
        }))
        
        alert.addAction(UIAlertAction(
            title: "Nein",
            style: .default,
            handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    // MARK: - Methods
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            let pickerController = ImagePickerController()
            pickerController.delegate = self
            present(pickerController, animated: true, completion: nil)
        }
    }
    
    @objc func imageTappedDelete(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if let gestureView = gesture.view as? UIImageView {
            if let index = imageViews.firstIndex(of: gestureView) {
                let deletedView = imageViews.remove(at: index)
                deletedView.removeFromSuperview()
                layoutImages(animated: true)
                if let identifier = deletedView.accessibilityIdentifier {
                    deletedImages.append(identifier)
                }
            }
            if let index = addedImages.firstIndex(of: gestureView) {
                addedImages.remove(at: index)
            }
        }
    }
    
    private func layoutImages(animated: Bool) {
        var latestView = newOfferImageView
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
    
    @IBAction func touchCreate(_ sender: UIBarButtonItem) {
        
        if titleTextField.text != nil &&
            titleTextField.text != "" &&
            descriptionTextField.text != nil &&
            descriptionTextField.text != "" {
            // Show an animated waiting circle
            let indicatorView = self.activityIndicator(style: .medium,
                                                       center: self.view.center)
            self.view.addSubview(indicatorView)
            indicatorView.startAnimating()
            
            if currentOffer != nil {
                saveOffer()
            } else {
                createOffer()
            }
            self.performSegue(withIdentifier: "backToOffers", sender: nil)
        } else {
            let alert = Utility.displayAlert(withTitle: "Fehler", withMessage: "Titel und Beschreibung müssen ausgefüllt sein.", withSignOut: false)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func createOffer() {
        let newOfferId = UUID.init().uuidString
        MainController.database.collection("offers")
            .document(MainController.currentUser.uid)
            .collection("offer")
            .document(newOfferId)
            .setData([
                "date": Timestamp(),
                "title": titleTextField.text ?? "",
                "type": offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
                "description": descriptionTextField.text ?? "",
                "duration": pickerData[timePickerView.selectedRow(inComponent: 0)]
            ]) { err in
                if let err = err {
                    print("Error creating document: \(err.localizedDescription)")
                }
        }
        
        uploadImages(images: addedImages, for: newOfferId)
    }
    
    private func saveOffer() {
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
        
        if !deletedImages.isEmpty {
            for identifier in deletedImages {
                MainController.storage
                    .reference(withPath: "offers/\(currentOffer!.uid)/\(identifier)")
                    .delete { error in
                        if let error = error {
                            print ("Error deleting image: \(error.localizedDescription)")
                        } else {
                            self.uploadImages(images: self.addedImages, for: self.currentOffer!.uid)
                        }
                }
            }
        } else {
            self.uploadImages(images: self.addedImages, for: currentOffer!.uid)
        }
    }
    
    private func uploadImages(currentOfferUID: String) {
        if imageViews.count > 0 {
            for view in imageViews {
                let storageRef = MainController.storage
                    .reference(withPath: "offers/\(currentOfferUID)/\(UUID.init().uuidString).jpeg")
                if let image = view.image, let imageData = image.jpegData(compressionQuality: 0.75) {
                    let imageMetaData = StorageMetadata.init()
                    imageMetaData.contentType = "image/jpeg"
                    // Upload image
                    storageRef.putData(imageData, metadata: imageMetaData) { (storageMetadata, error) in
                        if let error = error {
                            print("Error while uploading data: \(error.localizedDescription)")
                        } else {
                            print("uplaod complete with metadata: \(storageMetadata?.description ?? "nil")")
                            
                            // Don't go back to the offers TableView until the new image has been completely uploaded
                            self.performSegue(withIdentifier: "backToOffers", sender: nil)
                        }
                    }
                }
            }
        } else {
            // Perform segue without having to wait for an image to be uploaded
            self.performSegue(withIdentifier: "backToOffers", sender: nil)
        }
    }
    
    private func uploadImages(images: [UIImageView], for offerID: String) {
        if images.count > 0 {
            for view in images {
                let storageRef = MainController.storage
                    .reference(withPath: "offers/\(offerID)/\(UUID.init().uuidString).jpeg")
                if let image = view.image, let imageData = image.jpegData(compressionQuality: 0.75) {
                    let imageMetaData = StorageMetadata.init()
                    imageMetaData.contentType = "image/jpeg"
                    // Upload image
                    storageRef.putData(imageData, metadata: imageMetaData) { (storageMetadata, error) in
                        if let error = error {
                            print("Error while uploading data: \(error.localizedDescription)")
                        } else {
                            print("uplaod complete with metadata: \(storageMetadata?.description ?? "nil")")
                            
                            // Don't go back to the offers TableView until the new image has been completely uploaded
                            self.performSegue(withIdentifier: "backToOffers", sender: nil)
                        }
                    }
                }
            }
        } else {
            // Don't go back to the offers TableView until the new image has been completely uploaded
            self.performSegue(withIdentifier: "backToOffers", sender: nil)
        }
    }
    
    private func activityIndicator(style: UIActivityIndicatorView.Style = .medium,
                                   frame: CGRect? = nil,
                                   center: CGPoint? = nil) -> UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(style: style)
        if let frame = frame {
            activityIndicatorView.frame = frame
        }
        if let center = center {
            activityIndicatorView.center = center
        }
        return activityIndicatorView
    }
    
    // This function is called when you click return key in the text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resign the first responder from textField to close the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
}

// MARK: - Extensions

extension OfferEditTableViewController: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {}
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        var latestView = newOfferImageView
        for image in images {
            let newView = UIImageView(image: image)
            newView.frame.size.width = newOfferImageView.frame.size.width
            newView.frame.size.height = newOfferImageView.frame.size.height
            imageScrollView.insertSubview(newView, at: 0)
            
            latestView = newView
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(OfferEditTableViewController.imageTappedDelete(gesture:)))
            latestView!.addGestureRecognizer(tapGesture)
            latestView!.isUserInteractionEnabled = true
            
            imageViews.insert(latestView!, at: 0)
            addedImages.append(latestView!)
        }
        imageScrollView.contentSize.width = imageScrollView.frame.size.width
            + CGFloat(imageViews.count - 1)
            * newOfferImageView.frame.size.width
            + CGFloat(imageViews.count - 1) * 5.0
        layoutImages(animated: true)
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
}
