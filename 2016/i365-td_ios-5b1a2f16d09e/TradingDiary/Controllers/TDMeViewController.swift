//
//  TDMeViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster

class TDMeViewController: UIViewController {
    
    @IBOutlet weak var userManagerButton: UIButton!
    
    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "我的"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    @IBAction func userManagerAction(_ sender: UIButton) {
        if HelpersMethond.sharedInstance.checkLogin() {
            // Perform Segue
            performSegue(withIdentifier: "ModifyProfileViewController", sender: self)
        } else {
            performSegue(withIdentifier: "LoginViewController", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if HelpersMethond.sharedInstance.checkLogin() {
            let username = UserDefaults.standard.object(forKey: "username") as? String
            userManagerButton.setTitle(username, for: UIControlState())
        } else {
            userManagerButton.setTitle("登陆或注册", for: UIControlState())
        }
        userManagerButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ModifyProfileViewController" {
            TDLoadingIndicatorView.show()
            HelpersMethond.getUserProfileByToken { result in
                TDLoadingIndicatorView.hide()
                guard result.error == nil else {
                    JLToast.makeText("获取数据失败，请重试！").show()
                    return
                }
                guard let userValue = result.value else {
                    JLToast.makeText("系统出错，请重试！").show()
                    return
                }
                let json = userValue.dictionaryObject!
                if let profileViewController = segue.destinationViewController as? TDProfileViewController {
                    profileViewController.mail = json["email"] as? String
                    profileViewController.phone = json["phone"] as? String
                }
            }
        }
    }

}
