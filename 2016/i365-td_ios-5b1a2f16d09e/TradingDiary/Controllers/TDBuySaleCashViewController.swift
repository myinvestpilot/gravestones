//
//  TDBuySaleCashViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDBuySaleCashViewController: UIViewController {
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBOutlet weak var buyView: UIView!
    @IBOutlet weak var saleView: UIView!
    @IBOutlet weak var cashView: UIView!
    
    var portfolioId: String?
    var portfolio: TDPortfolio?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        buyView.isHidden = false
        saleView.isHidden = true
        cashView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func segmentIndexChanged(_ sender: AnyObject) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            buyView.isHidden = false
            saleView.isHidden = true
            cashView.isHidden = true
        case 1:
            buyView.isHidden = true
            saleView.isHidden = false
            cashView.isHidden = true
        case 2:
            buyView.isHidden = true
            saleView.isHidden = true
            cashView.isHidden = false
        default:
            buyView.isHidden = false
            saleView.isHidden = true
            cashView.isHidden = true
        }
    }

}
