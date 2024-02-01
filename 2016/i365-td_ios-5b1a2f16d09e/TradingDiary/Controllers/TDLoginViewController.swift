//
//  TDLoginViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/10.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Spring
import Toaster

class TDLoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "登陆"
        
        initTextFields()
    }
    
    func initTextFields() {
        usernameTextField.delegate = self
        usernameTextField.keyboardType = .asciiCapable
        passwordTextField.delegate = self
        passwordTextField.keyboardType = .asciiCapable
        passwordTextField.isSecureTextEntry = true
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
        default:
            return true
        }
    }

    @IBAction func loginAction(_ sender: UIButton) {
        view.endEditing(true)
        let usernameStr = usernameTextField.text!
        let passwordStr = passwordTextField.text!
        
        if usernameStr.isEmpty || passwordStr.isEmpty {
            JLToast.makeText("账号和密码不能为空").show()
            return
        }
        
        HelpersMethond.sharedInstance.loginWithUsername(self,loginUsername: usernameStr, loginPassword: passwordStr)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
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
            passwordTextField.becomeFirstResponder()
        }
        return true
    }

}
