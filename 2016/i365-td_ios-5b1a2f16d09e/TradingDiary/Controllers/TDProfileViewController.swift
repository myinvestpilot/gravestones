//
//  TDProfileViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/10.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster

class TDProfileViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var mail: String? {
        didSet {
            mailTextField.text = mail
        }
    }
    var phone: String? {
        didSet {
            phoneTextField.text = phone
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        initTextFields()
    }
    
    func initTextFields() {
        mailTextField.delegate = self
        mailTextField.keyboardType = .emailAddress
        phoneTextField.delegate = self
        phoneTextField.keyboardType = .phonePad
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
        case passwordTextField:
            return prospectiveText.characters.count <= 20
        case phoneTextField:
            return prospectiveText.characters.count <= 11 && prospectiveText.inputMatchRegex("[0-9]")
        default:
            return true
        }
    }
    
    func validateInputText() -> Bool{
        let mailStr = mailTextField.text ?? ""
        let passwordStr = passwordTextField.text ?? ""
        let phoneStr = phoneTextField.text ?? ""
        
        if !(mailStr =~ "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$") {
            Toast.makeText("请输入正确的邮箱格式ヾ(=^▽^=)ノ").show()
            return false
        } else if !(phoneStr =~ "^(13[0-9]|15[012356789]|17[678]|18[0-9]|14[57])[0-9]{8}$") {
            Toast.makeText("输入正确的手机号格式ヾ(=^▽^=)ノ").show()
            return false
        } else if !(passwordStr =~ "[A-Za-z0-9\\.$&@-_!?,']{5,20}") {
            Toast.makeText("密码长度应介于5-20位字符，可包含特殊字符：.$&@-_!?,'").show()
            return false
        }
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    @IBAction func modifyProfileAction(_ sender: UIButton) {
        if !validateInputText() {
            return
        }
        view.endEditing(true)
        if let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") {
            TDLoadingIndicatorView.show()
            let mailStr = mailTextField.text!
            let passwordStr = passwordTextField.text!
            let phoneStr = phoneTextField.text!
            let userInfo = ["email":mailStr, "hashpw": passwordStr, "phone": phoneStr]
            service.updateUserProfile(userId, userInfo: userInfo) { result in
                TDLoadingIndicatorView.hide()
                guard result.error == nil else {
                    JLToast.makeText("获取数据失败，请重试！").show()
                    return
                }
                guard let _ = result.value else {
                    JLToast.makeText("系统出错，请重试！").show()
                    return
                }
                HelpersMethond.sharedInstance.logout()
                JLToast.makeText("修改资料成功，请重新登陆ヾ(=^▽^=)ノ").show()
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else {
            Toast.makeText("请先登陆ヾ(=^▽^=)ノ").show()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        if let service = CoreServices.getInstance() {
            let realm = service.aRealm
            // Delete all objects from the realm
            try! realm.write {
                realm.deleteAll()
            }
        }
        HelpersMethond.sharedInstance.logout()
        navigationController?.popViewController(animated: true)
        
        HelpersMethond.sharedInstance.resetViewControllers(self)
        
        //let appDelegate = UIApplication.sharedApplication().delegate
        
        //appDelegate?.window??.rootViewController = navigation
        
//        tabBarController?.viewControllers?.map { controller in
//            if controller.isMemberOfClass(UINavigationController.classForCoder()) {
//                if let navController = controller as? UINavigationController {
//                    navController.popViewControllerAnimated(false)
//                }
//            }
//        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == mailTextField {
            phoneTextField.becomeFirstResponder()
        }else if textField == phoneTextField {
            passwordTextField.becomeFirstResponder()
        }
        return true
    }

}
