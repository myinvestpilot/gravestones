//
//  TDCashHistoryTableViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/14.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster

class TDCashHistoryTableViewController: UITableViewController {

    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    
    let cellIdentifier = "CashHistoryCellIdentifier"
    var numberOfCash = 0
    var cashs = [TDCashFlow]() {
        didSet {
            numberOfCash = cashs.count ?? 0
        }
    }
    var selection: TDCashFlow?
    var uid: String?
    var portfolioId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib.init(nibName: "CashHistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "CashHistoryCellIdentifier")
    }
    
    // MARK: - config navigation controller
    
    func setNavigationBar() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "资金管理"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // clear old data
        cashs = [TDCashFlow]()
        // set portfolio id
        let portfolioId = UserDefaults.standard.string(forKey: "currentPortfolioId")
        guard portfolioId != nil && portfolioId != "" else {
            numberOfCash = 0
            return
        }
        guard let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") else {
            numberOfCash = 0
            return
        }
        // set uid
        uid = userId
        let predicate = NSPredicate(format: "portfolios = '\(portfolioId!)' and userId = '\(userId)'")
        let cashsResults = service.aRealm.objects(TDCashFlow).filter(predicate).sorted(byProperty: "transferDate", ascending: false)
        numberOfCash = cashsResults.count
        for cash in cashsResults {
            cashs.append(cash)
        }
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return numberOfCash
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CashHistoryTableViewCell = tableView.dequeueReusableCell(withIdentifier: "CashHistoryCellIdentifier", for: indexPath) as! CashHistoryTableViewCell
        
        // Configure the cell...
        cell.cashDateLabel.text = cashs[indexPath.row].transferDate.dateToString()
        if cashs[indexPath.row].transferMoney >= 0 {
            cell.inOrOutLabel.text = "转入"
            cell.inOrOutLabel.textColor = UIColor.red
        } else {
            cell.inOrOutLabel.text = "转出"
            cell.inOrOutLabel.textColor = UIColor.green
        }
        cell.moneyLabel.text = cashs[indexPath.row].transferMoney.toStringWithDecimal()
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.row == numberOfCash - 1 {
            return false
        } else {
            return true
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            deleteCashById(withPortfolio: cashs[indexPath.row], forRowAtIndexPath: indexPath)
        }
    }
    
    func deleteCashById(withPortfolio cash: TDCashFlow, forRowAtIndexPath indexPath: IndexPath) {
        self.cashs.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        TDCashFlow.deleteCashHistoryWithPortfolioId(withPortfolioId: cash.portfolios, cashId: cash.id, etag: cash.etag) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let value = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if value.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权过期，请重新登陆试试ヾ(=^▽^=)ノ").show()
                return
            }
            guard let service = CoreServices.getInstance() else {
                JLToast.makeText("授权过期，请重新登陆试试ヾ(=^▽^=)ノ").show()
                return
            }
            // delete cash from realm
            service.aRealm.beginWrite()
            let predicate = NSPredicate(format: "id = '\(cash.id)'")
            let results = service.aRealm.objects(TDCashFlow).filter(predicate)
            service.aRealm.delete(results.first!)
            try! service.aRealm.commitWrite()
        }
    }
}
