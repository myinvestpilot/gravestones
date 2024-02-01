//
//  TDMarketViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDMarketViewController: UIViewController {

    @IBOutlet weak var tradeStrategyView: UIView!
    @IBOutlet weak var marketInformationView: UIView!
    @IBOutlet weak var assetAllocationView: UIView!
    @IBOutlet weak var segementedControl: UISegmentedControl!
    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "市场"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        
        segementedControl.selectedSegmentIndex = 1
        tradeStrategyView.isHidden = true
        marketInformationView.isHidden = false
        assetAllocationView.isHidden = true
        
    }
    @IBAction func segementIndexChanged(_ sender: AnyObject) {
        switch segementedControl.selectedSegmentIndex {
        case 0:
            tradeStrategyView.isHidden = false
            marketInformationView.isHidden = true
            assetAllocationView.isHidden = true
        case 1:
            tradeStrategyView.isHidden = true
            marketInformationView.isHidden = false
            assetAllocationView.isHidden = true
        case 2:
            tradeStrategyView.isHidden = true
            marketInformationView.isHidden = true
            assetAllocationView.isHidden = false
        default:
            tradeStrategyView.isHidden = true
            marketInformationView.isHidden = false
            assetAllocationView.isHidden = true
        }
    }

}
