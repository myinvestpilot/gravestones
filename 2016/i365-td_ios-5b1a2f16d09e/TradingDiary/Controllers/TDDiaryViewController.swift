//
//  TDDiaryViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDDiaryViewController: UITableViewController {

    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.84, brightness: 0.89, alpha: 1)
    
    var numberOfRisk = 0
    var risks = [TDRiskManager]()
    var selection: TDRiskManager?
    
    let riskCellIdentifier = "DiaryCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "日记"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib.init(nibName: "DiaryTableViewCell", bundle: nil), forCellReuseIdentifier: "DiaryCellIdentifier")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // clear old value for new portfolio
        risks = [TDRiskManager]()
        
        let portfolioId = UserDefaults.standard.string(forKey: "currentPortfolioId")
        guard portfolioId != nil && portfolioId != "" else {
            numberOfRisk = 0
            return
        }
        guard let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") else {
            numberOfRisk = 0
            return
        }
        let predicate = NSPredicate(format: "portfolios = '\(portfolioId!)' and userId = '\(userId)' and isHold = False")
        let risksResults = service.aRealm.objects(TDRiskManager).filter(predicate).sorted(byProperty: "created", ascending: false)
        numberOfRisk = risksResults.count
        // set content of collection view
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
        return numberOfRisk
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DiaryTableViewCell = tableView.dequeueReusableCell(withIdentifier: "DiaryCellIdentifier", for: indexPath) as! DiaryTableViewCell

        // Configure the cell...
        let buy = risks[indexPath.row].buy! as TDRiskBuy
        let buyDp = risks[indexPath.row].buyDp! as TDRiskBuyDp
        let saleDp = risks[indexPath.row].buySaleDp! as TDRiskBuySaleDp
        cell.positionCodeLabel.text = buy.code
        cell.positionNameLabel.text = buyDp.name
        cell.positionProfitOrLessRatioLabel.text = saleDp.tradeProfitRatio.toStringWithPercentage()
        cell.positionRatioLabel.text = buyDp.positionRatio.toStringWithPercentage()
    
        // set position profit or less ratio color, red for profit, green for less
        if saleDp.tradeProfitRatio > 0 {
            cell.positionProfitOrLessRatioLabel.textColor = UIColor.red
        } else {
            cell.positionProfitOrLessRatioLabel.textColor = UIColor.green
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // set table view cell height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: -
    // MARK: Table View Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selection = risks[indexPath.row]
        //Perform Segue
        performSegue(withIdentifier: "DiaryDetialViewController", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DiaryDetialViewController" {
            if let diaryDetailViewController = segue.destination as? DiaryDetailViewController, let item = selection {
                diaryDetailViewController.risk = item
            }
            
        }
    }
}
