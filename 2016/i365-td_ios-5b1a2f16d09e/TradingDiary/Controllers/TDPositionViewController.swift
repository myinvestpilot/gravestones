//
//  TDPositionViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/9.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import RealmSwift

class TDPositionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    let cellBgColor = UIColor.init(hue: 0.01, saturation: 0.6, brightness: 0.96, alpha: 1)
    
    let positionCellIdentifier = "PositionCellIdentifier"
    let contentCellIdentifier = "ContentCellIdentifier"
    @IBOutlet weak var collectionView: UICollectionView!
    
    var numberOfPosition = 1
    var positions = [TDPosition()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "持仓"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        
        self.collectionView .register(UINib(nibName: "PositionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: positionCellIdentifier)
        self.collectionView .register(UINib(nibName: "ContentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: contentCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // clear old value for new portfolio
        positions = [TDPosition()]
        
        let portfolioId = UserDefaults.standard.string(forKey: "currentPortfolioId")
        guard portfolioId != nil && portfolioId != "" else {
            numberOfPosition = 1
            return
        }
        guard let service = CoreServices.getInstance(), let userId = UserDefaults.standard.string(forKey: "user_id") else {
            numberOfPosition = 1
            return
        }
        let predicate = NSPredicate(format: "portfolios = '\(portfolioId!)' and userId = '\(userId)'")
        let positionsResults = service.aRealm.objects(TDPosition).filter(predicate)
        numberOfPosition = positionsResults.count + 1   // set number of collection view
        // set content of collection view
        for position in positionsResults {
            positions.append(position)
        }
        collectionView.reloadData()
    }

    // MARK - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfPosition
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let positionCell : PositionCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: positionCellIdentifier, for: indexPath) as! PositionCollectionViewCell
                positionCell.backgroundColor = UIColor.white
                positionCell.positionLabel.font = UIFont(name: "PingFang SC", size: 16)
                positionCell.positionLabel.textColor = UIColor.black
                positionCell.positionLabel.text = "名称"
                
                return positionCell
            } else {
                let contentCell : ContentCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: contentCellIdentifier, for: indexPath) as! ContentCollectionViewCell
                contentCell.contentLabel.font = UIFont(name: "PingFang SC", size: 16)
                switch indexPath.row {
                case 1:
                    contentCell.contentLabel.text = "现价"
                case 2:
                    contentCell.contentLabel.text = "止损价"
                case 3:
                    contentCell.contentLabel.text = "盈亏率"
                case 4:
                    contentCell.contentLabel.text = "持仓率"
                case 5:
                    contentCell.contentLabel.text = "市值"
                case 6:
                    contentCell.contentLabel.text = "代码"
                case 7:
                    contentCell.contentLabel.text = "买入时间"
                default:
                    contentCell.contentLabel.text = ""
                }
                if indexPath.section % 2 != 0 {
                    contentCell.backgroundColor = cellBgColor
                    contentCell.contentLabel.textColor = UIColor.white
                } else {
                    contentCell.backgroundColor = UIColor.white
                    contentCell.contentLabel.textColor = UIColor.black
                }
                
                return contentCell
            }
        } else {
            if indexPath.row == 0 {
                let positionCell : PositionCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: positionCellIdentifier, for: indexPath) as! PositionCollectionViewCell
                positionCell.positionLabel.font = UIFont(name: "PingFang SC", size: 16)
                positionCell.positionLabel.text = positions[indexPath.section].name
                if indexPath.section % 2 != 0 {
                    positionCell.backgroundColor = cellBgColor
                    positionCell.positionLabel.textColor = UIColor.white
                } else {
                    positionCell.backgroundColor = UIColor.white
                    positionCell.positionLabel.textColor = UIColor.black
                }
                return positionCell
            } else {
                let contentCell : ContentCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: contentCellIdentifier, for: indexPath) as! ContentCollectionViewCell
                contentCell.contentLabel.font = UIFont(name: "PingFang SC", size: 16)
                switch indexPath.row {
                case 1:
                    contentCell.contentLabel.text = positions[indexPath.section].price.toStringWithDecimal()
                case 2:
                    contentCell.contentLabel.text = positions[indexPath.section].stopPrice.toStringWithDecimal()
                case 3:
                    contentCell.contentLabel.text = positions[indexPath.section].profitOrLossRatio.toStringWithPercentage()
                case 4:
                    contentCell.contentLabel.text = positions[indexPath.section].positionRatio.toStringWithPercentage()
                case 5:
                    contentCell.contentLabel.text = positions[indexPath.section].marketValue.toStringWithDecimal()
                case 6:
                    contentCell.contentLabel.text = positions[indexPath.section].code
                case 7:
                    contentCell.contentLabel.text = positions[indexPath.section].created.dateToString()
                default:
                    contentCell.contentLabel.text = ""
                }
                if indexPath.section % 2 != 0 {
                    contentCell.backgroundColor = cellBgColor
                    contentCell.contentLabel.textColor = UIColor.white
                } else {
                    contentCell.backgroundColor = UIColor.white
                    contentCell.contentLabel.textColor = UIColor.black
                }
                
                return contentCell
            }
        }
    }

}
