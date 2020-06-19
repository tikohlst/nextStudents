//
//  ProfileViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

class ProfileViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var firstNameText: UITextField!
    @IBOutlet weak var lastNameText: UITextField!
    @IBOutlet weak var addressText: UITextField!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var radiusText: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var changeProfilePictureButton: UIButton!
    @IBOutlet weak var deleteProfilePictureButton: UIButton!

    let placeholderText = "Erzähl was über dich..."
    var currentUser: User?
    var db: Firestore!
    var storage: Storage!
    let radiusComponent = SliderTextComponent()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        radiusComponent.slider = radiusSlider
        radiusComponent.textField = radiusText
        
        db = Firestore.firestore()
        storage = Storage.storage()
        // prepare placeholder
        bioTextView.text = placeholderText
        bioTextView.textColor = UIColor.lightGray

        // tag all text fields
        firstNameText.tag = 0
        lastNameText.tag = 1
        addressText.tag = 2
        radiusText.tag = 3
        bioTextView.tag = 4

        // Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)

        // add user information
        if let user = currentUser {
            firstNameText.text = user.firstName
            lastNameText.text = user.lastName
            addressText.text = user.address
            radiusText.text = user.radius
            bioTextView.text = user.bio
            profilePictureImageView.image = user.profileImage
            radiusChanged(radiusText!)

        }
    }

    // Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true, completion: nil)
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            profilePictureImageView.image = pickedImage
        }
    }

    // MARK: - UI methods
    @IBAction func touchChangeProfilePicture(_ sender: UIButton) {
        let pickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            pickerController.delegate = self
            pickerController.allowsEditing = true
            pickerController.mediaTypes = ["public.image"]
            pickerController.sourceType = .photoLibrary

            present(pickerController, animated: true, completion: nil)
        }
    }

    @IBAction func touchDeleteProfilePicture(_ sender: UIButton) {
        profilePictureImageView.image = nil
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            textView.text = placeholderText
            textView.textColor = UIColor.lightGray
            
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
        // Else if the text view's placeholder is showing and the
        // length of the replacement string is greater than 0, set
        // the text color to black then set its text to the
        // replacement string
        else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text
        }
        // For every other case, the text should change with the usual
        // behavior...
        else {
            return true
        }
        // ...otherwise return false since the updates have already
        // been made
        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }

    /// Focus the next tagged text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @IBAction func touchSave(_ sender: UIButton) {
        if let user = currentUser, let authUser = Auth.auth().currentUser {
            user.firstName = firstNameText.text ?? ""
            user.lastName = lastNameText.text ?? ""
            user.address = addressText.text ?? ""
            user.radius = radiusText.text ?? ""
            user.bio = bioTextView.text

            self.db.collection("users").document(authUser.uid).setData([
                "givenName" : user.firstName,
                "name" : user.lastName,
                "address" : user.address,
                "radius" : user.radius,
                "bio" : user.bio
            ]) { err in
                if let err = err {
                    print("Error editing document: \(err.localizedDescription)")
                }
            }
            // profile image upload
            let storageRef = storage.reference(withPath: "profilePictures/\(String(describing: authUser.uid))/profilePicture.jpg")
            if let imageData = profilePictureImageView.image?.jpegData(compressionQuality: 0.75) {
                let imageMetadata = StorageMetadata.init()
                imageMetadata.contentType = "image/jpeg"
                storageRef.putData(imageData, metadata: imageMetadata) { (storageMetadata, error) in
                    if let error = error {
                        print("Error while uploading profile image: \(error.localizedDescription)")
                        return
                    }
                    print("upload complete with metadata: \(String(describing: storageMetadata))")
                }
            } else {
                if profilePictureImageView.image == nil {
                    storageRef.delete { error in
                        if let error = error {
                            print("Error while deleting profile image: \(error.localizedDescription)")
                        } else {
                            print("File deleted successfully")
                        }
                    }
                }
            }
        }
    }

    @IBAction func radiusChanged(_ sender: Any) {
        radiusComponent.radiusChanged(sender)
    }

    @IBAction func presentDeletionFailsafe(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "Are you sure you'd like to delete your account?", preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    func deleteUser() {
        let user = Auth.auth().currentUser
        
        // Delete user from the firebase database
        db.collection("users").document(user!.uid).delete { error in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
            } else {
                // Delete user from the firebase authentication
                user!.delete { error in
                    if let error = error {
                        // An error happened.
                        print(error.localizedDescription)
                    } else {
                        // Account was deleted. Go to login screen
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(identifier: "loginVC") as LoginViewController
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
