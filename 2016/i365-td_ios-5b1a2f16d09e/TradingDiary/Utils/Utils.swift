//
//  Utils.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/1.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation

class Utils: NSObject {
    
    // MARK: - Util Methods
    static func pathForItems(nameOfPlist item: String?, ofType type: String?) -> String? {
        // Get plist file path
        return Bundle.main.path(forResource: item, ofType: type)
    }
    
    static func loadItems(nameOfPlist item: String?, ofType type: String?) -> NSDictionary? {
        // Load plist dictionary
        if let filePath = pathForItems(nameOfPlist: item, ofType: type), FileManager.default.fileExists(atPath: filePath) {
            let apiConfigDictionary = NSDictionary(contentsOf: URL(fileURLWithPath: filePath))
            if let dictionary = apiConfigDictionary {
                return dictionary
            }
        }
        return nil
    }
    
    static func mongodbDateFormatter(_ rawDate:String?) -> Date? {
        if let date = rawDate {
            // rfc1123 time format
            // Sat, 19 Mar 2016 19:14:08 GMT
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            formatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss 'GMT'"
            formatter.locale = Locale.init(identifier: "en_US")
            formatter.timeZone = TimeZone.init(abbreviation: "GMT")
            return formatter.date(from: date)
        }
        return nil
    }
    
}

extension Date {
    func dateToString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM-dd"
        return formatter.string(from: self)
    }
    
    func dateToRFC1123() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss 'GMT'"
        formatter.locale = Locale.init(identifier: "en_US")
        formatter.timeZone = TimeZone.init(abbreviation: "GMT")
        return formatter.string(from: self)
    }
}

extension String {
    func toDouble() -> Double? {
        return Double.init(self)
    }
}

extension Double {
    func toStringWithDecimal(_ decimal: Int = 2) -> String {
        return String(format: "%.\(decimal)f", self)
    }
    func toStringWithPercentage(_ decimal: Int = 2) -> String {
        return String(format: "%.\(decimal)f", self*100) + "%"
    }
}

func backgroundThread(_ delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
    // MARK: - backgroud task thread
    /* USAGE:
     A. To run a process in the background with a delay of 3 seconds:
     
     backgroundThread(3.0, background: {
     // Your background function here
     })
     
     B. To run a process in the background then run a completion in the foreground:
     
     backgroundThread(background: {
     // Your function here to run in the background
     },
     completion: {
     // A function to run in the foreground when the background thread is complete
     })
     
     C. To delay by 3 seconds - note use of completion parameter without background parameter:
     
     backgroundThread(3.0, completion: {
     // Your delayed function here to be run in the foreground
     })
     */
    DispatchQueue.global(priority: Int(DispatchQoS.QoSClass.userInitiated.rawValue)).async {
        if(background != nil){ background!(); }
        
        let popTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            if(completion != nil){ completion!(); }
        }
    }
}
