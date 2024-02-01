//
//  TDBuyViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Spring
import Toaster

class TDBuyViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var codeTextView: UITextField!
    @IBOutlet weak var buyPriceTextView: UITextField!
    @IBOutlet weak var buyAmountTextView: UITextField!
    @IBOutlet weak var stopPriceTextView: UITextField!
    @IBOutlet weak var targetPriceTextView: UITextView!
    @IBOutlet weak var buyCommentTextView: UITextView!
    @IBOutlet weak var buyDatePicker: UIDatePicker!
    
    var codeStr = ""
    var priceStr = ""
    var amountStr = ""
    var stopPriceStr = ""
    var targetPriceStr = ""
    var buyCommentStr = ""
    var buyDateStr = ""
    
    var portfolio: String?
    var portfolioInfo: TDPortfolio?
    
    var postJSON = [String: AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTextFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let parentVC = self.parent as? TDBuySaleCashViewController {
            if let portfolioId = parentVC.portfolioId, let pobj = parentVC.portfolio {
                portfolio = portfolioId
                portfolioInfo = pobj
                buyDatePicker.minimumDate = portfolioInfo?.createdDate as Date?
                buyDatePicker.maximumDate = Date()
            }
        }
    }
    
    func initTextFields() {
        codeTextView.delegate = self
        codeTextView.keyboardType = .numberPad
        buyPriceTextView.delegate = self
        buyPriceTextView.keyboardType = .decimalPad
        buyAmountTextView.delegate = self
        buyAmountTextView.keyboardType = .numberPad
        stopPriceTextView.delegate = self
        stopPriceTextView.keyboardType = .decimalPad
        targetPriceTextView.delegate = self
        targetPriceTextView.keyboardType = .decimalPad
        buyCommentTextView.delegate = self
        buyCommentTextView.keyboardType = .default
        
        buyCommentTextView.textContainerInset = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        buyCommentTextView.text = "买入理由"
        buyCommentTextView.textColor = UIColor.lightGray
        
    }
    
    func getStockInfo(_ code: String) {
        // TODO: - get stock info to check input true or wrong
    }
    
    func getInputValue() {
        codeStr = codeTextView.text ?? ""
        priceStr = buyPriceTextView.text ?? ""
        amountStr = buyAmountTextView.text ?? ""
        stopPriceStr = stopPriceTextView.text ?? ""
        targetPriceStr = targetPriceTextView.text ?? ""
        buyCommentStr = buyCommentTextView.text != "买入理由" ? buyCommentTextView.text : ""
        buyDateStr = buyDatePicker.date.dateToRFC1123()
    }
    
    func resetTextField() {
        codeTextView.text = ""
        buyPriceTextView.text = ""
        buyAmountTextView.text = ""
        stopPriceTextView.text = ""
        targetPriceTextView.text = ""
        buyCommentTextView.text = "买入理由"
        buyCommentTextView.textColor = UIColor.lightGray
        buyDatePicker.date = Date()
    }
    
    func wrapInputDict() {
        if let portfolioId = portfolio {
            let subJSON = [
                "code": codeStr,
                "trade_buy_price": priceStr.toDouble() ?? 0,
                "amount": amountStr.toDouble() ?? 0,
                "stop_price": stopPriceStr.toDouble() ?? 0,
                "target_price": targetPriceStr.toDouble() ?? 0,
                "trade_buy_comment": buyCommentStr,
                "trade_buy_date": buyDateStr
            ] as [String : Any]
            postJSON = [
                "portfolios": portfolioId as AnyObject,
                "buy": subJSON as AnyObject
            ]
        }
    }
    
    func validateInputText() -> Bool{
        // TODO: - add stock info check
        getStockInfo(codeStr)
        
        if !(codeStr =~ "^([01356])[0-9]{5}") {
            Toast.init(text: "证券代码有误，请修正后再试ヾ(=^▽^=)ノ").show()
            return false
        } else if !(priceStr =~ "^([0-9])([0-9]{0,2}$|[0-9]{0,2}\\.[0-9]{0,3}$)") {
            Toast.init(text: "请输入正确的买入价格，最多保留三位小数ヾ(=^▽^=)ノ").show()
            return false
        } else if !(amountStr =~ "^([1-9]+)0{2,8}$") {
            Toast.init(text: "请输入合规的买入数量，需是100的整数倍ヾ(=^▽^=)ノ").show()
            return false
        } else if amountStr.toDouble()! > portfolioInfo!.marketValue * (1 - portfolioInfo!.position) / priceStr.toDouble()! {
            let maxAmount = portfolioInfo!.marketValue * (1 - portfolioInfo!.position) / priceStr.toDouble()!
            Toast.init(text: "最多可买\(maxAmount.toStringWithDecimal(0))").show()
            return false
        }
        else if !(stopPriceStr =~ "^([0-9])([0-9]{0,2}$|[0-9]{0,2}\\.[0-9]{0,3}$)") {
            Toast.init(text: "请输入正确的止损价格，最多保留三位小数ヾ(=^▽^=)ノ").show()
            return false
        } else if !(targetPriceStr =~ "^([0-9])([0-9]{0,2}$|[0-9]{0,2}\\.[0-9]{0,3}$)") {
            Toast.init(text: "请输入正确的目标价格，最多保留三位小数ヾ(=^▽^=)ノ").show()
            return false
        }
        return true
    }
    

    func textViewDidBeginEditing(_ textView: UITextView) {
        if buyCommentTextView.textColor == UIColor.lightGray {
            buyCommentTextView.text = nil
            buyCommentTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if buyCommentTextView.text.isEmpty {
            buyCommentTextView.text = "买入理由"
            buyCommentTextView.textColor = UIColor.lightGray
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == codeTextView {
            buyPriceTextView.becomeFirstResponder()
        }else if textField == buyPriceTextView {
            buyAmountTextView.becomeFirstResponder()
        }else if textField == buyAmountTextView {
            stopPriceTextView.becomeFirstResponder()
        }else if textField == stopPriceTextView{
            targetPriceTextView.becomeFirstResponder()
        }else if textField == targetPriceTextView {
            buyCommentTextView.becomeFirstResponder()
        }else if textField == buyCommentTextView {
            view.endEditing(true)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.characters.count == 0 {
            return true
        }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        switch textField {
        case codeTextView:
            return prospectiveText.characters.count <= 6
        case buyPriceTextView:
            return prospectiveText.characters.count <= 6
        case buyAmountTextView:
            return prospectiveText.characters.count <= 10
        case stopPriceTextView:
            return prospectiveText.characters.count <= 6
        case targetPriceTextView:
            return prospectiveText.characters.count <= 6
        case buyCommentTextView:
            return prospectiveText.characters.count <= 200
        default:
            return true
        }
    }
    
    func buy(_ isAgain: Bool = false) {
        view.endEditing(true)
        // set input value
        getInputValue()
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
            TDRiskManager.createRiskManagerWithPortfolioId(withPortfolioId: portfolioId, riskInfo: postJSON) { result in
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
                    JLToast.makeText("买入成功！").show()
                    // post notification
                    NSNotificationCenter.defaultCenter().postNotificationName("GetPortfolios", object: nil)
                } else {
                    JLToast.makeText("网络故障，请稍候再试").show()
                }
            }
        }
    }
    
    @IBAction func buyAction(_ sender: AnyObject) {
        buy()
    }
    
    @IBAction func buyAgainAction(_ sender: AnyObject) {
        buy(true)
        // reset dict
        postJSON.removeAll()
        // reset text field
        resetTextField()
    }
    
    @IBAction func uploadBuyImageAction(_ sender: AnyObject) {
        Toast.init(text: "图片上传功能正在开发ing").show()
    }

}
