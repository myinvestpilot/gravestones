//
//  TDPortfolio.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/5.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON
import Alamofire

class TDPortfolio: Object {
    dynamic var id = ""
    dynamic var name = ""
    dynamic var tradeTotalCount: Double = 0
    dynamic var winRatio: Double = 0
    dynamic var retreatRange: Double = 0
    dynamic var position: Double = 0
    dynamic var positionDate = Date()
    dynamic var returnRatio: Double = 0
    dynamic var profitLossMonthRatio: Double = 0
    dynamic var createdDate = Date()
    dynamic var beginMonthMoney: Double = 0
    dynamic var marketValue: Double = 0
    dynamic var biggestRetreatDay: Double = 0
    dynamic var syncTime = Date()
    dynamic var currentDate = Date()
    dynamic var currentAmount: Double = 0
    dynamic var profitLossRatio: Double = 0
    dynamic var currentNet: Double = 0
    dynamic var initialMoney: Double = 0
    dynamic var averagePositionDay: Double = 0
    dynamic var tradeStyle: Double = 0
    dynamic var createdNet: Double = 0
    dynamic var tradeTotalDay: Double = 0
    dynamic var riskRatio: Double = 0
    dynamic var beginAmount: Double = 0
    dynamic var returnRatioYear: Double = 0
    dynamic var tradeCountRatio: Double = 0
    dynamic var isPublic = false
    dynamic var riskMoney: Double = 0
    dynamic var biggestRetreatRange: Double = 0
    dynamic var beginMonthNet: Double = 0
    dynamic var userId = ""
    dynamic var floatingProfitLoss: Double = 0
    dynamic var calDate = Date()
    dynamic var etag = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    class func portfolio(_ json: NSDictionary) -> TDPortfolio? {
        let portfolio = TDPortfolio()
        
        if let id = json["_id"] as? String {
            portfolio.id = id
        }
        
        if let name = json["name"] as? String {
            portfolio.name = name
        }
        
        if let tradeTotalCount = json["portfolio_trade_total_count"] as? Double {
            portfolio.tradeTotalCount = tradeTotalCount
        }
        
        if let winRatio = json["portfolio_win_ratio"] as? Double {
            portfolio.winRatio = winRatio
        }
        
        if let retreatRange = json["portfolio_retreat_range"] as? Double {
            portfolio.retreatRange = retreatRange
        }
        
        if let position = json["portfolio_position"] as? Double {
            portfolio.position = position
        }
        
        if let positionDate = json["portfolio_position_date"] as? String {
            if let date = Utils.mongodbDateFormatter(positionDate) {
                portfolio.positionDate = date
            }
        }
        
        if let returnRatio = json["portfolio_return_ratio"] as? Double {
            portfolio.returnRatio = returnRatio
        }
        
        if let profitLossMonthRatio = json["portfolio_profit_loss_month_ratio"] as? Double {
            portfolio.profitLossMonthRatio = profitLossMonthRatio
        }
        
        if let createdDate = json["portfolio_created_date"] as? String {
            if let date = Utils.mongodbDateFormatter(createdDate) {
                portfolio.createdDate = date
            }
        }
        
        if let beginMonthMoney = json["portfolio_begin_month_money"] as? Double {
            portfolio.beginMonthMoney = beginMonthMoney
        }
        
        if let marketValue = json["portfolio_market_value"] as? Double {
            portfolio.marketValue = marketValue
        }
        
        if let biggestRetreatDay = json["portfolio_biggest_retreat_day"] as? Double {
            portfolio.biggestRetreatDay = biggestRetreatDay
        }
        
        if let syncTime = json["portfolio_sync_time"] as? String {
            if let date = Utils.mongodbDateFormatter(syncTime) {
                portfolio.syncTime = date
            }
        }
        
        if let currentDate = json["portfolio_current_date"] as? String {
            if let date = Utils.mongodbDateFormatter(currentDate) {
                portfolio.currentDate = date
            }
        }
        
        if let currentAmount = json["portfolio_current_amount"] as? Double {
            portfolio.currentAmount = currentAmount
        }
        
        if let profitLossRatio = json["portfolio_profit_loss_ratio"] as? Double {
            portfolio.profitLossRatio = profitLossRatio
        }
        
        if let currentNet = json["portfolio_current_net"] as? Double {
            portfolio.currentNet = currentNet
        }
        
        if let initialMoney = json["initial_money"] as? Double {
            portfolio.initialMoney = initialMoney
        }
        
        if let averagePositionDay = json["portfolio_average_position_day"] as? Double {
            portfolio.averagePositionDay = averagePositionDay
        }
        
        if let tradeStyle = json["portfolio_trade_style"] as? Double {
            portfolio.tradeStyle = tradeStyle
        }
        
        if let createdNet = json["portfolio_created_net"] as? Double {
            portfolio.createdNet = createdNet
        }
        
        if let tradeTotalDay = json["portfolio_trade_total_day"] as? Double {
            portfolio.tradeTotalDay = tradeTotalDay
        }
        
        if let riskRatio = json["portfolio_risk_ratio"] as? Double {
            portfolio.riskRatio = riskRatio
        }
        
        if let beginAmount = json["portfolio_begin_amount"] as? Double {
            portfolio.beginAmount = beginAmount
        }
        
        if let returnRatioYear = json["portfolio_return_ratio_year"] as? Double {
            portfolio.returnRatioYear = returnRatioYear
        }
        
        if let tradeCountRatio = json["portfolio_trade_count_ratio"] as? Double {
            portfolio.tradeCountRatio = tradeCountRatio
        }
        
        if let isPublic = json["is_public"] as? Bool {
            portfolio.isPublic = isPublic
        }
        
        if let riskMoney = json["portfolio_risk_money"] as? Double {
            portfolio.riskMoney = riskMoney
        }
        
        if let biggestRetreatRange = json["portfolio_biggest_retreat_range"] as? Double {
            portfolio.biggestRetreatRange = biggestRetreatRange
        }
        
        if let beginMonthNet = json["portfolio_begin_month_net"] as? Double {
            portfolio.beginMonthNet = beginMonthNet
        }
        
        if let userId = json["__user_id__"] as? String {
            portfolio.userId = userId
        }
        
        if let etag = json["_etag"] as? String {
            portfolio.etag = etag
        }
        
        if let floatingProfitLoss = json["portfolio_floating_profit_loss"] as? Double {
            portfolio.floatingProfitLoss = floatingProfitLoss
        }
        
        if let calDate = json["cal_date"] as? String {
            if let date = Utils.mongodbDateFormatter(calDate) {
                portfolio.calDate = date
            }
        }
        
        return portfolio
    }
    
    class func portfolioById(withUserId userId: String, withPortfolioId portfolioId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rPortfolioWithUserById(userId: userId, portfolioId: portfolioId))
            .responseObject { response in
                completionHandler(response.result)
            }
    }
    
    class func portfoliosWithUser(withUserId userId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rPortfoliosWithUser(userId: userId))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func dPortfolioById(withUserId userId: String, withPortfolioId portfolioId: String, withEtag etag: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.dPortfolioWithUserById(userId: userId, portfolioId: portfolioId, etag: etag))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
}



