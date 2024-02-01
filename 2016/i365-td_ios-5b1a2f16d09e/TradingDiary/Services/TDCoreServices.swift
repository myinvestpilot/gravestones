//
//  CoreServices.swift
//  TradingDiary
//  Core Services
//  Created by Dawei Ma on 16/4/1.
//  Copyright © 2016年 i365.tech. All rights reserved.
//
import Foundation
import Alamofire
import SwiftyJSON
import RealmSwift
import Toaster
import ObjectMapper

public final class CoreServices: TDServiceProtocol {
    
    fileprivate static let _sharedInstance = CoreServices()
    
    // Get the default Realm
    let aRealm = try! Realm()
    
    // Must login to get the CoreServices Object
    static func getInstance() -> CoreServices? {
        if HelpersMethond.sharedInstance.checkLogin() {
            return _sharedInstance
        }
        return nil
    }
    
    fileprivate init() {
        // Register Obsever to portfolios db update
        NotificationCenter.default.addObserver(self, selector: #selector(CoreServices.backgroudUpdateDBTask), name: NSNotification.Name(rawValue: "ResetPortfolios"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CoreServices.getPortfoliosByNotification), name: NSNotification.Name(rawValue: "GetPortfolios"), object: nil)
    }
    
    deinit {
        // Remove Obsever when deinit
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ResetPortfolios"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "GetPortfolios"), object: nil)
    }
    
    @objc fileprivate func backgroudUpdateDBTask() {
        backgroundThread(background: {
            let realm = try! Realm()
            let portfolios = realm.objects(TDPortfolio)
            for portfolio in portfolios {
                self.getNetAssetsWithPortfolio(withPortfolioId: portfolio.id)
                self.getRiskWithPortfolio(withPortfolioId: portfolio.id)
                self.getCashFlowWithPortfolio(withPortfolioId: portfolio.id)
                self.getPositionWithPortfolio(withPortfolioId: portfolio.id)
                self.getTradeHistoryWithPortfolio(withPortfolioId: portfolio.id)
            }
        })
    }
    
    @objc fileprivate func getPortfoliosByNotification() {
        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            self.getPortfoliosWithUser(withUserId: userId)
        }
    }
    
    func wrapHttpHeader() -> [String: String]? {
        let authorizationType = TDResource.sharedInstance.authorization
        let accessToken = HelpersMethond.sharedInstance.getToken()
        if let token = accessToken {
            let headers = [
                "Authorization": authorizationType! + " " + token
            ]
            return headers
        }
        return nil
    }
    
    // MARK: - User Manager
    func updateUserProfile(_ userId: String, userInfo :[String: AnyObject], completionHandler: (Result<JSON, NSError>) -> Void) {
        let etag = UserDefaults.standard.dictionary(forKey: "user_info")!["_etag"] as! String
        request(TDRouter.uUserById(userId: userId, userInfo, etag: etag))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    // MARK: - Portfolio Manager
    func createPortfolio(_ userId: String, portfolioInfo :[String: AnyObject], completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.cPortfolioWithUser(userId: userId, portfolioInfo))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    func getPortfolioById(withUserId userId: String, withPortfolioId portfolioId: String) {
        TDPortfolio.portfolioById(withUserId: userId, withPortfolioId: portfolioId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let portfolioJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if portfolioJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("网络故障，请稍后再试ヾ(=^▽^=)ノ").show()
                return
            }
            if let portfolio = portfolioJSON.dictionaryObject {
                // begin write data
                self.aRealm.beginWrite()
                if let item = TDPortfolio.portfolio(portfolio) {
                    self.aRealm.add(item, update: true)
                }
                try! self.aRealm.commitWrite()
            }
        }
    }
    
