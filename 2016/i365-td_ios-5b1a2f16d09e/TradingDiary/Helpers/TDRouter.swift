//
//  TDRouter.swift
//  TradingDiary
//  API Parameter Abstraction
//  Created by Dawei Ma on 16/4/25.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation
import Alamofire

public enum TDRouter: URLRequestConvertible {
    case user
    case cUser([String: AnyObject])
    case rUserById(userId: String)
    case uUserById(userId: String, [String: AnyObject], etag: String)
    case token([String: AnyObject])
    case rPortfoliosWithUser(userId: String)
    case cPortfolioWithUser(userId: String, [String: AnyObject])
    case rPortfolioWithUserById(userId: String, portfolioId: String)
    case uPortfolioWithUserById(userId: String, portfolioId: String, [String: AnyObject], etag: String)
    case dPortfolioWithUserById(userId: String, portfolioId: String, etag: String)
    case rPositionHistorysWithPortfolio(portfolioId: String)
    case rNetAssetValuesWithPortfolio(portfolioId: String)
    case rPositionsWithPortfolio(portfolioId: String)
    case rTradeHistorysWithPortfolio(portfolioId: String)
    case rCashflowHistorysWithPortfolio(portfolioId: String)
    case cCashflowHistoryWithPortfolio(portfolioId: String, [String: AnyObject])
    case rCashflowHistoryWithPortfolioById(portfolioId: String, cashId: String)
    case uCashflowHistoryWithPortfolioById(portfolioId: String, cashId: String, [String: AnyObject], etag: String)
    case dCashflowHistoryWithPortfolioById(portfolioId: String, cashId: String, etag: String)
    case rRiskManagersWithPortfolio(portfolioId: String)
    case cRiskManagerWithPortfolio(portfolioId: String, [String: AnyObject])
    case rRiskManagerWithPortfolioById(portfolioId: String, riskId: String)
    case uRiskManagerWithPortfolioById(portfolioId: String, riskId: String, [String: AnyObject], etag: String)
    case dRiskManagerWithPortfolioById(portfolioId: String, riskId: String, etag: String)
    case upload([String: AnyObject])
    
