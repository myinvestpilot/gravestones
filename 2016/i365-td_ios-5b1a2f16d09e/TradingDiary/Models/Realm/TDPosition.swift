//
//  TDPosition.swift
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

class TDPosition: Object, Mappable {
    dynamic var id = ""
    dynamic var code: String = ""
    dynamic var name: String = ""
    dynamic var price: Double = 0.0
    dynamic var stopPrice: Double = 0.0
    dynamic var costPrice: Double = 0.0
    dynamic var marketValue: Double = 0.0
    dynamic var positionRatio: Double = 0.0
    dynamic var isShouldSale: Bool = false
    dynamic var amount: Double = 0.0
    dynamic var riskId: String = ""
    dynamic var profitOrLoss: Double = 0.0
    dynamic var profitOrLossRatio: Double = 0.0
    dynamic var portfolios: String = ""
    dynamic var userId: String = ""
    dynamic var created = Date()
    dynamic var updated = Date()
    dynamic var etag: String = ""
    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func mapping(_ map: Map) {
        id <- map["_id"]
        code <- map["code"]
        name <- map["name"]
        price <- map["price"]
        stopPrice <- map["stop_price"]
        costPrice <- map["cost_price"]
        marketValue <- map["market_value"]
        positionRatio <- map["position_ratio"]
        isShouldSale <- map["is_should_sale"]
        amount <- map["amount"]
        riskId <- map["risk_id"]
        profitOrLoss <- map["profit_or_loss"]
        profitOrLossRatio <- map["profit_or_loss_ratio"]
        portfolios <- map["portfolios"]
        userId <- map["__user_id__"]
        created <- (map["_created"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        updated <- (map["_updated"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        etag <- map["_etag"]
    }
    
    class func getPositionsWithPortfolio(withPortfolioId portfolioId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rPositionsWithPortfolio(portfolioId: portfolioId))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
}
