//
//  TDAddPortfolioViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster

class TDAddPortfolioViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var moneyTextFild: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = UIColor.white
        initTextFields()
    }
    
    func initTextFields() {
        nameTextField.delegate = self
        nameTextField.keyboardType = .default
        moneyTextFild.delegate = self
        moneyTextFild.keyboardType = .decimalPad
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.characters.count == 0 {
            return true
        }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        switch textField {
        case nameTextField:
            return prospectiveText.length <= 8 && prospectiveText.doesNotContainCharactersIn(" ")
        default:
            return true
        }
    }
    
    @IBAction func addPortfolio(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        
        let nameStr = nameTextField.text!
        let moneyStr = moneyTextFild.text!
        
        if nameStr.isEmpty || moneyStr.isEmpty {
            Toast.init(text: "名称和金额不能为空").show()
            return
        }
        if let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") {
            let portfolioResults = service.aRealm.objects(TDPortfolio.self)
            if portfolioResults.count >= 5 {
                Toast.init(text: "已达组合上限，最多新建5个组合").show()
                return
            }
            let portfolioInfo = ["name": nameStr, "initial_money": Double.init(moneyStr)!] as [String : Any]
            TDLoadingIndicatorView.show()
            service.createPortfolio(userId, portfolioInfo: portfolioInfo as! [String : AnyObject]) { result in
                TDLoadingIndicatorView.hide()
                guard result.error == nil else {
                    JLToast.makeText("获取数据失败，请重试！").show()
                    return
                }
                guard let value = result.value else {
                    JLToast.makeText("系统出错，请重试！").show()
                    return
                }
                guard value.dictionaryValue["_status"] == "OK" else {
                    JLToast.makeText("授权过期，请重新登陆试试ヾ(=^▽^=)ノ").show()
                    return
                }
                JLToast.makeText("新建组合成功，记录几笔交易吧ヾ(=^▽^=)ノ").show()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("GetPortfolios", object: nil)
                self.navigationController?.popToRootViewControllerAnimated(true)
                
                // update local portfolios database on backgroud
//                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//                dispatch_async(dispatch_get_global_queue(priority, 0)) {
//                    dispatch_async(dispatch_get_main_queue()) {
                        // update some UI
//                    }
//                }
            }
        } else {
            Toast.init(text: "请登陆后再新建组合吧ヾ(=^▽^=)ノ").show()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == nameTextField {
            moneyTextFild.becomeFirstResponder()
        }
        return true
    }
    
}
