//
//  ProfileViewController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 04.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var firstNameText: UITextField!
    @IBOutlet weak var lastNameText: UITextField!
    @IBOutlet weak var addressText: UITextField!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var radiusText: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func radiusChanged(_ sender: Any) {
        // TODO: change respective UI Element when radius got changed
        if type(of: sender) == type(of: radiusSlider!) {
            let oldValue = Int(round(radiusSlider.value))
            let newValue = oldValue/50 * 50

            radiusText.text = String(newValue)
            radiusSlider.value = Float(newValue)
            
        } else {
            let oldValue = Int(radiusText.text!) ?? 0
            let newValue = oldValue / 50 * 50 + (oldValue < 50 ? 50 : 0)
            radiusSlider.value = Float(newValue)
            radiusText.text = String(newValue)
        }
    }
    

}
