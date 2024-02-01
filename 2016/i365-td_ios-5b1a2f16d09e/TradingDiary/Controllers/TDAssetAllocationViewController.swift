//
//  TDAssetAllocationViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/14.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDAssetAllocationViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setWebView()
    }
    
    func setWebView() {
        let urlPath = TDResource.sharedInstance.baseURL + "/asset"
        let url = URL(string: urlPath)
        let request = URLRequest(url: url!)
        webView.loadRequest(request)
    }
}
