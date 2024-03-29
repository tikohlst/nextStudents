//
//  OfferEditTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import ImagePicker

class OfferEditTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // MARK: - Variables
    
    var pickerData = [["5", "10", "15", "30", "60"],
                      ["1", "2", "3", "4", "5", "10", "15", "20", "24"],
                      ["Min.", "Std."]]
    var pickerDataShown = [String]()
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
            timePickerView.selectRow(pickerData[2].firstIndex(of: currentOffer!.timeFormat)!, inComponent: 1, animated: true)
            self.pickerView(self.timePickerView, didSelectRow: pickerData[2].firstIndex(of: currentOffer!.timeFormat)!, inComponent: 1)
            timePickerView.selectRow(pickerDataShown.firstIndex(of: currentOffer!.duration)!, inComponent: 0, animated: true)
            deleteOfferCell.isHidden = false
            
            MainController.dataService.getOfferPicturesReferences(for: currentOffer!.uid, completion: { references in
                for reference in references {
                    MainController.dataService.getOfferPicture(from: reference, completion: { image in
                        let newView = UIImageView(image: image)
                        newView.accessibilityIdentifier = reference.name
                        
                        newView.frame.size.width = 115
                        newView.frame.size.height = 106
                        newView.contentMode = .scaleAspectFit
                        
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
                    })
                }
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timePickerView.delegate = self
        timePickerView.dataSource = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(OfferEditTableViewController.imageTapped(gesture:)))
        // Add it to the image view
        newOfferImageView.addGestureRecognizer(tapGesture)
        // Make sure imageView can be interacted with by user
        newOfferImageView.isUserInteractionEnabled = true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return pickerDataShown.count
        } else {
            return pickerData[2].count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return pickerDataShown[row]
        } else {
            return pickerData[2][row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 1 {
            pickerDataShown = pickerData[pickerView.selectedRow(inComponent: component)]
            pickerView.reloadComponent(0)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "backToOffers":
                let vc = segue.destination as! OffersTableViewController
                if vc.allOffers.count > OffersTableViewController.offersArray.count {
                    vc.allOffers = OffersTableViewController.offersArray
                }
            default:
                break
            }
        }
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
                MainController.dataService.deleteOffer(for: self.currentOffer!.uid)
                // Remove Offer object from array
                if let existingOffer = OffersTableViewController.offersArray.firstIndex(where: { $0.uid == self.currentOffer!.uid }) {
                    OffersTableViewController.offersArray.remove(at: existingOffer)
                }
                self.performSegue(withIdentifier: "backToOffers", sender: nil)
        }))
        
        alert.addAction(UIAlertAction(
            title: "Abbrechen",
            style: .default,
            handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    // MARK: - Methods
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // If the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            let pickerController = ImagePickerController()
            pickerController.delegate = self
            present(pickerController, animated: true, completion: nil)
        }
    }
    
    @objc func imageTappedDelete(gesture: UIGestureRecognizer) {
        // If the tapped view is a UIImageView then set it to imageview
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
        let dict: [String: Any] = [
            "date": Timestamp(),
            "title": titleTextField.text!,
            "type": offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
            "description": descriptionTextField.text!,
            "duration": pickerDataShown[timePickerView.selectedRow(inComponent: 0)],
            "timeFormat" : pickerData[2][timePickerView.selectedRow(inComponent: 1)]
        ]
        
        MainController.dataService.createOffer(with: dict, completion: { newOfferId in
            if let newOfferId = newOfferId {
                self.uploadImages(images: self.addedImages, for: newOfferId)
            }
        })
    }
    
    private func saveOffer() {
        let dict: [String: Any] = [
            "title": titleTextField.text ?? "",
            "type": offerNeedControl.titleForSegment(at: offerNeedControl.selectedSegmentIndex)!,
            "description": descriptionTextField.text ?? "",
            "duration": pickerDataShown[timePickerView.selectedRow(inComponent: 0)],
            "timeFormat" : pickerData[2][timePickerView.selectedRow(inComponent: 1)]
        ]
        MainController.dataService.updateOffer(with: dict, offerID: currentOffer!.uid)
        
        if !deletedImages.isEmpty {
            for imageID in deletedImages {
                MainController.dataService.deleteOfferPicture(for: currentOffer!.uid, imageID: imageID)
            }
        }
        self.uploadImages(images: self.addedImages, for: currentOffer!.uid)
        
    }
    
    private func uploadImages(currentOfferUID: String) {
        uploadImages(images: imageViews, for: currentOfferUID)
    }
    
    private func uploadImages(images: [UIImageView], for offerID: String) {
        if images.count > 0 {
            for view in images {
                if let image = view.image {
                    MainController.dataService.uploadOfferPicture(image: image, offerID: offerID, completion: {
                        // Don't go back to the offers TableView until the new image has been completely uploaded
                        self.performSegue(withIdentifier: "backToOffers", sender: nil)
                    })
                }
            }
        } else {
            // Perform segue without having to wait for an image to be uploaded
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
            newView.frame.size.width = 115
            newView.frame.size.height = 106
            newView.contentMode = .scaleAspectFit
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
