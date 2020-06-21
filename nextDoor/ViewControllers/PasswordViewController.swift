//
//  PasswordViewController.swift
//  nextDoor
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import Eureka

public struct RuleMinLength: RuleType {

    let min: UInt

    public var id: String?
    public var validationError: ValidationError

    public init(minLength: UInt, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ?? "Das Passwort muss mindestens \(minLength) Zeichen enthalten"
        min = minLength
        validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    public func isValid(value: String?) -> ValidationError? {
        guard let value = value, !value.isEmpty else { return nil }
        return value.count < Int(min) ? validationError : nil
    }
}

public struct RuleMaxLength: RuleType {

    let max: UInt

    public var id: String?
    public var validationError: ValidationError

    public init(maxLength: UInt, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ?? "Das Passwort darf maximal \(maxLength) Zeichen enthalten"
        max = maxLength
        validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    public func isValid(value: String?) -> ValidationError? {
        guard let value = value, !value.isEmpty else { return nil }
        return value.count > Int(max) ? validationError : nil
    }
}

public struct RuleEqualsToRow<T: Equatable>: RuleType {

    public init(form: Form, tag: String, msg: String = "Die Passwörter stimmen nicht überein!", id: String? = nil) {
        self.validationError = ValidationError(msg: msg)
        self.form = form
        self.tag = tag
        self.row = nil
        self.id = id
    }

    public init(row: RowOf<T>, msg: String = "Die Passwörter stimmen nicht überein!", id: String? = nil) {
        self.validationError = ValidationError(msg: msg)
        self.form = nil
        self.tag = nil
        self.row = row
        self.id = id
    }

    public var id: String?
    public var validationError: ValidationError
    public weak var form: Form?
    public var tag: String?
    public weak var row: RowOf<T>?

    public func isValid(value: T?) -> ValidationError? {
        let rowAux: RowOf<T> = row ?? form!.rowBy(tag: tag!)!
        return rowAux.value == value ? nil : validationError
    }
}

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
                }
                .onCellSelection { cell, row in
                    if row.section?.form?.validate().isEmpty ?? false {
                        // TODO: Save the new password
                        self.navigationController?.popViewController(animated: true)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
    }
}
