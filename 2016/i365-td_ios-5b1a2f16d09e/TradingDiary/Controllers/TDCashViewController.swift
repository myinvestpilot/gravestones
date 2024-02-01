//
//  TDCashViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/8.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class TDCashViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var cashTransferTextField: UITextField!

    @IBOutlet weak var cashInOrOutPicker: UIPickerView!
    
    @IBOutlet weak var cashDatePicker: UIDatePicker!
    
    var inOrOut = 1 // in
    let buyOrSale = ["转入", "转出"]
    var cashStr = ""
    var cashDateStr = ""
    var portfolio: String?
    var postJSON = [String: AnyObject]()
    var portfolioInfo: TDPortfolio?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initTextFields()
        
        // init cash picker view
        cashInOrOutPicker.delegate = self
        cashInOrOutPicker.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let parentVC = self.parent as? TDBuySaleCashViewController {
            if let portfolioId = parentVC.portfolioId, let pobj = parentVC.portfolio {
                portfolio = portfolioId
                portfolioInfo = pobj
                cashDatePicker.minimumDate = portfolioInfo?.createdDate as Date?
                cashDatePicker.maximumDate = Date()
            }
        }
    }
    
    func initTextFields() {
        cashTransferTextField.delegate = self
        cashTransferTextField.keyboardType = .decimalPad
    }
    
    func validateTextFields() {
        
    }
    
    // MARK: - Position Picker Delegate and Datasource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return buyOrSale[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            inOrOut = 1
        } else {
            inOrOut = -1
        }
    }
    
    func getInputValue() {
        cashStr = cashTransferTextField.text ?? ""
        cashDateStr = cashDatePicker.date.dateToRFC1123()
    }
    
    func resetTextField() {
        self.cashTransferTextField.text = ""
        self.cashDatePicker.date = Date()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.characters.count == 0 {
            return true
        }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        switch textField {
        case cashTransferTextField:
            return prospectiveText.characters.count <= 10
        default:
            return true
        }
    }
    
    func wrapInputDict() {
        postJSON = [
            "portfolios": portfolio! as AnyObject,
            "transfer_money": (cashStr.toDouble() ?? 0) * Double(inOrOut) as AnyObject,
            "transfer_date": cashDateStr as AnyObject
        ]
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func validateInputText() -> Bool{
        if cashStr.toDouble() <= 0 {
            Toast.init(text: "转账金额不可为零").show()
            return false
        } else if (inOrOut == -1) && (cashStr.toDouble() > portfolioInfo!.marketValue * (1 - portfolioInfo!.position)) {
            let maxCash = portfolioInfo!.marketValue * (1 - portfolioInfo!.position)
            Toast.init(text: "最多可转出\(maxCash.toStringWithDecimal(0))").show()
            return false
        }
        return true
    }
    
    func cash(_ isAgain: Bool = false) {
        view.endEditing(true)
        // set input value
        getInputValue()
        // check input value
        // check input value
        guard validateInputText() else {
            return
        }
        wrapInputDict()
        // send data to server
        if let portfolioId = portfolio {
            if !isAgain {
                self.navigationController?.popToRootViewController(animated: true)
            }
            TDCashFlow.createCashHistoryWithPortfolioId(withPortfolioId: portfolioId, cashInfo: postJSON) { result in
                guard result.error == nil else {
                    JLToast.makeText("获取数据失败，请重试！").show()
                    return
                }
                guard let aJSON = result.value else {
                    JLToast.makeText("系统出错，请重试！").show()
                    return
                }
                if aJSON.dictionaryValue["_status"] == "ERR" {
                    JLToast.makeText("网络故障，请稍候再试！").show()
                    return
                }
                if aJSON.dictionaryValue["_status"] == "OK" {
                    JLToast.makeText("转账成功！").show()
                    // post notification
                    NSNotificationCenter.defaultCenter().postNotificationName("GetPortfolios", object: nil)
                } else {
                    JLToast.makeText("网络故障，请稍候再试").show()
                }
            }
        }
        
    }
    
    @IBAction func cashAgainAction(_ sender: AnyObject) {
        cash(true)
        // reset dict
        postJSON.removeAll()
        // reset text field
        resetTextField()
    }
    
    @IBAction func cashAction(_ sender: AnyObject) {
        cash()
    }
    
}
