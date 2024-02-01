//
//  TradingViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/3.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Charts
import RealmSwift
import Toaster
import Realm

class TradeItemController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ChartViewDelegate {
    
    // TO DO - portfolio net value
    // var netValue: TDPortfolioNet?
    
    let reuseIdentifier = "tdCell"
    var items = ["净值", "胜率", "盈亏比", "浮动盈亏", "风险资金", "仓位", "总资产", "收益率", "回撤幅度"]
    
    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var portfolioCollectionView: UICollectionView!
    @IBOutlet weak var parentViewBottomLayoutGuide: NSLayoutConstraint!
    
    @IBOutlet weak var buySaleButtonBottonLayoutGuide: NSLayoutConstraint!
    
    var notificationToken: NotificationToken? = nil
    
    var itemValue: [String]!
    var itemIndex: Int = 0
    var portfolio: TDPortfolio? {
        didSet {
            itemValue = [portfolio!.currentNet.toStringWithDecimal(), portfolio!.winRatio.toStringWithPercentage(), portfolio!.profitLossRatio.toStringWithDecimal(), portfolio!.floatingProfitLoss.toStringWithDecimal(), portfolio!.riskMoney.toStringWithDecimal(), portfolio!.position.toStringWithPercentage(), portfolio!.marketValue.toStringWithDecimal(), portfolio!.returnRatio.toStringWithPercentage(), portfolio!.retreatRange.toStringWithPercentage()]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Notification call function not the object, so the function cannot use value of object
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TradeItemController.setChartRealmData), name: "ResetNetAssets", object: nil)
        chartView.delegate = self
        // Set Charts
        if !HelpersMethond.sharedInstance.checkLogin() {
            setChartSampleData()
        } else {
            setChartRealmData()
        }
        setChartView()
    }
    
    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ResetNetAssets", object: nil)
//        notificationToken?.stop()
    }
    
    // MARK - chart view config
    
//    func realmData() {
    
        // add database watch
