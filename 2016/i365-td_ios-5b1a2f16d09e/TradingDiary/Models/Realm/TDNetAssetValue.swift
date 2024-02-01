//
//  TDNetAssetValue.swift
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

class TDNetAssetValue: Object, Mappable {
    dynamic var id = ""
    dynamic var portfolioNetRetreatDay: Double = 0.0
    dynamic var portfolioPositionValue: Double = 0.0
    dynamic var portfolioBuyCost: Double = 0.0
    dynamic var portfolioNetValue: Double = 0.0
    dynamic var portfolioTradCount: Double = 0.0
    dynamic var portfolioMarketValue: Double = 0.0
    dynamic var tradeDate = Date()
    dynamic var portfolioAvaliableCash: Double = 0.0
    dynamic var portfolioDayChange: Double = 0.0
    dynamic var portfolioAmountChange: Double = 0.0
    dynamic var portfolioCashTransfer: Double = 0.0
    dynamic var portfolioNetRetreatChange: Double = 0.0
    dynamic var portfolioNetAmount: Double = 0.0
    dynamic var hs300IndexNet: Double = 0.0
    dynamic var hs300Index: Double = 0.0
    dynamic var zz500IndexNet: Double = 0.0
    dynamic var zz500Index: Double = 0.0
    dynamic var portfolios: String = ""
    dynamic var userId: String = ""
    dynamic var created = Date()
    dynamic var updated = Date()
    dynamic var etag: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    func mapping(_ map: Map) {
        id <- map["_id"]
        portfolioNetRetreatDay <- map["portfolio_net_retreat_day"]
        portfolioPositionValue <- map["portfolio_position_value"]
        portfolioBuyCost <- map["portfolio_buy_cost"]
        portfolioNetValue <- map["portfolio_net_value"]
        portfolioTradCount <- map["portfolio_trad_count"]
        portfolioMarketValue <- map["portfolio_market_value"]
        tradeDate <- (map["trade_date"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        portfolioAvaliableCash <- map["portfolio_avaliable_cash"]
        portfolioDayChange <- map["portfolio_day_change"]
        portfolioAmountChange <- map["portfolio_amount_change"]
        portfolioCashTransfer <- map["portfolio_cash_transfer"]
        portfolioNetRetreatChange <- map["portfolio_net_retreat_change"]
        portfolioNetAmount <- map["portfolio_net_amount"]
        hs300IndexNet <- map["hs300_index_net"]
        hs300Index <- map["hs300_index"]
        zz500IndexNet <- map["zz500_index_net"]
        zz500Index <- map["zz500_index"]
        portfolios <- map["portfolios"]
        userId <- map["__user_id__"]
        created <- (map["_created"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        updated <- (map["_updated"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        etag <- map["_etag"]
    }
    
    class func getNetAssetValuesWithPortfolio(withPortfolioId portfolioId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rNetAssetValuesWithPortfolio(portfolioId: portfolioId))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
}
