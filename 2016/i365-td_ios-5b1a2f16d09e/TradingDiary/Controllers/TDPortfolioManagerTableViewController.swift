//
//  TDPortfolioManagerTableViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster

class TDPortfolioManagerTableViewController: UITableViewController {
    
    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    
    let cellIdentifier = "PortfolioCellIdentifier"
    var numberOfPortfolio = 0
    var portfolios = [TDPortfolio]() {
        didSet {
            numberOfPortfolio = portfolios.count ?? 0
        }
    }
    var selection: TDPortfolio?
    var uid: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib.init(nibName: "PortfolioTableViewCell", bundle: nil), forCellReuseIdentifier: "PortfolioCellIdentifier")
    }

    // MARK: - config navigation controller
    
    func setNavigationBar() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        
        let addPortfolioBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "Add-Icon"), style: .plain, target: self, action: #selector(TDPortfolioManagerTableViewController.addPortfolio))
        addPortfolioBarButtonItem.tintColor = mainFgColor
        navigationItem.setRightBarButton(addPortfolioBarButtonItem, animated: true)
        
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "组合管理"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // clear old value for new portfolio
        portfolios = [TDPortfolio]()
        
        guard let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") else {
            numberOfPortfolio = 0
            return
        }
        // set uid
        uid = userId
        let predicate = NSPredicate(format: "userId = '\(userId)'")
        let portfoliosResults = service.aRealm.objects(TDPortfolio).filter(predicate).sorted(byProperty: "createdDate", ascending: false)
        numberOfPortfolio = portfoliosResults.count
        for portfolio in portfoliosResults {
            portfolios.append(portfolio)
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
        return numberOfPortfolio
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PortfolioTableViewCell = tableView.dequeueReusableCell(withIdentifier: "PortfolioCellIdentifier", for: indexPath) as! PortfolioTableViewCell
        
        // Configure the cell...
        cell.portfolioNameLabel.text = portfolios[indexPath.row].name
        cell.portfolioCreatedDateLabel.text = portfolios[indexPath.row].createdDate.dateToString()
        
        return cell
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
            deletePortfolioById(withPortfolio: portfolios[indexPath.row], forRowAtIndexPath: indexPath)
        }
    }
    
    func deletePortfolioById(withPortfolio portfolio: TDPortfolio, forRowAtIndexPath indexPath: IndexPath) {
        TDLoadingIndicatorView.show()
        TDPortfolio.dPortfolioById(withUserId: portfolio.userId, withPortfolioId: portfolio.id, withEtag: portfolio.etag) { result in
            TDLoadingIndicatorView.hide()
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
            // delete portfolio from realm
            service.aRealm.beginWrite()
            let predicate = NSPredicate(format: "id = '\(portfolio.id)'")
            let results = service.aRealm.objects(TDPortfolio).filter(predicate)
            service.aRealm.delete(results.first!)
            try! service.aRealm.commitWrite()
            self.portfolios.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func addPortfolio() {
        if HelpersMethond.sharedInstance.checkLogin() {
            performSegue(withIdentifier: "AddPortfolioViewController", sender: self)
        } else {
            self.tabBarController?.selectedIndex = 4
            Toast.init(text: "请登陆后操作ヾ(=^▽^=)ノ").show()
        }
    }

}
