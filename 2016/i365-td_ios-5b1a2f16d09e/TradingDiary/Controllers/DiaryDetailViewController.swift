//
//  DiaryDetailViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class DiaryDetailViewController: UIViewController {

    @IBOutlet weak var positionCodeLabel: UILabel!
    @IBOutlet weak var positionNameLabel: UILabel!
    @IBOutlet weak var diaryDetailTextView: UITextView!
    
    var risk: TDRiskManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let risk = risk {
            let buy = risk.buy! as TDRiskBuy
            let buyDp = risk.buyDp! as TDRiskBuyDp
            let sale = risk.sale! as TDRiskSale
            let saleDp = risk.buySaleDp! as TDRiskBuySaleDp
            
            positionNameLabel.text = buyDp.name
            positionCodeLabel.text = buy.code
            
            let buyPlanStr = "买入计划：于" + buy.tradeBuyDate.dateToString() + "在" + buy.tradeBuyPrice.toStringWithDecimal() + "元买入占比" + buyDp.positionRatio.toStringWithPercentage() + "的仓位，止损价" + buy.stopPrice.toStringWithDecimal() + "元，目标价" + buy.targetPrice.toStringWithDecimal() + "元"
            let buyCommentStr = "买入理由：" + buy.tradeBuyComment
            let salePlanStr = "卖出计划：于" + sale.tradeSaleDate.dateToString() + "在" + sale.tradeSalePrice.toStringWithDecimal() + "元卖出。"
            let saleCommentStr = "卖出理由：" + sale.tradeSaleComment
            var profitOrLessStr = ""
            if saleDp.tradeProfitRatio > 0 {
                profitOrLessStr = "盈利"
            } else {
                profitOrLessStr = "亏损"
            }
            let tradeResultStr = "交易结果：持仓" + saleDp.holdTradeDay.toStringWithDecimal(0) + "天，" + profitOrLessStr + saleDp.tradeProfitRatio.toStringWithPercentage()
            diaryDetailTextView.text = buyPlanStr + "\n\n" + buyCommentStr + "\n\n" + salePlanStr + "\n\n" + saleCommentStr + "\n\n" + tradeResultStr
            
            // set diary detail text view style
            diaryDetailTextView.autoresizingMask = .flexibleHeight
            diaryDetailTextView.textAlignment = .justified
            diaryDetailTextView.textContainerInset = UIEdgeInsets(top: 0, left: 5, bottom: 5, right: 5)
        }
    }
}
