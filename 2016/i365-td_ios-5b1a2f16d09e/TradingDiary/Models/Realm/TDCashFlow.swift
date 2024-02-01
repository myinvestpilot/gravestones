//
//  TDCashFlow.swift
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

class TDCashFlow: Object, Mappable {
    dynamic var id = ""
    dynamic var portfolioNet: Double = 0.0
    dynamic var transferMoney: Double = 0.0
    dynamic var transferDate = Date()
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
        portfolioNet <- map["portfolio_net"]
        transferMoney <- map["transfer_money"]
        transferDate <- (map["transfer_date"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        portfolios <- map["portfolios"]
        userId <- map["__user_id__"]
        created <- (map["_created"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        updated <- (map["_updated"], TransformOf<Date, String>(fromJSON: {Utils.mongodbDateFormatter($0)}, toJSON: { $0.map { String($0) } }))
        etag <- map["_etag"]
    }
    
    class func getCashFlowById(withPortfolioId portfolioId: String, withCashId cashid: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rCashflowHistoryWithPortfolioById(portfolioId: portfolioId, cashId: cashid))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func getCashFlowsWithPortfolio(withPortfolioId portfolioId: String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.rCashflowHistorysWithPortfolio(portfolioId: portfolioId))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func createCashHistoryWithPortfolioId(withPortfolioId portfolioId: String, cashInfo :[String: AnyObject], completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.cCashflowHistoryWithPortfolio(portfolioId: portfolioId, cashInfo))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    // - TODO: add etag
    class func updateCashHistoryWithPortfolioId(withPortfolioId portfolioId: String, withCashId cashId: String, cashInfo :[String: AnyObject],completionHandler: (Result<JSON, NSError>) -> Void) {
        let etag = ""
        request(TDRouter.uCashflowHistoryWithPortfolioById(portfolioId: portfolioId, cashId: cashId, cashInfo, etag: etag))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
    
    class func deleteCashHistoryWithPortfolioId(withPortfolioId portfolioId: String, cashId: String, etag : String, completionHandler: (Result<JSON, NSError>) -> Void) {
        request(TDRouter.dCashflowHistoryWithPortfolioById(portfolioId: portfolioId, cashId: cashId, etag: etag))
            .responseObject { response in
                completionHandler(response.result)
        }
    }
}
