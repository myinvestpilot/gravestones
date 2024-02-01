//
//  TDTradeHistory.swift
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

class TDTradeHistory: Object, Mappable {
    dynamic var id = ""
    dynamic var code: String = ""
    dynamic var name: String = ""
    dynamic var tradeMoney: Double = 0.0
    dynamic var tradeAmount: Double = 0.0
    dynamic var buyOrSale: Bool = false
    dynamic var riskId: String = ""
    dynamic var tradeCost: Double = 0.0
    dynamic var tradeDate = Date()
    dynamic var tradePrice: Double = 0.0
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
        code <- map["code"]
        name <- map["name"]
        tradeMoney <- map["tradeMoney"]
        tradeAmount <- map["tradeAmount"]
        buyOrSale <- map["buyOrSale"]
        riskId <- map["riskId"]
        tradeCost <- map["tradeCost"]
        tradeDate <- (map["tradeDate"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        tradePrice <- map["tradePrice"]
        portfolios <- map["portfolios"]
        userId <- map["__user_id__"]
        created <- (map["_created"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        updated <- (map["_updated"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        etag <- map["_etag"]
    }
    
    class func getTradeHistorysWithPortfolio(withPortfolioId portfolioId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rTradeHistorysWithPortfolio(portfolioId: portfolioId))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
}
