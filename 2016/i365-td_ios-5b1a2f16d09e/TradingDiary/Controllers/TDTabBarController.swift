//
//  TDTabBarController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/3.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Select the trading view controller when loade the view
        self.selectedIndex = 2
        self.tabBar.tintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
        self.tabBarItem.selectedImage?.withRenderingMode(.alwaysOriginal)
        self.tabBar.barTintColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
