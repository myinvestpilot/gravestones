//
//  HelpersMethond.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/5.
//  Copyright © 2016年 i365.tech. All rights reserved.
//
import Foundation
import Alamofire
import SwiftyJSON
import RealmSwift
import Toaster
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public final class HelpersMethond: NSObject {
    // singletons
    static let sharedInstance = HelpersMethond()
    
    static let tdKeychainWrapper = KeychainWrapper()
    
    fileprivate override init() {}
    
    // MARK: - User Login
    func getToken() -> String? {
        if checkLogin() {
            let currentDate = Date()
            let token_expire_time = UserDefaults.standard.object(forKey: "token_expire_time") as? Date
            if currentDate.timeIntervalSinceReferenceDate > token_expire_time?.timeIntervalSinceReferenceDate  {
                refreshToken()
            }
            return UserDefaults.standard.object(forKey: "access_token") as? String
        }
        return nil
    }
    
    func refreshToken() {
        if checkLogin() {
            loginWithUsername(nil, loginUsername: UserDefaults.standardUserDefaults().stringForKey("username")!, loginPassword: (HelpersMethond.tdKeychainWrapper.myObjectForKey("v_Data") as? String)!)
        }
    }
    
    func checkLogin() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasLoginKey")
    }
    
    func storeUserIdByToken() {
        HelpersMethond.getUserProfileByToken { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let userValue = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            let json = userValue.dictionaryObject!
            NSUserDefaults.standardUserDefaults().setValue(json, forKey: "user_info")
            NSUserDefaults.standardUserDefaults().setValue(json["_id"]!.description, forKey: "user_id")
            // post notification
            NSNotificationCenter.defaultCenter().postNotificationName("GetPortfolios", object: nil)
        }
    }
    
    class func getUserProfileByToken(_ completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.User)
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    func loginWithUsername(_ view:UIViewController?, loginUsername username: String, loginPassword password: String) {
        //NSLog(NSUserDefaults.standardUserDefaults().dictionaryRepresentation().description)
        let baseURL = TDResource.sharedInstance.baseURL
        let clientID = TDResource.sharedInstance.clientID
        let grantType = TDResource.sharedInstance.grantType
        let urlString = baseURL + TDResource.ResourcePath.token.description
        let parameters = [
            "client_id": clientID,
            "grant_type": grantType,
            "username": username,
            "password": password,
            ]
        TDLoadingIndicatorView.show()
        Alamofire.request(.POST, urlString, parameters: parameters)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                switch response.result {
                case .Success:
                    TDLoadingIndicatorView.hide()
                    if let object = response.result.value {
                        let json = JSON(object)
                        
                        if json["access_token"] != nil {
                            
                            let hasLoginKey = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
                            if !hasLoginKey {
                                NSUserDefaults.standardUserDefaults().setValue(username, forKey: "username")
                            }
                            
                            HelpersMethond.tdKeychainWrapper.mySetObject(password, forKey: kSecValueData)
                            HelpersMethond.tdKeychainWrapper.writeToKeychain()
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
                            NSUserDefaults.standardUserDefaults().setValue(json["access_token"].description, forKey: "access_token")
                            let currentDate = NSDate()
                            let hoursToAddInSeconds: NSTimeInterval = 19 * 60 * 60 // token after 19 hours to expire
                            NSUserDefaults.standardUserDefaults().setValue(currentDate.dateByAddingTimeInterval(hoursToAddInSeconds), forKey: "token_expire_time")
                            NSUserDefaults.standardUserDefaults().synchronize()
                            // store user_id to local in backgroud
                            self.storeUserIdByToken()
                            // get CoreServies Object
                            let _ = CoreServices.getInstance()
                            if let v = view {
                                JLToast.makeText("登陆成功 o(*≧▽≦)ツ").show()
                                v.navigationController?.popViewControllerAnimated(true)
                            }
                        } else {
                            JLToast.makeText("用户名或密码错误，请修改后再试一次 ╮(╯_╰)╭").show()
                        }
                    }
                case .Failure(_):
                    TDLoadingIndicatorView.hide()
                    JLToast.makeText("网络出现故障，请稍后重试 Σ(°△°|||)︴").show()
                }
        }
    }
    
    func logout() {
        let hasLoginKey = UserDefaults.standard.bool(forKey: "hasLoginKey")
        if hasLoginKey {
            UserDefaults.standard.set(false, forKey: "hasLoginKey")
            HelpersMethond.tdKeychainWrapper.mySetObject("", forKey: kSecValueData)
            HelpersMethond.tdKeychainWrapper.writeToKeychain()
        }
    }
    
    func registerUser(_ view:UIViewController, username:String, email:String, password:String, phone:String) {
        let baseURLWithVersion = TDResource.sharedInstance.baseURLWithVersion
        let urlString = baseURLWithVersion + TDResource.ResourcePath.users.description
        let headers = [
            "Content-Type": "application/json"
        ]
        let parameters = [
            "username": username,
            "hashpw": password,
            "phone": phone,
            "email": email
        ]
        TDLoadingIndicatorView.show()
        Alamofire.request(.POST, urlString,parameters: parameters, encoding: .JSON, headers: headers)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                switch response.result {
                case .Success:
                    TDLoadingIndicatorView.hide()
                    if let value = response.result.value {
                        let json = JSON(value)
                        if json["_status"].string == "OK" {
                            JLToast.makeText("注册成功 o(*≧▽≦)ツ").show()
                            view.navigationController?.popViewControllerAnimated(true)
                        } else {
                            JLToast.makeText("用户名已存在，请修改后再试一次 ╮(╯_╰)╭").show()
                        }
                    }
                case .Failure(_):
                    TDLoadingIndicatorView.hide()
                    JLToast.makeText("网络出现故障，请稍后重试 Σ(°△°|||)︴").show()
                }
        }
    }
    
    func resetViewControllers(_ vc: UIViewController) {
        let diaryNavigationViewController = UIStoryboard(name: "Main", bundle: Bundle.mainBundle()).instantiateViewControllerWithIdentifier("diaryNavigationViewController")
        let positionNavigationViewController = UIStoryboard(name: "Main", bundle: Bundle.mainBundle()).instantiateViewControllerWithIdentifier("positionNavigationViewController")
        let tradeNavigationViewController = UIStoryboard(name: "Main", bundle: Bundle.mainBundle()).instantiateViewControllerWithIdentifier("tradeNavigationController") as! UINavigationController
        
        let portfolioTradeViewCOntroller = UIStoryboard(name: "Main", bundle: Bundle.mainBundle()).instantiateViewControllerWithIdentifier("TDPortfolioTradeViewController")
        tradeNavigationViewController.setViewControllers([portfolioTradeViewCOntroller], animated: false)
        
        var viewControllers = vc.tabBarController!.viewControllers!
        
        viewControllers[0] = diaryNavigationViewController
        viewControllers[1] = positionNavigationViewController
        viewControllers[2] = tradeNavigationViewController
        vc.tabBarController?.setViewControllers(viewControllers, animated: false)
    }
    
}