    func getPortfoliosWithUser(withUserId userId: String) {
        TDPortfolio.portfoliosWithUser(withUserId: userId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let portfoliosJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if portfoliosJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权失效，请重新登陆！").show()
                return
            }
            
            if portfoliosJSON["_items"].count > 0 {
                self.aRealm.beginWrite()
                // delete old data in realm
                self.aRealm.delete(self.aRealm.objects(TDPortfolio))
                // write data
                for (_, subJson):(String, JSON) in portfoliosJSON["_items"] {
                    if let item = TDPortfolio.portfolio(subJson.dictionaryObject!) {
                        self.aRealm.add(item, update: true)
                    }
                }
                try! self.aRealm.commitWrite()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("ResetPortfolios", object: nil)
            }
        }
    }
    
    // MARK: - Net Asset Manager
    func getNetAssetsWithPortfolio(withPortfolioId portfolioId: String) {
        TDNetAssetValue.getNetAssetValuesWithPortfolio(withPortfolioId: portfolioId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let aJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if aJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权失效，请重新登陆！").show()
                return
            }
            if aJSON["_items"].count > 0{
                self.aRealm.beginWrite()
                // delete old data in realm
                let predicate = NSPredicate(format: "portfolios = '\(portfolioId)'")
                self.aRealm.delete(self.aRealm.objects(TDNetAssetValue).filter(predicate))
                for (_, subJson):(String, JSON) in aJSON["_items"] {
                    if let item = Mapper<TDNetAssetValue>().map(subJson.description) {
                        self.aRealm.add(item, update: true)
                    }
                }
                try! self.aRealm.commitWrite()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("ResetNetAssets", object: nil)
            }
        }
    }
    
    // MARK: - Risk Manager
    func getRiskWithPortfolio(withPortfolioId portfolioId: String) {
        TDRiskManager.getRisksWithPortfolio(withPortfolioId: portfolioId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let aJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if aJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权失效，请重新登陆！").show()
                return
            }
            if aJSON["_items"].count > 0{
                self.aRealm.beginWrite()
                // delete old data in realm
                var predicate = NSPredicate(format: "portfolios = '\(portfolioId)'")
                self.aRealm.delete(self.aRealm.objects(TDRiskManager).filter(predicate))
                predicate = NSPredicate(format: "id = '\(portfolioId)'")
                self.aRealm.delete(self.aRealm.objects(TDRiskBuy).filter(predicate))
                self.aRealm.delete(self.aRealm.objects(TDRiskSale).filter(predicate))
                self.aRealm.delete(self.aRealm.objects(TDRiskBuyDp).filter(predicate))
                self.aRealm.delete(self.aRealm.objects(TDRiskBuySaleDp).filter(predicate))
                for (_, subJson):(String, JSON) in aJSON["_items"] {
                    if let item = Mapper<TDRiskManager>().map(subJson.description) {
                        self.aRealm.add(item, update: true)
                    }
                }
                try! self.aRealm.commitWrite()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("ResetRiskManager", object: nil)
            }
        }
    }
    
    func createRiskWithPortfolio(withPortfolioId portfolioId: String, withRiskInfo riskInfo: [String : AnyObject]) {
        
    }
    
    // MARK: - Cash Manager
    func getCashFlowWithPortfolio(withPortfolioId portfolioId: String) {
        TDCashFlow.getCashFlowsWithPortfolio(withPortfolioId: portfolioId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let aJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if aJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权失效，请重新登陆！").show()
                return
            }
            if aJSON["_items"].count > 0{
                self.aRealm.beginWrite()
                // delete old data in realm
                let predicate = NSPredicate(format: "portfolios = '\(portfolioId)'")
                self.aRealm.delete(self.aRealm.objects(TDCashFlow).filter(predicate))
                for (_, subJson):(String, JSON) in aJSON["_items"] {
                    if let item = Mapper<TDCashFlow>().map(subJson.description) {
                        self.aRealm.add(item, update: true)
                    }
                }
                try! self.aRealm.commitWrite()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("ResetCashFlow", object: nil)
            }
        }
    }
    
    // MARK: - Position Manager
    func getPositionWithPortfolio(withPortfolioId portfolioId: String) {
        TDPosition.getPositionsWithPortfolio(withPortfolioId: portfolioId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let aJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if aJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权失效，请重新登陆！").show()
                return
            }
            if aJSON["_items"].count > 0{
                self.aRealm.beginWrite()
                // delete old data in realm
                let predicate = NSPredicate(format: "portfolios = '\(portfolioId)'")
                self.aRealm.delete(self.aRealm.objects(TDPosition).filter(predicate))
                for (_, subJson):(String, JSON) in aJSON["_items"] {
                    if let item = Mapper<TDPosition>().map(subJson.description) {
                        self.aRealm.add(item, update: true)
                    }
                }
                try! self.aRealm.commitWrite()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("ResetPosition", object: nil)
            }
        }
    }
    
    // MARK: - Trade History Manager
    func getTradeHistoryWithPortfolio(withPortfolioId portfolioId: String) {
        TDTradeHistory.getTradeHistorysWithPortfolio(withPortfolioId: portfolioId) { result in
            guard result.error == nil else {
                JLToast.makeText("获取数据失败，请重试！").show()
                return
            }
            guard let aJSON = result.value else {
                JLToast.makeText("系统出错，请重试！").show()
                return
            }
            if aJSON.dictionaryValue["_status"] == "ERR" {
                JLToast.makeText("授权失效，请重新登陆！").show()
                return
            }
            if aJSON["_items"].count > 0{
                self.aRealm.beginWrite()
                // delete old data in realm
                let predicate = NSPredicate(format: "portfolios = '\(portfolioId)'")
                self.aRealm.delete(self.aRealm.objects(TDTradeHistory).filter(predicate))
                for (_, subJson):(String, JSON) in aJSON["_items"] {
                    if let item = Mapper<TDTradeHistory>().map(subJson.description) {
                        self.aRealm.add(item, update: true)
                    }
                }
                try! self.aRealm.commitWrite()
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName("ResetTradeHistory", object: nil)
            }
        }
    }
    
    // MARK: - Diary Manager
    
}
