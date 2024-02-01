//
//  TDContactMeViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/10.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDContactMeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "与我联系"
    }
    
    @IBAction func addPortfolio(_ sender: UIBarButtonItem) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }

}
