//
//  TDGridController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/5.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import RealmSwift

private let reuseIdentifier = "tdCell"

class TDGridController: RealmGridController, UICollectionViewDelegateFlowLayout {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the Realm object class name that the grid controller will bind to
        self.entityName = "TDPortfolio"
        self.sortDescriptors = [SortDescriptor(property: "publishedDate", ascending: false)]
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TDCollectionViewCell
        return cell
    }
    

}
