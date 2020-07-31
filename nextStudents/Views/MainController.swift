//
//  MainController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class MainController: UITabBarController {
    
    // MARK: - Variables
    
    static let dataService = DataService()
    
    // MARK: - UIViewController events
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        // show the offers screen after login
        self.selectedIndex = 1
        
    }
}
