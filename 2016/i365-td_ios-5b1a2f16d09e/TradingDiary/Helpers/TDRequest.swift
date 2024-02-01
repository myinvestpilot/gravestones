//
//  TDRequest.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/26.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension Alamofire.Request {
    public func responseObject(_ completionHandler: (Response<JSON, NSError>) -> Void) -> Self {
        let responseSerializer = ResponseSerializer<JSON, NSError> { request, response, data, error in
            guard error == nil else {
                return .Failure(error!)
            }
            guard let responseData = data else {
                let failureReason = "Array could not be serialized because input data was nil."
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            
            let JSONResponseSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, responseData, error)
            
            if result.isSuccess {
                if let value = result.value {
                    let json = SwiftyJSON.JSON(value)
                    return .Success(json)
                }
            }
            
            let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: "JSON could not be converted to object")
            return .Failure(error)
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}
