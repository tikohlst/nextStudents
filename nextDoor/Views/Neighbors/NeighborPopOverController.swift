//
//  FilterPopOverController.swift
//  nextDoor
//
//  Created by Benedict Zendel on 16.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import UIKit

class NeighborPopOverController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filterOptionsView: UIView!
    @IBOutlet weak var schoolPickerView: UIPickerView!
    @IBOutlet weak var degreePickerView: UIPickerView!
    
    // MARK: - Variables
    var schoolPickerData = [String]()
    var degreePickerData = [String]()
    var users: [User]?
    var filteredUsers: [User]?
    weak var delegate: NeighborFilterControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        schoolPickerView.delegate = self
        schoolPickerView.dataSource = self
        schoolPickerView.tag = 0
        
        degreePickerView.delegate = self
        degreePickerView.dataSource = self
        degreePickerView.tag = 1
        
        if let users = users {
            for user in users {
                if !schoolPickerData.contains(user.school) {
                    schoolPickerData.append(user.school)
                }
                if !degreePickerData.contains(user.degreeProgram) {
                    degreePickerData.append(user.degreeProgram)
                }
            }
        }
        degreePickerData.insert("-", at: 0)
        schoolPickerData.insert("-", at: 0)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let fittedSize = filterOptionsView?.sizeThatFits(UIView.layoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + 30, height: fittedSize.height + 30)
        }
    }
    
    private func filterUsers() {
        var filteredBySchool = users!
        var filteredByDegree = users!
        let schoolIndex = schoolPickerView.selectedRow(inComponent: 0)
        let degreeIndex = degreePickerView.selectedRow(inComponent: 0)
        if schoolIndex != 0 {
            filteredBySchool = users!.filter({ user -> Bool in
                user.school == schoolPickerData[schoolIndex]
            })
        }
        if degreeIndex != 0 {
            filteredByDegree = users!.filter({ user -> Bool in
                user.degreeProgram == degreePickerData[degreeIndex]
            })
        }
        let result = Set<User>(filteredBySchool).intersection(Set<User>(filteredByDegree))
        filteredUsers = Array(result)
    }

    private func setDelegate() {
        if let delegate = delegate {
            delegate.forward(data: filteredUsers!)
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

extension NeighborPopOverController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView.tag == 0 ? schoolPickerData.count : degreePickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerView.tag == 0 ? schoolPickerData[row] : degreePickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if users != nil {
            filterUsers()
            setDelegate()
        }
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let pickerText = pickerView.tag == 0 ? schoolPickerData[row] : degreePickerData[row]
        pickerLabel.text = pickerText
        pickerLabel.adjustsFontSizeToFitWidth = true
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
}

protocol NeighborFilterControllerDelegate: NSObjectProtocol {
    func forward(data: [User])
}
