//
//  DataService.swift
//  nextStudents
//
//  Created by Benedict Zendel on 30.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import Foundation
import Firebase

class DataService {
    
    let database = Firestore.firestore()
    let storage = Storage.storage()
    var currentUserAuth: FirebaseAuth.User!
    var currentUser: User!
    var currentUserUpdated = true
    
    var usersInRangeArray = [User]()
    var allUsers = [User]() {
        didSet {
            usersInRangeArray = allUsers
        }
    }
    
    var listeners = [ListenerRegistration]()
    
    
    func createUser(from dict: [String: Any?], completion: @escaping (_ success: Bool) -> Void) {
        Auth.auth().createUser(
            withEmail: (dict["email"] as! String),
            password: dict["password"] as! String) { authResult, error in
                // Error handling
                if error != nil {
                    print("An error occurred: \(error!.localizedDescription)")
                    completion(false)
                } else if authResult != nil {
                        completion(true)
                }
        }
    }
    
func setUserData(from dict: [String: Any?], radius: Double, gpsCoordinates: GeoPoint?, completion: @escaping () -> Void) {
    
    // Write userdata to firestore
    if let firstName = dict["firstName"] as? String,
        let lastName = dict["lastName"] as? String,
        let street = dict["street"] as? String,
        let housenumber = dict["housenumber"] as? String,
        let zipcode = dict["zipcode"] as? Int,
        let school = dict["hs"] as? String {
        
        let degreeProgram = dict["degreeProgram"] as? String ?? ""
            
            MainController.dataService.database.collection("users")
                .document(Auth.auth().currentUser!.uid)
                .setData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "street": street,
                    "housenumber": housenumber,
                    "zipcode": String(zipcode),
                    "radius": radius,
                    "gpsCoordinates": gpsCoordinates!,
                    "bio": "",
                    "skills": "",
                    "school": school,
                    "degreeProgram" : degreeProgram
                ]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    }
                    else {
                        completion()
                    }
            }
        }
    }
    
    func updateUserData(from dict: [String: Any?], radius: Double, gpsCoordinates: GeoPoint?, completion: @escaping () -> Void) {
        // Write userdata to firestore
        if let firstName = dict["firstName"] as? String,
            let name = dict["lastName"] as? String,
            let street = dict["street"] as? String,
            let housenumber = dict["housenumber"] as? String,
            let zipcode = dict["zipcode"] as? Int,
            let school = dict["hs"] as? String,
            let degreeProgram = dict["degreeProgram"] as? String {
            
            MainController.dataService.database.collection("users")
                .document(MainController.dataService.currentUser.uid)
                .updateData([
                    "firstName": firstName,
                    "lastName": name,
                    "street": street,
                    "housenumber": housenumber,
                    "zipcode": String(zipcode),
                    "radius": radius,
                    "gpsCoordinates": gpsCoordinates!,
                    "school": school,
                    "degreeProgram": degreeProgram
                ]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        completion()
                    }
            }
        } else {
            print("something went wrong.")
        }
    }
    
    func deleteUser(completion: @escaping () -> Void) {
        database.collection("users").document(MainController.dataService.currentUser.uid).delete { error in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
            } else {
                completion()
            }
        }
    }
    
    func deleteUserAuth(completion: @escaping () -> Void) {
        currentUserAuth.delete { error in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
            } else {
                completion()
            }
        }
    }
    
    func updatePassword(newPassword: String, completion: @escaping () -> Void) {
        currentUserAuth.updatePassword(to: newPassword) { (error) in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
            } else {
                completion()
            }
        }
    }
    
    func getNeighbors(completion: @escaping (_ newUser: User?) -> Void) {
        database.collection("users")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    
                    for currentNeighbor in querySnapshot!.documents {
                        let differenceInMeter = Utility.getGPSDifference(currentNeighbor.data()["gpsCoordinates"] as! GeoPoint, self.currentUser.gpsCoordinates)
                        // Only show neighbors in the defined range
                        if (differenceInMeter) < Double(self.currentUser.radius) {
                            // Don't show currentUser as its own neighbor
                            if currentNeighbor.documentID != self.currentUser.uid {
                                // Create User object for every neighbor in the radius and write it into an array
                                do {
                                    let newUser = try User().mapData(uid: currentNeighbor.documentID, data: currentNeighbor.data())
                                    completion(newUser)
                                } catch UserError.mapDataError {
                                    print("Error while mapping User!")
                                    completion(nil)
                                } catch {
                                    print("Unexpected error: \(error)")
                                }
                            }
                        }
                    }
                    
                }
        }
    }
    
    func getRawNeighborData(completion: @escaping (_ data: [QueryDocumentSnapshot]) -> Void) {
        database.collection("users")
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else if let documents = querySnapshot?.documents{
                completion(documents)
            }
        }
    }
    
    func getNeighbor(with uid: String, completion: @escaping (_ neighborData: [String: Any], _ documentID: String) -> Void) {
        database.collection("users").document(uid).getDocument { (neighbor, error) in
            if let error = error {
                print("Error getting neighbor information: \(error.localizedDescription)")
            } else if let neighbor = neighbor {
                if let neighborData = neighbor.data() {
                    completion(neighborData, neighbor.documentID)
                }
                
            }
            
        }
    }
    
    func getChats(for userID: String, completion: @escaping (_ querySnapshot: QuerySnapshot) -> Void) {
        //let array1:
        database.collection("Chats")
            .whereField("users", arrayContains: userID)
            .getDocuments { (chatQuerySnap, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                } else {
                    if let chatQuerySnap = chatQuerySnap {
                        completion(chatQuerySnap)
                    }
                }
        }
    }
    
    func getChatThreadCollection(for reference: DocumentReference, completion: @escaping (_ threadQuery: QuerySnapshot) -> Void) {
        
        reference.collection("thread").getDocuments { (threadQuery, error) in
            if let error = error {
                print("Error gettin thread: \(error.localizedDescription)")
            } else if let threadQuery = threadQuery, !threadQuery.isEmpty {
                completion(threadQuery)
            }
        }
    }
    
    func getProfilePicture(for uid: String, completion: @escaping (_ image: UIImage) -> Void) {
        storage
            .reference(withPath: "profilePictures/\(uid)/profilePicture.jpg")
            .getData(maxSize: 4 * 1024 * 1024) { (data, error) in
                if let error = error {
                    print("Error while downloading profile image: \(error.localizedDescription)")
                    if let image = UIImage(named: "DefaultProfilePicture") {
                        completion(image)
                    }
                } else {
                    if let image = UIImage(data: data!) {
                        completion(image)
                    }
                }
        }
    }
    
    func setProfilePicture(image: UIImage, completion: @escaping () -> Void) {
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            let imageMetadata = StorageMetadata.init()
            imageMetadata.contentType = "image/jpeg"
            storage
            .reference(withPath: "profilePictures/\(String(describing: MainController.dataService.currentUser.uid))/profilePicture.jpg").putData(imageData, metadata: imageMetadata) { (storageMetadata, error) in
                if let error = error {
                    print("Error while uploading profile image: \(error.localizedDescription)")
                }
                print("upload complete with metadata: \(String(describing: storageMetadata))")
                completion()
            }
        }
    }
    
    func getOfferPicturesReferences(for offerId: String, completion: @escaping (_ references: [StorageReference]) -> Void) {
        storage
            .reference().child("offers/\(offerId)")
            .listAll { (result, error) in
                if let error = error {
                    print("Error while listing data: \(error.localizedDescription)")
                } else {
                    completion(result.items)
                }
        }
    }
    
    func getOfferPicture(from reference: StorageReference, completion: @escaping (_ image: UIImage) -> Void) {
        
        reference.getData(maxSize: 4 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("Error while downloading profile image: \(error.localizedDescription)")
                if let offerImage = UIImage(named: "defaultOfferImage") {
                    completion(offerImage)
                }
            } else {
                // Data for "profilePicture.jpg" is returned
                if let offerImage = UIImage(data: data!) {
                    completion(offerImage)
                }
            }
            
        }
    }
    
    func deleteOfferPicture(for offerID: String, imageID: String) {
        storage.reference(withPath: "offers/\(offerID)/\(imageID)")
            .delete { error in
                if let error = error {
                    print ("Error deleting image: \(error.localizedDescription)")
                }
        }
    }
    
    func uploadOfferPicture(image: UIImage, offerID: String, completion: @escaping () -> Void) {
        let imageID = UUID.init().uuidString
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            let imageMetaData = StorageMetadata.init()
            imageMetaData.contentType = "image/jpeg"
            storage
                .reference(withPath: "offers/\(offerID)/\(imageID).jpeg").putData(imageData, metadata: imageMetaData) { (storageMetadata, error) in
                    if let error = error {
                        print("Error while uploading data: \(error.localizedDescription)")
                    } else {
                        print("upload complete with metadata: \(storageMetadata?.description ?? "nil")")
                        completion()
                    }
            }
        }
    }
    
    func createOffer(with dict: [String: Any], completion: @escaping (_ uid: String?) -> Void) {
        let newOfferId = UUID.init().uuidString
        database.collection("offers")
            .document(MainController.dataService.currentUser.uid)
            .collection("offer")
            .document(newOfferId)
            .setData(dict) { err in
                if let err = err {
                    print("Error creating document: \(err.localizedDescription)")
                    completion(nil)
                } else {
                    completion(newOfferId)
                }
        }
    }
    
    func updateOffer(with dict: [String: Any], offerID: String) {
        database.collection("offers")
            .document(MainController.dataService.currentUser.uid)
            .collection("offer")
            .document(offerID)
            .updateData(dict) { err in
                if let err = err {
                    print("Error editing document: \(err.localizedDescription)")
                }
        }
    }
    
    func deleteOffer(for offerID: String) {
        database
            .collection("offers")
            .document(currentUser.uid)
            .collection("offer")
            .document(offerID)
            .delete()
        
        storage
            .reference(withPath: "offers/\(offerID)")
            .delete()
    }

    func addRequest(with data: [String:Any], to id: String, completion: @escaping () -> Void) {
        database.collection("friends").document(id).setData(data) { error in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
            } else {
                completion()
            }
        }
    }
    
    func getFriendList(uid: String, completion: @escaping (_ data: Dictionary<String, Int>) -> Void) {
        database.collection("friends").document(uid).getDocument { document, error in
            if let error = error {
                print("Error getting friendlist: \(error.localizedDescription)")
            } else if let docData = document?.data(), let data = (docData["list"] as! Dictionary<String, Int>?) {
                completion(data)
            } else {
                // no error but document doesn't exist right now -> create data for empty document
                let newData = Dictionary<String, Int>()
                completion(newData)
            }
        }
    }
    
    func setFriendList(uid: String, data: Dictionary<String, Int>, completion: @escaping (Bool) -> Void) {
        var docData = [String:Any]()
        docData["list"] = data
        database.collection("friends").document(uid).setData(docData) { error in
            if let error = error {
                print("Error setting data: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func addListenerForCurrentUser(completion: @escaping (_ data: [String: Any], _ documentId: String) -> Void) {
        listeners.append(MainController.dataService.database.collection("users")
            .document(MainController.dataService.currentUserAuth.uid)
            .addSnapshotListener { (querySnapshot, error) in
                if error != nil {
                    print("Error getting document: \(error!.localizedDescription)")
                } else  if let querySnapshot = querySnapshot, let data = querySnapshot.data() {
                    let docId = querySnapshot.documentID
                    completion(data, docId)
                }
        })
    }
    
    func addListener(for collection: String, completion: @escaping (_ snapshot: QueryDocumentSnapshot) -> Void) {
        listeners.append(MainController.dataService.database.collection(collection)
            .addSnapshotListener() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        completion(document)
                    }
                }
        })
    }
    
    func addListenerForChatThread(chatId: String, chatPartnerUID: String, completion: @escaping (_ snapshot: QueryDocumentSnapshot) -> Void ) {
        ChatsTableViewController.threadListeners[chatPartnerUID] = database.collection("Chats")
            .document(chatId)
            .collection("thread")
            .order(by: "created", descending: true)
            .limit(to: 1)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                
                for latestMessage in documents {
                   completion(latestMessage)
                }
        }
    }
    
    func addListenerForOffer(for ownerUID: String, completion: @escaping (_ documents: [QueryDocumentSnapshot]) -> Void) {
        listeners.append(MainController.dataService.database.collection("offers")
            .document(ownerUID)
            .collection("offer")
            .addSnapshotListener() { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!.localizedDescription)")
                    return
                }
                completion(documents)
        })
    }
    
    func createListenerForChatThreadOrdered(snapshot: QueryDocumentSnapshot, completion: @escaping (_ threadQuery: QuerySnapshot) -> Void) -> ListenerRegistration {
        return snapshot.reference.collection("thread")
                .order(by: "created", descending: false)
                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    } else {
                        if let threadQuery = threadQuery {
                            completion(threadQuery)
                        }
                    }
                })
        }
}