//        self.notificationToken = netAssetsResults.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
//            switch changes {
//            case .Initial:
//                // Results are now populated and can be accessed without blocking the UI
//                self!.realmData()
//                break
//            case .Update(_, let deletions, let insertions, let modifications):
//                self!.realmData()
//                break
//            case .Error(let err):
//                // An error occurred while opening the Realm file on the background worker thread
//                fatalError("\(err)")
//                break
//            }
//        }
//    }
    
    // Set Charts Realm Data
    func setChartRealmData() {
        var xDates = [String]()
        var xIndex = [Int]()
        var chartDataSets = [IChartDataSet]()
        var netDataEntries: [ChartDataEntry] = []
        var index500Entries: [ChartDataEntry] = []
        var index300Entries: [ChartDataEntry] = []
        
        // Set Realm Charts Data
        let aRealm = try! Realm
        // read portfolio id from disk
        let predicate = NSPredicate(format: "portfolios = '\(portfolio!.id)'")
        let netAssetsResults = aRealm.objects(TDNetAssetValue).filter(predicate).sorted("tradeDate", ascending: true)
        
        // create xIndex and Xvalue
        var i = 0
        for net in netAssetsResults {
            xIndex.append(i)
            xDates.append(net.tradeDate.dateToString())
            netDataEntries.append(ChartDataEntry(value: net.portfolioNetValue, xIndex: i))
            index500Entries.append(ChartDataEntry(value: net.zz500IndexNet, xIndex: i))
            index300Entries.append(ChartDataEntry(value: net.hs300IndexNet, xIndex: i))
            i += 1
        }
        
        let netChartDataSet = LineChartDataSet(yVals: netDataEntries, label: "净值")
        let index500ChartDataSet = LineChartDataSet(yVals: index500Entries, label: "中证500")
        let index300ChartDataSet = LineChartDataSet(yVals: index300Entries, label: "沪深300")
        
        netChartDataSet.colors = [mainFgColor]
        netChartDataSet.circleRadius = 0
        netChartDataSet.valueTextColor = mainFgColor
        netChartDataSet.drawValuesEnabled = false
        netChartDataSet.drawCircleHoleEnabled = false
        netChartDataSet.circleColors = [mainFgColor]
        index500ChartDataSet.colors = [UIColor.init(hue: 0.1, saturation: 1, brightness: 1, alpha: 1)]
        index500ChartDataSet.circleRadius = 0
        index500ChartDataSet.valueTextColor = mainFgColor
        index500ChartDataSet.drawValuesEnabled = false
        index500ChartDataSet.drawCircleHoleEnabled = false
        index500ChartDataSet.circleColors = [UIColor.init(hue: 0.1, saturation: 1, brightness: 1, alpha: 1)]
        index300ChartDataSet.colors = [UIColor.init(hue: 0.2, saturation: 1, brightness: 0.8, alpha: 1)]
        index300ChartDataSet.circleRadius = 0
        index300ChartDataSet.valueTextColor = mainFgColor
        index300ChartDataSet.drawValuesEnabled = false
        index300ChartDataSet.drawCircleHoleEnabled = false
        index300ChartDataSet.circleColors = [UIColor.init(hue: 0.2, saturation: 1, brightness: 0.8, alpha: 1)]
        
        chartDataSets.append(netChartDataSet)
        chartDataSets.append(index500ChartDataSet)
        chartDataSets.append(index300ChartDataSet)
        
        chartView.data = LineChartData(xVals: xDates, dataSets: chartDataSets)
        chartView.notifyDataSetChanged()
    }
    
    // Set Charts Sample Data
    @objc func setChartSampleData() {
        
        var xDates = [String]()
        var netValues = [Double]()
        var index500Values = [Double]()
        var index300Values = [Double]()
        netValues.append(1)
        index500Values.append(1)
        index300Values.append(1)
        
        var netDataEntries: [ChartDataEntry] = []
        var index500Entries: [ChartDataEntry] = []
        var index300Entries: [ChartDataEntry] = []
        var chartDataSets = [LineChartDataSet]()
        
        // Set Sample Charts Data
        for i in 1...1000 {
            xDates.append(String(i))
            netValues.append(netValues.last! + ((arc4random_uniform(2) == 0) ? 1.0 : -1.0) * Double(arc4random_uniform(10)) / 100.0)
            index500Values.append(index500Values.last! + ((arc4random_uniform(2) == 0) ? 1.0 : -1.0) * Double(arc4random_uniform(10)) / 100.0)
            index300Values.append(index300Values.last! + ((arc4random_uniform(2) == 0) ? 1.0 : -1.0) * Double(arc4random_uniform(10)) / 100.0)
        }
        
        for i in 0..<xDates.count {
            netDataEntries.append(ChartDataEntry(value: netValues[i], xIndex: i))
            index500Entries.append(ChartDataEntry(value: index500Values[i], xIndex: i))
            index300Entries.append(ChartDataEntry(value: index300Values[i], xIndex: i))
        }
        
        let netChartDataSet = LineChartDataSet(yVals: netDataEntries, label: "净值")
        let index500ChartDataSet = LineChartDataSet(yVals: index500Entries, label: "中证500")
        let index300ChartDataSet = LineChartDataSet(yVals: index300Entries, label: "沪深300")
        netChartDataSet.colors = [mainFgColor]
        netChartDataSet.circleRadius = 0
        netChartDataSet.valueTextColor = mainFgColor
        netChartDataSet.drawValuesEnabled = false
        netChartDataSet.drawCircleHoleEnabled = false
        netChartDataSet.circleColors = [mainFgColor]
        index500ChartDataSet.colors = [UIColor.init(hue: 0.1, saturation: 1, brightness: 1, alpha: 1)]
        index500ChartDataSet.circleRadius = 0
        index500ChartDataSet.valueTextColor = mainFgColor
        index500ChartDataSet.drawValuesEnabled = false
        index500ChartDataSet.drawCircleHoleEnabled = false
        index500ChartDataSet.circleColors = [UIColor.init(hue: 0.1, saturation: 1, brightness: 1, alpha: 1)]
        index300ChartDataSet.colors = [UIColor.init(hue: 0.2, saturation: 1, brightness: 0.8, alpha: 1)]
        index300ChartDataSet.circleRadius = 0
        index300ChartDataSet.valueTextColor = mainFgColor
        index300ChartDataSet.drawValuesEnabled = false
        index300ChartDataSet.drawCircleHoleEnabled = false
        index300ChartDataSet.circleColors = [UIColor.init(hue: 0.2, saturation: 1, brightness: 0.8, alpha: 1)]
        chartDataSets.append(netChartDataSet)
        chartDataSets.append(index500ChartDataSet)
        chartDataSets.append(index300ChartDataSet)
        
        chartView.data = LineChartData(xVals: xDates, dataSets: chartDataSets)
    }
    
    // set chart view
    func setChartView() {
        
        chartView.noDataText = "网络故障，请稍候再试"
        
        chartView.descriptionText = ""
        chartView.xAxis.labelPosition = .Bottom
        chartView.xAxis.labelTextColor = mainFgColor
        chartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .EaseInBounce)
        chartView.rightAxis.labelTextColor = mainFgColor
        chartView.leftAxis.labelTextColor = chartView.backgroundColor!
        chartView.leftAxis.xOffset = 0
        chartView.rightAxis.zeroLineColor = mainFgColor
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.rightAxis.drawAxisLineEnabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.rightAxis.drawZeroLineEnabled = false
        chartView.rightAxis.gridColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 1, alpha: 1)
        chartView.scaleYEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.avoidFirstLastClippingEnabled = true
        chartView.highlightPerDragEnabled = true
        chartView.legend.textColor = mainFgColor
        chartView.autoScaleMinMaxEnabled = true
        // cause the NetAssetValue count is only one, so it cannot set visibleXRangeMinimum
        chartView.setVisibleXRangeMinimum(10)
        let marker = TDChartMarker.init(color: mainFgColor, font: UIFont.systemFont(ofSize: 2), insets: UIEdgeInsetsMake(2.0, 0, 2.0, 0))
        marker.minimumSize = CGSize(width: 2, height: 2)
        
        chartView.marker = marker
