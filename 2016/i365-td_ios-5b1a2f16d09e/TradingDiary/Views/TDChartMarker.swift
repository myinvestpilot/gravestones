//
//  TDChartMarker.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/8.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Charts
import Foundation

open class TDChartMarker: ChartMarker {
    
    open var color: UIColor?
    open var arrowSize = CGSize(width: 15, height: 11)
    open var font: UIFont?
    open var insets = UIEdgeInsets()
    open var minimumSize = CGSize()
    
    fileprivate var labelns: NSString?
    fileprivate var _labelSize: CGSize = CGSize()
    fileprivate var _size: CGSize = CGSize()
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var _drawAttributes = [String : AnyObject]()
    
    public init(color: UIColor, font: UIFont, insets: UIEdgeInsets)
    {
        super.init()
        
        self.color = color
        self.font = font
        self.insets = insets
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = .center
    }
    
    open override var size: CGSize { return _size; }
    
    override open func draw(context: CGContext, point: CGPoint)
    {
        if (labelns == nil)
        {
            return
        }
        
        let labelText = labelns as! String
        
        var label: String {
            if labelText.characters.distance(from: labelText.startIndex, to: labelText.endIndex) > 4 {
                return labelText.substring(to: labelText.characters.index(labelText.startIndex, offsetBy: 4))
            }
            return labelText
        }
        
        var pt = CGPoint()
        
        pt.x = 15
        pt.y = CGFloat(point.y - 8)
        
        ChartUtils.drawText(context: context, text: label, point: pt, align: .center, attributes: [NSForegroundColorAttributeName: color!])
    }
    
    func drawArrowRct(context: CGContext, point: CGPoint)
    {
        if (labelns == nil)
        {
            return
        }
        
        var rect = CGRect(origin: point, size: _size)
        rect.origin.x -= _size.width / 2.0
        rect.origin.y -= _size.height
        
        context.saveGState()
        
        context.setFillColor((color?.cgColor)!)
        context.beginPath()
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height - arrowSize.height))
        context.addLine(to: CGPoint(x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0, y: rect.origin.y + rect.size.height - arrowSize.height))
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width / 2.0, y: rect.origin.y + rect.size.height))
        context.addLine(to: CGPoint(x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0, y: rect.origin.y + rect.size.height - arrowSize.height))
        context.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height - arrowSize.height))
        context.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.fillPath()
        
        rect.origin.y += self.insets.top
        rect.size.height -= self.insets.top + self.insets.bottom
        
        UIGraphicsPushContext(context)
        
        labelns?.draw(in: rect, withAttributes: _drawAttributes)
        
        UIGraphicsPopContext()
        
        context.restoreGState()
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        let label = entry.value.description
        labelns = label as NSString
        
        _drawAttributes.removeAll()
        _drawAttributes[NSFontAttributeName] = self.font
        _drawAttributes[NSParagraphStyleAttributeName] = _paragraphStyle
        
        _labelSize = labelns?.size(attributes: _drawAttributes) ?? CGSize.zero
        _size.width = _labelSize.width + self.insets.left + self.insets.right
        _size.height = _labelSize.height + self.insets.top + self.insets.bottom
        _size.width = max(minimumSize.width, _size.width)
        _size.height = max(minimumSize.height, _size.height)
    }
    
}
