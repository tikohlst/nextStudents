//
//  FilterPopOverController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 16.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit

class FilterPopOverController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filterOptionsView: UIView!
    @IBOutlet weak var rangePickerView: UIPickerView!
    @IBOutlet weak var lessGreaterControl: UISegmentedControl!
    
    // MARK: - Variables
    var pickerData = ["50", "100", "200", "300", "400", "500"]
    var users: [User]?
    var filteredUsers: [User]?

    override func viewDidLoad() {
        super.viewDidLoad()

        rangePickerView.delegate = self
        rangePickerView.dataSource = self
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let fittedSize = filterOptionsView?.sizeThatFits(UIView.layoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + 30, height: fittedSize.height + 30)
        }
    }
    
    func filterUsers() -> [User] {
        //let range =
        return [User]()
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

extension FilterPopOverController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }
    
}

protocol FilterControllerDelegate: NSObjectProtocol {
    func forward(data: [User])
}