    public var URLRequest: NSMutableURLRequest {
        let result: (path: String, method: Alamofire.Method) = {
            switch self {
            case .User:
                return (TDResource.ResourcePath.User.description, .GET)
            case .cUser:
                return (TDResource.ResourcePath.Users.description, .POST)
            case .rUserById(let id):
                return (TDResource.ResourcePath.UsersId(userId: id).description, .GET)
            case .uUserById(let id, _, _):
                return (TDResource.ResourcePath.UsersId(userId: id).description, .PATCH)
            case .Token(_):
                return (TDResource.ResourcePath.Token.description, .POST)
            case .rPortfoliosWithUser(let id):
                return (TDResource.ResourcePath.Portfolios(userId: id).description, .GET)
            case .cPortfolioWithUser(let id, _):
                return (TDResource.ResourcePath.Portfolios(userId: id).description, .POST)
            case .rPortfolioWithUserById(let userId, let portfolioId):
                return (TDResource.ResourcePath.PortfoliosId(userId: userId, portfolioId: portfolioId).description, .GET)
            case .uPortfolioWithUserById(let userId, let portfolioId, _, _):
                return (TDResource.ResourcePath.PortfoliosId(userId: userId, portfolioId: portfolioId).description, .PATCH)
            case .dPortfolioWithUserById(let userId, let portfolioId, _):
                return (TDResource.ResourcePath.PortfoliosId(userId: userId, portfolioId: portfolioId).description, .DELETE)
            case .rPositionHistorysWithPortfolio(let portfolioId):
                return (TDResource.ResourcePath.PositionHistory(portfolioId: portfolioId).description, .GET)
            case .rNetAssetValuesWithPortfolio(let portfolioId):
                return (TDResource.ResourcePath.NetAssetValue(portfolioId: portfolioId).description, .GET)
            case .rPositionsWithPortfolio(let portfolioId):
                return (TDResource.ResourcePath.Position(portfolioId: portfolioId).description, .GET)
            case .rTradeHistorysWithPortfolio(let portfolioId):
                return (TDResource.ResourcePath.TradeHistory(portfolioId: portfolioId).description, .GET)
            case .rCashflowHistorysWithPortfolio(let portfolioId):
                return (TDResource.ResourcePath.CashflowHistory(portfolioId: portfolioId).description, .GET)
            case .cCashflowHistoryWithPortfolio(let portfolioId, _):
                return (TDResource.ResourcePath.CashflowHistory(portfolioId: portfolioId).description, .POST)
            case .rCashflowHistoryWithPortfolioById(let portfolioId, let cashId):
                return (TDResource.ResourcePath.CashflowHistoryId(portfolioId: portfolioId, cashId: cashId).description, .GET)
            case .uCashflowHistoryWithPortfolioById(let portfolioId, let cashId, _, _):
                return (TDResource.ResourcePath.CashflowHistoryId(portfolioId: portfolioId, cashId: cashId).description, .PATCH)
            case .dCashflowHistoryWithPortfolioById(let portfolioId, let cashId, _):
                return (TDResource.ResourcePath.CashflowHistoryId(portfolioId: portfolioId, cashId: cashId).description, .DELETE)
            case .rRiskManagersWithPortfolio(let portfolioId):
                return (TDResource.ResourcePath.RiskManager(portfolioId: portfolioId).description, .GET)
            case .cRiskManagerWithPortfolio(let portfolioId, _):
                return (TDResource.ResourcePath.RiskManager(portfolioId: portfolioId).description, .POST)
            case .rRiskManagerWithPortfolioById(let portfolioId, let riskId):
                return (TDResource.ResourcePath.RiskManagerId(portfolioId: portfolioId, riskId: riskId).description, .GET)
            case .uRiskManagerWithPortfolioById(let portfolioId, let riskId, _, _):
                return (TDResource.ResourcePath.RiskManagerId(portfolioId: portfolioId, riskId: riskId).description, .PATCH)
            case .dRiskManagerWithPortfolioById(let portfolioId, let riskId, _):
                return (TDResource.ResourcePath.RiskManagerId(portfolioId: portfolioId, riskId: riskId).description, .DELETE)
            case .Upload(_):
                return (TDResource.ResourcePath.Upload.description, .POST)
            }
        }()
        var URL: Foundation.URL {
            switch self {
            case .token:
                return Foundation.URL(string: TDResource.sharedInstance.baseURL)!
            case .user:
                return Foundation.URL(string: TDResource.sharedInstance.baseURL)!
            default:
                return Foundation.URL(string: TDResource.sharedInstance.baseURLWithVersion)!
            }
        }
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(result.path))
        mutableURLRequest.HTTPMethod = result.method.rawValue
        if let token = HelpersMethond.sharedInstance.getToken() {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        switch self {
        case .cUser(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .uUserById(_, let parameters, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .cPortfolioWithUser(_, let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .uPortfolioWithUserById(_, _, let parameters, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .dPortfolioWithUserById(_, _, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return mutableURLRequest
        case .cCashflowHistoryWithPortfolio(_, let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .uCashflowHistoryWithPortfolioById(_, _, let parameters, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .dCashflowHistoryWithPortfolioById(_, _, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return mutableURLRequest
        case .cRiskManagerWithPortfolio(_, let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .uRiskManagerWithPortfolioById(_, _, let parameters, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .dRiskManagerWithPortfolioById(_, _, let etag):
            mutableURLRequest.setValue("\(etag)", forHTTPHeaderField: "If-Match")
            return mutableURLRequest
        case .token(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .upload(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        default:
            return mutableURLRequest
        }
    }
}
