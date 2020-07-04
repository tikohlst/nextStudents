//
//  SliderTextComponent.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Foundation
import UIKit

class SliderTextComponent {

    // MARK: - Variables

    var slider: UISlider?
    var textField: UITextField?

    // MARK: - Methods

    func radiusChanged(_ sender: Any) {
        if let slider = slider, let textField = textField {
            if type(of: sender) == type(of: slider) {
                let oldValue = Int(round(slider.value))
                let newValue = oldValue / 50 * 50
                
                textField.text = String(newValue)
                slider.value = Float(newValue)
            } else {
                let oldValue = Int(textField.text!) ?? 0
                var newValue = oldValue / 50 * 50 +
                    ((oldValue % 100 < 50 && oldValue % 100 >= 25)
                    || !(oldValue % 100 < 75) ? 50 : 0)
                newValue = newValue < 50 ? 50 : newValue
                slider.value = Float(newValue)
                textField.text = String(newValue)
            }
        }
    }
}
