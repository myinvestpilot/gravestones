//
//  TDSaleViewController.swift
// TradingDiary
//
//  Created by Dawei Ma on 16/5/7.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster
import RealmSwift

class TDSaleViewController: UIViewController,UITextViewDelegate,UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var positionStockPicker: UIPickerView!
    @IBOutlet weak var salePriceTextField: UITextField!
    @IBOutlet weak var saleAmountTextLabel: UILabel!
    @IBOutlet weak var saleCommentTextView: UITextView!
    @IBOutlet weak var saleDatePicker: UIDatePicker!
    
    var priceStr = ""
    var commentStr = ""
    var saleDateStr = ""
    var etag = ""
    
    var notificationToken: NotificationToken? = nil
    
    var postJSON = [String: AnyObject]()
    
    var portfolio: String?
    var portfolioInfo: TDPortfolio?
    var positionsHold = [String]()
    var pickerCount: Int?
    var currentSelect = 0 {
        didSet {
            if positionsArray.count > 0 {
                saleAmountTextLabel.text = String(positionsArray[currentSelect].amount)
                saleDatePicker.minimumDate = positionsArray[currentSelect].created as Date
            }
        }
    }
    var positionsArray = [TDPosition]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTextFields()
        
        // init position picker view
        positionStockPicker.delegate = self
        positionStockPicker.dataSource = self
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let parentVC = self.parent as? TDBuySaleCashViewController {
            if let portfolioId = parentVC.portfolioId, let pobj = parentVC.portfolio {
                portfolio = portfolioId
                portfolioInfo = pobj
                saleDatePicker.minimumDate = portfolioInfo?.createdDate as Date?
                saleDatePicker.maximumDate = Date()
            }
        }
        initPositionPicker()
        if positionsArray.count > 0 {
            saleAmountTextLabel.text = String(positionsArray[currentSelect].amount)
        }
    }
    
    func initTextFields() {
        salePriceTextField.delegate = self
        salePriceTextField.keyboardType = .decimalPad
        saleCommentTextView.delegate = self
        saleCommentTextView.keyboardType = .default
        
        saleCommentTextView.textContainerInset = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        saleCommentTextView.text = "卖出理由"
        saleCommentTextView.textColor = UIColor.lightGray
    }
    
    // MARK: - Position Picker Delegate and Datasource
    
    func initPositionPicker() {
        if let service = CoreServices.getInstance() {
            if let pid = portfolio {
                let predicate = NSPredicate.init(format: "portfolios = '\(pid)'")
                let positions = service.aRealm.objects(TDPosition).filter(predicate)
                for position in positions {
                    let titleForPicker = position.name + "(" + position.code + ")"
                    positionsHold.append(titleForPicker)
                    positionsArray.append(position)
                }
                pickerCount = positions.count
            }
        }
        positionStockPicker.reloadAllComponents()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let count = pickerCount {
            return count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if positionsHold.count > 0 {
            return positionsHold[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentSelect = row
    }
    
    // regex validate
    
    func getInputValue() {
        priceStr = salePriceTextField.text ?? ""
        commentStr = saleCommentTextView.text != "买入理由" ? saleCommentTextView.text : ""
        saleDateStr = saleDatePicker.date.dateToRFC1123()
    }
    
    func resetTextField() {
        self.salePriceTextField.text = ""
        self.saleCommentTextView.text = "买入理由"
        self.saleCommentTextView.textColor = UIColor.lightGray
        self.saleDatePicker.date = Date()
    }
    
    func validateInputText() -> Bool{
        if !(priceStr =~ "^([0-9])([0-9]{0,2}$|[0-9]{0,2}\\.[0-9]{0,3}$)") {
            Toast.makeText("请输入正确的卖出价格，最多保留三位小数ヾ(=^▽^=)ノ").show()
            return false
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
        case salePriceTextField:
            return prospectiveText.characters.count <= 6
        case saleCommentTextView:
            return prospectiveText.characters.count <= 200
        default:
            return true
        }
    }
    
    func wrapInputDict() {
        let subJSON = [
            "trade_sale_price": priceStr.toDouble() ?? 0,
            "trade_sale_comment": commentStr,
            "trade_sale_date": saleDateStr
        ] as [String : Any]
        postJSON = [
            "sale": subJSON as AnyObject
        ]
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if saleCommentTextView.textColor == UIColor.lightGray {
            saleCommentTextView.text = nil
            saleCommentTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if saleCommentTextView.text.isEmpty {
            saleCommentTextView.text = "卖出理由"
            saleCommentTextView.textColor = UIColor.lightGray
        }
    }
    
    @IBAction func salePicUploadAction(_ sender: AnyObject) {
        Toast.makeText("图片上传功能正在开发ing").show()
    }
    
    func sale(_ isAgain: Bool = false) {
        view.endEditing(true)
        // must sale when has positions
        guard positionsArray.count > 0 else {
            Toast.makeText("组合没有持仓标的可卖").show()
            return
        }
        // set input value
        getInputValue()
        // check input value
        guard validateInputText() else {
            return
        }
        wrapInputDict()
        // send data to server
        // set current risk etag
        let riskId = positionsArray[currentSelect].riskId
        let predicate = NSPredicate.init(format: "id = '\(riskId)'")
        if let service = CoreServices.getInstance() {
            if let risk = service.aRealm.objects(TDRiskManager).filter(predicate).first {
                etag = risk.etag
            }
        }
        
        if let portfolioId = portfolio {
            if !isAgain {
                self.navigationController?.popToRootViewController(animated: true)
            }
            TDRiskManager.updateRiskManagerWithPortfolioId(withPortfolioId: portfolioId, withRiskId: riskId, withEtag: etag, riskInfo: postJSON) { result in
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
                    JLToast.makeText("卖出成功！").show()
                    // post notification
                    NSNotificationCenter.defaultCenter().postNotificationName("GetPortfolios", object: nil)
                } else {
                    JLToast.makeText("网络故障，请稍候再试").show()
                }
            }
        }
        
    }
    
    @IBAction func saleAgainAction(_ sender: AnyObject) {
        sale(true)
        // reset dict
        postJSON.removeAll()
        // reset text field
        resetTextField()
    }
    @IBAction func saleAction(_ sender: AnyObject) {
        sale()
    }
    
    @IBAction func saleAmountAlertAction(_ sender: AnyObject) {
        view.endEditing(true)
        let alert = SweetAlert()
        let alertColor = UIColor.init(hue: 0.01, saturation: 0.71, brightness: 0.90, alpha: 1)
        let alertString = "因目前资金管理功能需要统计分析每笔交易，并对当前组合持仓的风险资金计算评估，导致卖出操作只能按买入量进行操作。如果你多次卖出某个股票或场内基金的话，需自行计算多次卖出的平均价来录入。考虑到不少交易策略有定投的需求，我会在后续版本中加入对卖出数量修改的支持。对产品功能有建议也可在微信公众号与我联系<(￣︶￣)>"
        alert.showAlert("无法修改卖出数量？", subTitle: alertString, style: AlertStyle.none, buttonTitle: "我原谅你的水平", buttonColor: alertColor)
    }
}
