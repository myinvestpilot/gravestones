//
//  TDRiskManager.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/3.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON
import Alamofire
import ObjectMapper

var portfolioId: String?

class TDRiskBuy: Object, Mappable {
    dynamic var id: String = ""
    dynamic var code: String = ""
    dynamic var stopPrice: Double = 0.0
    dynamic var targetPrice: Double = 0.0
    dynamic var amount: Double = 0.0
    dynamic var tradeBuyDate = Date()
    dynamic var tradeBuyPrice: Double = 0.0
    dynamic var tradeBuyComment: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init?(map: Map) {
        self.init()
        id = portfolioId ?? NSDate.timeIntervalSinceReferenceDate.description
    }
    
    func mapping(map: Map) {
        code <- map["code"]
        stopPrice <- map["stop_price"]
        targetPrice <- map["target_price"]
        amount <- map["amount"]
        tradeBuyDate <- (map["trade_buy_date"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String(describing: $0) } }))
        tradeBuyPrice <- map["trade_buy_price"]
        tradeBuyComment <- map["trade_buy_comment"]
    }
    
}

class TDRiskSale: Object, Mappable {
    dynamic var id: String = ""
    dynamic var tradeSalePrice: Double = 0.0
    dynamic var tradeSaleDate = Date()
    dynamic var tradeSaleComment: String = ""
    
    required convenience init?(map: Map) {
        self.init()
        id = portfolioId ?? NSDate.timeIntervalSinceReferenceDate.description
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func mapping(map: Map) {
        tradeSalePrice <- map["trade_sale_price"]
        tradeSaleDate <- (map["trade_sale_date"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String(describing: $0) } }))
        tradeSaleComment <- map["trade_sale_comment"]
    }
}

class TDRiskBuyDp: Object, Mappable {
    dynamic var id: String = ""
    dynamic var costPrice: Double = 0.0
    dynamic var marketValue: Double = 0.0
    dynamic var positionRatio: Double = 0.0
    dynamic var name: String = ""
    dynamic var price: Double = 0.0
    dynamic var floatingProfitLoss: Double = 0.0
    dynamic var riskAllMoney: Double = 0.0
    dynamic var isShouldSale: Bool = false
    dynamic var tradeBuyScore: Double = 0.0
    dynamic var riskCostMoney: Double = 0.0
    dynamic var riskRewardRatio: Double = 0.0
    dynamic var tradeBuyLowPrice: Double = 0.0
    dynamic var stopRatio: Double = 0.0
    dynamic var buyFeeCost: Double = 0.0
    dynamic var upBuyAmount: Double = 0.0
    dynamic var tradeBuyHighPrice: Double = 0.0
    dynamic var targetProfit: Double = 0.0
    dynamic var floatingProfitLossRatio: Double = 0.0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init?(map: Map) {
        self.init()
        id = portfolioId ?? NSDate.timeIntervalSinceReferenceDate.description
    }
    
    func mapping(map: Map) {
        costPrice <- map["cost_price"]
        marketValue <- map["market_value"]
        positionRatio <- map["position_ratio"]
        name <- map["name"]
        price <- map["price"]
        floatingProfitLoss <- map["floating_profit_loss"]
        riskAllMoney <- map["risk_all_money"]
        isShouldSale <- map["is_should_sale"]
        tradeBuyScore <- map["trade_buy_score"]
        riskCostMoney <- map["risk_cost_money"]
        riskRewardRatio <- map["risk_reward_ratio"]
        tradeBuyLowPrice <- map["trade_buy_low_price"]
        stopRatio <- map["stop_ratio"]
        buyFeeCost <- map["buy_fee_cost"]
        upBuyAmount <- map["up_buy_amount"]
        tradeBuyHighPrice <- map["trade_buy_high_price"]
        targetProfit <- map["target_profit"]
        floatingProfitLossRatio <- map["floating_profit_loss_ratio"]
    }
}

class TDRiskBuySaleDp: Object, Mappable {
    dynamic var id: String = ""
    dynamic var tradeSaleScore: Double = 0.0
    dynamic var holdTradeDay: Double = 0.0
    dynamic var saleFeeCost: Double = 0.0
    dynamic var tradeSaleHighPrice: Double = 0.0
    dynamic var tradeProfitRatio: Double = 0.0
    dynamic var tradeSaleLowPrice: Double = 0.0
    dynamic var tradeScore: Double = 0.0
    dynamic var tradeProfit: Double = 0.0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init?(map: Map) {
        self.init()
        id = portfolioId ?? NSDate.timeIntervalSinceReferenceDate.description
    }
    
