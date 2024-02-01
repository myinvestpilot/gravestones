//
//  TDLoadingIndicatorView.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/11.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TDLoadingIndicatorView {

    static var currentOverlay : UIView?
    
    static func show() {
        
        guard let currentMainWindow = UIApplication.shared.keyWindow else {
            
            print("No main window.")
            
            return
            
        }
        
        showWithoutText(currentMainWindow)
        
    }
    
    static func show(_ loadingText: String) {
        
        guard let currentMainWindow = UIApplication.shared.keyWindow else {
            
            print("No main window.")
            
            return
            
        }
        
        show(currentMainWindow, loadingText: loadingText)
        
    }
    
    static func showWithoutText(_ overlayTarget : UIView) {
        
        show(overlayTarget, loadingText: nil)
        
    }
    
    static func show(_ overlayTarget : UIView, loadingText: String?) {
        
        // Clear it first in case it was already shown
        
        hide()
        
        // Create the overlay
        
        let overlay = UIView(frame: overlayTarget.frame)
        
        overlay.center = overlayTarget.center
        
        overlay.alpha = 0
        
        overlay.backgroundColor = UIColor.black
        
        overlayTarget.addSubview(overlay)
        
        overlayTarget.bringSubview(toFront: overlay)
        
        // Create and animate the activity indicator
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        
        indicator.center = overlay.center
        
        indicator.startAnimating()
        
        overlay.addSubview(indicator)
        
        // Create label
        
        if let textString = loadingText {
            
            let label = UILabel()
            
            label.text = textString
            
            label.textColor = UIColor.white
            
            label.sizeToFit()
            
            label.center = CGPoint(x: indicator.center.x, y: indicator.center.y + 30)
            
            overlay.addSubview(label)
            
        }
        
        // Animate the overlay to show
        
        UIView.beginAnimations(nil, context: nil)
        
        UIView.setAnimationDuration(0.5)
        
        overlay.alpha = overlay.alpha > 0 ? 0 : 0.5
        
        UIView.commitAnimations()
        
        currentOverlay = overlay
        
    }
    
    static func hide() {
        
        if currentOverlay != nil {
            
            currentOverlay?.removeFromSuperview()

            currentOverlay =  nil

        }

    }

}
