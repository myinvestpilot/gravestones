//
//  StringUtils.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import Foundation

struct Regex {
    
    var pattern: String {
        didSet {
            updateRegex()
        }
    }
    
    var expressionOptions: NSRegularExpression.Options {
        didSet {
            updateRegex()
        }
    }
    
    var matchingOptions: NSRegularExpression.MatchingOptions
    
    var regex: NSRegularExpression?
    
    init(pattern: String, expressionOptions: NSRegularExpression.Options, matchingOptions: NSRegularExpression.MatchingOptions) {
        self.pattern = pattern
        self.expressionOptions = expressionOptions
        self.matchingOptions = matchingOptions
        updateRegex()
    }
    
    init(pattern: String) {
        self.pattern = pattern
        expressionOptions = NSRegularExpression.Options(rawValue: 0)
        matchingOptions = NSRegularExpression.MatchingOptions(rawValue: 0)
        updateRegex()
    }
    
    mutating func updateRegex() {
        regex = try! NSRegularExpression(pattern: pattern, options: expressionOptions)
    }
}

extension String {
    // Returns true if the string has at least one character in common with matchCharacters.
    func containsCharactersIn(_ matchCharacters: String) -> Bool {
        let characterSet = CharacterSet(charactersIn: matchCharacters)
        return self.rangeOfCharacter(from: characterSet) != nil
    }
    
    // Returns true if the string contains only characters found in matchCharacters.
    func containsOnlyCharactersIn(_ matchCharacters: String) -> Bool {
        let disallowedCharacterSet = CharacterSet(charactersIn: matchCharacters).inverted
        return self.rangeOfCharacter(from: disallowedCharacterSet) == nil
    }
    
    // Returns true if the string has no characters in common with matchCharacters.
    func doesNotContainCharactersIn(_ matchCharacters: String) -> Bool {
        let characterSet = CharacterSet(charactersIn: matchCharacters)
        return self.rangeOfCharacter(from: characterSet) == nil
    }
    
    // Returns true if the string represents a proper numeric value.
    // This method uses the device's current locale setting to determine
    // which decimal separator it will accept.
    func isNumeric() -> Bool
    {
        let scanner = Scanner(string: self)
        
        // A newly-created scanner has no locale by default.
        // We'll set our scanner's locale to the user's locale
        // so that it recognizes the decimal separator that
        // the user expects (for example, in North America,
        // "." is the decimal separator, while in many parts
        // of Europe, "," is used).
        scanner.locale = Locale.current
        
        return scanner.scanDecimal(nil) && scanner.isAtEnd
    }
    
    // MARK- regex match
    
    func matchRegex(_ pattern: Regex) -> Bool {
        let range: NSRange = NSMakeRange(0, self.characters.count)
        if pattern.regex != nil {
            let matches: [AnyObject] = pattern.regex!.matches(in: self, options: pattern.matchingOptions, range: range)
            return matches.count > 0
        }
        return false
    }
    
    // check whether input charactor match regex or not instantly
    
    func inputMatchRegex(_ pattern: String) -> Bool {
        let patternRegex = Regex(pattern: pattern)
        let range: NSRange = NSMakeRange(0, self.characters.count)
        if patternRegex.regex != nil {
            let matches: [AnyObject] = patternRegex.regex!.matches(in: self, options: patternRegex.matchingOptions, range: range)
            return matches.count == self.characters.count
        }
        return false
    }
    
    func match(_ patternString: String) -> Bool {
        return self.matchRegex(Regex(pattern: patternString))
    }
    
    func replaceRegex(_ pattern: Regex, template: String) -> String {
        if self.matchRegex(pattern) {
            let range: NSRange = NSMakeRange(0, self.characters.count)
            if pattern.regex != nil {
                return pattern.regex!.stringByReplacingMatches(in: self, options: pattern.matchingOptions, range: range, withTemplate: template)
            }
        }
        return self
    }
    
    func replace(_ pattern: String, template: String) -> String {
        return self.replaceRegex(Regex(pattern: pattern), template: template)
    }
    
    /*
    //e.g. replaces symbols +, -, space, ( & ) from phone numbers
    "+91-999-929-5395".replace("[-\\s\\(\\)]", template: "")
    */
}

// custom regex operator

infix operator =~ {
    associativity none
    precedence 130
}

func =~(lhs: String, rhs: String) -> Bool {
    return  lhs.match(rhs)
}

//if "me@i365.tech" =~
//    "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$" {
//    print("me@i365.tech")
//}
