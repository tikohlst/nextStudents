//
//  SliderTextComponent.swift
//  nextDoor
//
//  Created by Benedict Zendel on 19.06.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import Foundation
import UIKit

class SliderTextComponent {
    var slider : UISlider?
    var textField : UITextField?
    
    
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
