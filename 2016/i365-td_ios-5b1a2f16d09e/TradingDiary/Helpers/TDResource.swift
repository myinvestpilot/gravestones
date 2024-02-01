//
//  TDResource.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/5.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation

public final class TDResource: NSObject {
    // singletons
    static let sharedInstance = TDResource()
    
    public enum ResourcePath {
        case user
        case users
        case usersId(userId: String)
        case token
        case portfolios(userId: String)
        case portfoliosId(userId: String, portfolioId: String)
        case positionHistory(portfolioId: String)
        case netAssetValue(portfolioId: String)
        case position(portfolioId: String)
        case tradeHistory(portfolioId: String)
        case cashflowHistory(portfolioId: String)
        case cashflowHistoryId(portfolioId: String, cashId: String)
        case riskManager(portfolioId: String)
        case riskManagerId(portfolioId: String, riskId: String)
        case upload
        
        var description: String {
            switch self {
            case .user: return "/user"
            case .users: return "/users"
            case .usersId(let id): return "/users/\(id)"
            case .token: return "/oauth/token"
            case .portfolios(let userId): return "/users/\(userId)/portfolios"
            case .portfoliosId(let userId, let portfolioId): return "/users/\(userId)/portfolios/\(portfolioId)"
            case .positionHistory(let portfolioId): return "/portfolios/\(portfolioId)/position_history/"
            case .netAssetValue(let portfolioId): return "/portfolios/\(portfolioId)/net_asset_value"
            case .position(let portfolioId): return "/portfolios/\(portfolioId)/position"
            case .tradeHistory(let portfolioId): return "/portfolios/\(portfolioId)/trade_history"
            case .cashflowHistory(let portfolioId): return "/portfolios/\(portfolioId)/cashflow_history"
            case .cashflowHistoryId(let portfolioId, let cashId): return "/portfolios/\(portfolioId)/cashflow_history/\(cashId)"
            case .riskManager(let portfolioId): return "/portfolios/\(portfolioId)/risk_manager"
            case .riskManagerId(let portfolioId, let riskId): return "/portfolios/\(portfolioId)/risk_manager/\(riskId)"
            case .upload: return "/upload"
            }
        }
        
    }
    
    let API_CONFIG_PLIST_NAME: String = String("api")
    var baseURL: String!
    var baseURLWithVersion: String!
    var clientID: String!
    var grantType: String!
    var authorization: String!
    
    fileprivate override init() {
        super.init()
        
        let apiDictionary = Utils.loadItems(nameOfPlist: API_CONFIG_PLIST_NAME, ofType: "plist")
        if let dictionary = apiDictionary {
            baseURL = dictionary.value(forKey: "baseURL") as? String
            baseURLWithVersion = dictionary.value(forKey: "baseURLWithVersion") as? String
            clientID = dictionary.value(forKey: "clientID") as? String
            grantType = dictionary.value(forKey: "grant_type") as? String
            authorization = dictionary.value(forKey: "Authorization") as? String
        }
        
    }
}