    func mapping(map: Map) {
        tradeSaleScore <- map["trade_sale_score"]
        holdTradeDay <- map["hold_trade_day"]
        saleFeeCost <- map["sale_fee_cost"]
        tradeSaleHighPrice <- map["trade_sale_high_price"]
        tradeProfitRatio <- map["trade_profit_ratio"]
        tradeSaleLowPrice <- map["trade_sale_low_price"]
        tradeScore <- map["trade_score"]
        tradeProfit <- map["trade_profit"]
    }
}

class TDRiskManager: Object, Mappable {
    dynamic var id: String = ""
    dynamic var portfolios: String = ""
    dynamic var userId: String = ""
    dynamic var isHold: Bool = false
    dynamic var created = Date()
    dynamic var updated = Date()
    dynamic var etag: String = ""
    dynamic var buy: TDRiskBuy?
    /*
     "buy": {
         "code": "000001",
         "stop_price": 12.8,
         "target_price": 20,
         "amount": 1000,
         "trade_buy_date": "Thu, 10 Mar 2016 02:26:16 GMT",
         "trade_buy_price": 13,
         "trade_buy_comment": "买入博涨"
     }
     */
    dynamic var buyDp: TDRiskBuyDp?
    /*
     "buy_dp": {
         "cost_price": 13,
         "market_value": 10260,
         "position_ratio": 0.00171,
         "name": "平安银行",
         "price": 10.26,
         "floating_profit_loss": -2740,
         "risk_all_money": 6000000,
         "is_should_sale": false,
         "trade_buy_score": -10.159999999999997,
         "risk_cost_money": 199.9999999999993,
         "risk_reward_ratio": 35.00000000000013,
         "trade_buy_low_price": 10.21,
         "stop_ratio": 0.01538461538461533,
         "buy_fee_cost": 5,
         "up_buy_amount": 600000.0000000021,
         "trade_buy_high_price": 10.46,
         "target_profit": 7000,
         "floating_profit_loss_ratio": -0.21076923076923076
     }
     */
    dynamic var sale: TDRiskSale?
    /*
     "sale": {
         "trade_sale_comment": "卖出获利",
         "trade_sale_date": "Sat, 02 Apr 2016 10:29:13 GMT",
         "trade_sale_price": 20
     }
     */
    dynamic var buySaleDp: TDRiskBuySaleDp?
    /*
     "buy_sale_dp": {
         "trade_sale_score": 39.16,
         "hold_trade_day": 17,
         "sale_fee_cost": 26,
         "trade_sale_high_price": 10.46,
         "trade_profit_ratio": 0.5360769230769231,
         "trade_sale_low_price": 10.21,
         "trade_score": 0.9955714285714286,
         "trade_profit": 6969
     }
     */
    
    required convenience init?(map: Map) {
        self.init()
        portfolioId <- map["_id"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func mapping(map: Map) {
        id <- map["_id"]
        portfolios <- map["portfolios"]
        userId <- map["__user_id__"]
        isHold <- map["is_hold"]
        created <- (map["_created"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String(describing: $0) } }))
        updated <- (map["_updated"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String(describing: $0) } }))
        etag <- map["_etag"]
        buy <- map["buy"]
        buyDp <- map["buy_dp"]
        sale <- map["sale"]
        buySaleDp <- map["buy_sale_dp"]
    }
    
    class func getRiskById(withPortfolioId portfolioId: String, withRiskId riskid: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rRiskManagerWithPortfolioById(portfolioId: portfolioId, riskId: riskid))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func getRisksWithPortfolio(withPortfolioId portfolioId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rRiskManagersWithPortfolio(portfolioId: portfolioId))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func createRiskManagerWithPortfolioId(withPortfolioId portfolioId: String, riskInfo :[String: AnyObject],completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.cRiskManagerWithPortfolio(portfolioId: portfolioId, riskInfo))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    // - TODO: add etag
    class func updateRiskManagerWithPortfolioId(withPortfolioId portfolioId: String, withRiskId riskId: String, withEtag etag: String, riskInfo :[String: AnyObject],completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.uRiskManagerWithPortfolioById(portfolioId: portfolioId, riskId: riskId, riskInfo, etag: etag))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func deleteRiskManagerWithPortfolioId(withPortfolioId portfolioId: String, withRiskId riskId: String, etag: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.dRiskManagerWithPortfolioById(portfolioId: portfolioId, riskId: riskId, etag: etag))
            .responseObject { response in
                completionHandler(response.result)
        }
    }

}