//        chartView.setVisibleXRangeMaximum(20)
//        chartView.moveViewToX(CGFloat(xDates.count - 20))
//        let one = ChartLimitLine(limit: 1.0, label: "1.0")
//        chartView.rightAxis.addLimitLine(one)
        
    }
    
    // MARK: - ChartViewDelegate
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
//        NSLog("chartValueNothingSelected")
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
//        NSLog("chartValueSelected")
    }
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TDCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.textLabel.text = self.items[indexPath.item]
        cell.valueLabel.text = self.itemValue[indexPath.item]
        
//        cell.layer.borderColor = UIColor.grayColor().CGColor
//        cell.layer.borderWidth = 1
//        cell.layer.cornerRadius = 8
//        cell.backgroundColor = UIColor.yellowColor() // make cell more visible in our example project
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
//        print("You selected cell #\(indexPath.item)!")
    }
    
    // set collectionview cell size
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width/4, height: self.portfolioCollectionView.frame.height/4)
    }
    
    // set collectionview cell margin
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let collectionViewFlowLayout = UICollectionViewFlowLayout.init()
        let cellSpacing = collectionViewFlowLayout.minimumLineSpacing
        let cellHight = self.portfolioCollectionView.frame.height/4
        let inset = (collectionView.bounds.size.height - (3 * cellHight + 2 * cellSpacing)) / 2
        return UIEdgeInsetsMake(inset, 10, 0, 10);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BuySaleViewController" {
            if let buySaleCashViewController = segue.destination as? TDBuySaleCashViewController {
                buySaleCashViewController.portfolioId = portfolio?.id
                buySaleCashViewController.portfolio = portfolio
            }
        }
    }

    @IBAction func BuySaleAction(_ sender: UIButton) {
        if HelpersMethond.sharedInstance.checkLogin() && (portfolio?.id != "") {
            performSegue(withIdentifier: "BuySaleViewController", sender: self)
        } else {
            JLToast.makeText("请登陆后新建一个组合再交易吧ヾ(=^▽^=)ノ").show()
        }
    }
}
