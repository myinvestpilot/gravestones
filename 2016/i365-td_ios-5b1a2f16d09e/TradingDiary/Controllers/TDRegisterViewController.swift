//
//  TDRegisterViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/10.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Spring
import Toaster
import Validator

class TDRegisterViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var scrollViewBottomLayout: NSLayoutConstraint!
    
    let labelTextColor = UIColor.init(hue: 0.67, saturation: 0.02, brightness: 0.82, alpha: 1)
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        initTextFields()
    }
    
    func initTextFields() {
        usernameTextField.delegate = self
        usernameTextField.keyboardType = .asciiCapable
        mailTextField.delegate = self
        mailTextField.keyboardType = .emailAddress
        phoneTextField.delegate = self
        phoneTextField.keyboardType = .phonePad
        passwordTextField.delegate = self
        passwordTextField.keyboardType = .asciiCapable
        passwordTextField.isSecureTextEntry = true
        
        validateTextFields()
    }
    
    func validateTextFields() {
        var rules = ValidationRuleSet<String>()
        let lengthRule = ValidationRuleLength(min: 5, max: 20, failureError: ValidationError(message: "输入5-20个字符"))
        let emailRule = ValidationRulePattern(pattern: .EmailAddress, failureError: ValidationError(message: "输入正确的邮箱格式"))
        rules.addRule(lengthRule)
        
        usernameTextField.validationRules = rules
        usernameTextField.validationHandler = { result, control in
            switch result {
            case .Valid:
                control.textColor = UIColor.blackColor()
                self.usernameLabel.text = "账户名"
                self.usernameLabel.textColor = self.labelTextColor
            case .Invalid(let failureErrors):
                let messages = failureErrors.map { $0.message }
                if let message = messages.first {
                    self.usernameLabel.text = message
                    self.usernameLabel.textColor = UIColor.redColor()
                }
                control.textColor = UIColor.redColor()
            }
        }
        usernameTextField.validateOnInputChange(true)
        
        rules = ValidationRuleSet<String>()
        rules.addRule(emailRule)
        mailTextField.validationRules = rules
        mailTextField.validationHandler = { result, control in
            switch result {
            case .Valid:
                control.textColor = UIColor.blackColor()
                self.mailLabel.text = "邮箱"
                self.mailLabel.textColor = self.labelTextColor
            case .Invalid(let failureErrors):
                let messages = failureErrors.map { $0.message }
                if let message = messages.first {
                    self.mailLabel.text = message
                    self.mailLabel.textColor = UIColor.redColor()
                }
                control.textColor = UIColor.redColor()
            }
        }
        mailTextField.validateOnInputChange(true)
        
        rules = ValidationRuleSet<String>()
        rules.addRule(lengthRule)
        passwordTextField.validationRules = rules
        passwordTextField.validationHandler = { result, control in
            switch result {
            case .Valid:
                control.textColor = UIColor.blackColor()
                self.passwordLabel.text = "密码"
                self.passwordLabel.textColor = self.labelTextColor
            case .Invalid(let failureErrors):
                let messages = failureErrors.map { $0.message }
                if let message = messages.first {
                    self.passwordLabel.text = message
                    self.passwordLabel.textColor = UIColor.redColor()
                }
                control.textColor = UIColor.redColor()
            }
        }
        passwordTextField.validateOnInputChange(true)
        
        rules = ValidationRuleSet<String>()
        rules.addRule(ValidationRuleLength(min: 11, max: 11, failureError: ValidationError(message: "输入正确的手机号格式")))
        phoneTextField.validationRules = rules
        phoneTextField.validationHandler = { result, control in
            switch result {
            case .Valid:
                control.textColor = UIColor.blackColor()
                self.phoneLabel.text = "手机"
                self.phoneLabel.textColor = self.labelTextColor
            case .Invalid(let failureErrors):
                let messages = failureErrors.map { $0.message }
                if let message = messages.first {
                    self.phoneLabel.text = message
                    self.phoneLabel.textColor = UIColor.redColor()
                }
                control.textColor = UIColor.redColor()
            }
        }
        phoneTextField.validateOnInputChange(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.characters.count == 0 {
            return true
        }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        switch textField {
        case usernameTextField:
            return prospectiveText.inputMatchRegex("[A-Za-z0-9]") && prospectiveText.characters.count <= 20
        case passwordTextField:
            return prospectiveText.characters.count <= 20
        case phoneTextField:
            return prospectiveText.characters.count <= 11 && prospectiveText.inputMatchRegex("[0-9]")
        default:
            return true
        }
    }
    
    func validateInputText() -> Bool{
        let usernameStr = usernameTextField.text ?? ""
        let mailStr = mailTextField.text ?? ""
        let passwordStr = passwordTextField.text ?? ""
        let phoneStr = phoneTextField.text ?? ""
        
        if !(usernameStr =~ "[A-Za-z0-9]{5,20}") {
            JLToast.makeText("账户名长度应介于5-20位字符ヾ(=^▽^=)ノ").show()
            return false
        } else if !(mailStr =~ "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$") {
            JLToast.makeText("请输入正确的邮箱格式ヾ(=^▽^=)ノ").show()
            return false
        } else if !(passwordStr =~ "[A-Za-z0-9\\.$&@-_!?,']{5,20}") {
            JLToast.makeText("密码长度应介于5-20位字符，可包含特殊字符：.$&@-_!?,'").show()
            return false
        } else if !(phoneStr =~ "^(13[0-9]|15[012356789]|17[678]|18[0-9]|14[57])[0-9]{8}$") {
            JLToast.makeText("输入正确的手机号格式ヾ(=^▽^=)ノ").show()
            return false
        }
        return true
    }
    
    @IBAction func registerAction(_ sender: UIButton) {
        if !validateInputText() {
            return
        }
        view.endEditing(true)
        let usernameStr = usernameTextField.text!
        let mailStr = mailTextField.text!
        let passwordStr = passwordTextField.text!
        let phoneStr = phoneTextField.text!
        
        HelpersMethond.sharedInstance.registerUser(self, username: usernameStr, email: mailStr, password: passwordStr, phone: phoneStr)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == usernameTextField {
            mailTextField.becomeFirstResponder()
        }else if textField == mailTextField {
            passwordTextField.becomeFirstResponder()
        }else {
            phoneTextField.becomeFirstResponder()
        }
        return true
    }
    
}

