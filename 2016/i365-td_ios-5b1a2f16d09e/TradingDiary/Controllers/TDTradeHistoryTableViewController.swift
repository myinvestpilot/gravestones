//
//  TDTradeHistoryTableViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster

class TDTradeHistoryTableViewController: UITableViewController {

    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    
    let cellIdentifier = "TradeHistoryCellIdentifier"
    var numberOfRisks = 0
    var risks = [TDRiskManager]() {
        didSet {
            numberOfRisks = risks.count ?? 0
        }
    }
    var selection: TDRiskManager?
    var uid: String?
    var portfolioId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib.init(nibName: "TradeHistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "TradeHistoryCellIdentifier")
    }
    
    // MARK: - config navigation controller
    
    func setNavigationBar() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        
        let cashHistoryBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "MoneyCash"), style: .plain, target: self, action: #selector(TDTradeHistoryTableViewController.cashHistory))
        cashHistoryBarButtonItem.tintColor = mainFgColor
        navigationItem.setRightBarButton(cashHistoryBarButtonItem, animated: true)

        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "交易历史"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // clear old data
        risks = [TDRiskManager]()
        // set portfolio id
        let portfolioId = UserDefaults.standard.string(forKey: "currentPortfolioId")
        guard portfolioId != nil && portfolioId != "" else {
            numberOfRisks = 0
            return
        }
        guard let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") else {
            numberOfRisks = 0
            return
        }
        // set uid
        uid = userId
        let predicate = NSPredicate(format: "portfolios = '\(portfolioId!)' and userId = '\(userId)' and isHold = False")
        let risksResults = service.aRealm.objects(TDRiskManager).filter(predicate).sorted(byProperty: "created", ascending: false)
        numberOfRisks = risksResults.count
        for risk in risksResults {
            risks.append(risk)
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
        return numberOfRisks
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TradeHistoryTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TradeHistoryCellIdentifier", for: indexPath) as! TradeHistoryTableViewCell
        
        // Configure the cell...
        let buy = risks[indexPath.row].buy! as TDRiskBuy
        let buyDp = risks[indexPath.row].buyDp! as TDRiskBuyDp
        
        if let sale = risks[indexPath.row].sale, let _ = risks[indexPath.row].buySaleDp {
            let saleObj = sale as TDRiskSale
            cell.saleDateLabel.text = "卖出日期：" +  saleObj.tradeSaleDate.dateToString()
        } else {
            cell.saleDateLabel.text = "持有中"
            cell.saleDateLabel.textColor = UIColor.red
        }
        cell.codeLabel.text = buy.code
        cell.nameLabel.text = buyDp.name
        cell.buyDateLabel.text = "买入日期：" + buy.tradeBuyDate.dateToString()
        
        return cell
    }
    
    // set table view cell height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            deleteRiskById(withPortfolio: risks[indexPath.row], forRowAtIndexPath: indexPath)
        }
    }
    
    func deleteRiskById(withPortfolio risk: TDRiskManager, forRowAtIndexPath indexPath: IndexPath) {
        self.risks.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        TDRiskManager.deleteRiskManagerWithPortfolioId(withPortfolioId: risk.portfolios, withRiskId: risk.id, etag: risk.etag) { result in
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
            // delete risk from realm
            service.aRealm.beginWrite()
            let predicate = NSPredicate(format: "id = '\(risk.id)'")
            let results = service.aRealm.objects(TDRiskManager).filter(predicate)
            service.aRealm.delete(results.first!)
            try! service.aRealm.commitWrite()
        }
    }
    
    func cashHistory() {
        if HelpersMethond.sharedInstance.checkLogin() {
            performSegue(withIdentifier: "CashHistoryViewController", sender: self)
        } else {
            self.tabBarController?.selectedIndex = 4
            Toast.makeText("请登陆后再新建组合吧ヾ(=^▽^=)ノ").show()
        }
    }
}
