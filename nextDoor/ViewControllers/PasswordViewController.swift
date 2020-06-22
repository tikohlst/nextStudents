//
//  PasswordViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka

class PasswordViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Design for LabelRow as validation error
        LabelRow.defaultCellUpdate = { cell, row in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
        }

        // Present label on the left side of the row in
        // red if the value on the right side is invalid
        PasswordRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }

        // Add new LabelRow below the PasswordRow to display existing errors
        PasswordRow.defaultOnRowValidationChanged = { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section?.insert(labelRow, at: indexPath)
                }
            }
        }

        form
            +++ Section()

                <<< PasswordRow("password") {
                    $0.title = "Neues Password"
                    $0.add(rule: RuleRequired(msg: "Du musst erst ein neues Passwort eingeben."))
                    $0.add(rule: RuleMinLength(minLength: 8, msg:  "Das Passwort muss mindestens 8 Zeichen enthalten"))
                    $0.add(rule: RuleMaxLength(maxLength: 16, msg: "Das Passwort darf maximal 16 Zeichen enthalten"))
                }

                <<< PasswordRow() {
                    $0.title = "Password bestätigen"
                    $0.add(rule: RuleEqualsToRow(form: form, tag: "password", msg: "Die Passwörter stimmen nicht überein"))
                }

            +++ Section()
                <<< ButtonRow() {
                    $0.title = "Passwort ändern"
                }.onCellSelection { cell, row in
                    if row.section?.form?.validate().isEmpty ?? false {
                        // TODO: Save the new password
                        self.navigationController?.popViewController(animated: true)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
    }
}
