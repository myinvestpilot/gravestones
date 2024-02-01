//
//  TDPortfolioTradeViewController.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/4/12.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit
import Toaster
import RealmSwift

class TDPortfolioTradeViewController: UIViewController, UIPageViewControllerDataSource, UINavigationControllerDelegate, UIPageViewControllerDelegate {
    
    var notificationToken: NotificationToken? = nil
    
    var pageViewController: UIPageViewController?
    
    var pageControl: UIPageControl?
    
    var portfolios: [TDPortfolio] = [TDPortfolio()]
    
    var isLoadData: Bool = false
    
    var isDisplay = 0
    
    var pageIndex: Int = 0 {
        didSet {
            // write portfolio id to disk for charts init
            UserDefaults.standard.setValue(portfolios[self.pageIndex].id, forKey: "currentPortfolioId")
            UserDefaults.standard.synchronize()
        }
    }
    
    let mainBgColor = UIColor.init(hue: 0.04, saturation: 0.71, brightness: 0.9, alpha: 1)
    let mainFgColor = UIColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1)
    let nvgBarTintColor = UIColor.init(hue: 0.01, saturation: 0.77, brightness: 0.98, alpha: 1)
    
    // TODO: portfolio net value
    // var netsValue: [TDPortfolioNet]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // config navigation item title
        setNavigationBar()
        self.tabBarController?.tabBar.isHidden = false
        
        // add observer
        NotificationCenter.default.addObserver(self, selector: #selector(TDPortfolioTradeViewController.resetViewController(_:)), name: NSNotification.Name(rawValue: "ResetPortfolios"), object: nil)
        
        // write portfolio id to disk for charts init
        UserDefaults.standard.setValue(portfolios[0].id, forKey: "currentPortfolioId")
        UserDefaults.standard.synchronize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isDisplay = 1
        if !isLoadData {
            setPortfoliosData()
        } else {
            initPageControl()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isDisplay = 0
        removePageControl()
    }
    
    // MARK: - set portfolio array data
    
    func setPortfoliosData() {
        guard let services = CoreServices.getInstance() else {
            createPageViewController()
            return
        }
        let portfolioResults = services.aRealm.objects(TDPortfolio.self)
        if portfolioResults.count > 0 {
            isLoadData = true
        }
        self.notificationToken = portfolioResults.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            switch changes {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                if portfolioResults.count > 0 {
                    self?.portfolios.removeAll()
                    for portfolio in portfolioResults {
                        self?.portfolios.append(portfolio.self)
                    }
                }
                break
            case .Update(_, let deletions, let insertions, let modifications):
                self?.portfolios.removeAll()
                for portfolio in portfolioResults {
                    self?.portfolios.append(portfolio.self)
                }
                if deletions.count > 0 {
                    if (self?.portfolios.count)! <= 0 {
                        self?.portfolios.append(TDPortfolio())
                    }
                }
                break
            case .Error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
                break
            }
            self?.pageIndex = 0
            self?.initPageControl()
            self?.createPageViewController()
        }
    }
    
    deinit {
        notificationToken?.stop()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ResetPortfolios"), object: nil)
    }
    
    // MARK: - config navigation controller
    
    func setNavigationBar() {
        //navigationItem.title = portfolios[pageIndex].name
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : mainFgColor, NSFontAttributeName: UIFont(name: "PingFang SC", size: 20)!]
        
        let loginBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "HistoryManager"), style: .plain, target: self, action: #selector(TDPortfolioTradeViewController.history))
        loginBarButtonItem.tintColor = mainFgColor
        navigationItem.setLeftBarButton(loginBarButtonItem, animated: true)
        let addPortfolioBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "PortfolioManager"), style: .plain, target: self, action: #selector(TDPortfolioTradeViewController.addPortfolio))
        addPortfolioBarButtonItem.tintColor = mainFgColor
        navigationItem.setRightBarButton(addPortfolioBarButtonItem, animated: true)
        navigationController?.navigationBar.barTintColor = nvgBarTintColor
        navigationController?.delegate = self
        navigationItem.title = "示例组合"
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }
    
    // MARK: - config page view controller
    
    func createPageViewController() {
        guard portfolios.count > 0 else {
            return
        }
        pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "TDPageViewController") as? UIPageViewController
        // if datasource count is bigger than 1, then enable page control scroll
        if portfolios.count > 1 {
            pageViewController?.dataSource = self
            pageViewController?.delegate = self
        }
        
        let firstController = getItemController(0)
        if let fc = firstController {
            let startingViewControllers: NSArray = [fc]
            pageViewController?.setViewControllers(startingViewControllers as? [UIViewController], direction: .forward, animated: true) {  [weak pageViewController] (finished: Bool) in
                if finished {
                    DispatchQueue.main.async {
                        pageViewController!.setViewControllers(
                            startingViewControllers as? [UIViewController],
                            direction: .forward,
                            animated: false,
                            completion: nil
                        )
                    }
                }
            }
        }
        
        if let pvc = pageViewController {
            addChildViewController(pvc)
            self.view.addSubview(pvc.view)
            pvc.didMove(toParentViewController: self)
        }
        
    }
    
    func resetViewController(_ notification: Foundation.Notification) {
        guard notification.name == "ResetPortfolios" else {
            return
        }
        // reset view controller data
        self.setPortfoliosData()
        // reset view controller when user first add portfolio
        // reset trade view controller
//        let tradeNavigationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("tradeNavigationController") as! UINavigationController
//        let portfolioTradeViewCOntroller = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("TDPortfolioTradeViewController")
//        tradeNavigationViewController.setViewControllers([portfolioTradeViewCOntroller], animated: true)
//        var viewControllers = self.tabBarController!.viewControllers!
//        viewControllers[2] = tradeNavigationViewController
//        self.tabBarController?.setViewControllers(viewControllers, animated: true)
    }
    
    func getItemController(_ itemIndex: Int) -> TradeItemController? {
        var index = itemIndex
        if index < 0 {
            index = self.portfolios.count - 1
        }
        if index >= portfolios.count {
            index = 0
        }
        let tradeItemController = self.storyboard?.instantiateViewController(withIdentifier: "TDTradeItemController") as? TradeItemController
        tradeItemController?.itemIndex = index
        tradeItemController?.portfolio = portfolios[index]
        return tradeItemController
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        pageViewController.viewControllers
        guard portfolios.count > 1 else {
            return nil
        }
        return getItemController(pageIndex-1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard portfolios.count > 1 else {
            return nil
        }
        return getItemController(pageIndex+1)
    }
    
    // MARK: - set page control indicator
    
    func initPageControl() {
        guard isDisplay == 1 else {
            return
        }
        guard portfolios.count > 0 else{
            return
        }
        removePageControl()
        if portfolios.count == 1 {
            navigationItem.title = portfolios[0].name != "" ? portfolios[0].name : "示例组合"
        } else {
            let navBarSize = navigationController?.navigationBar.bounds.size
            let origin = CGPoint(x: navBarSize!.width/2, y: navBarSize!.height/6 * 5)
            self.pageControl = UIPageControl.init(frame: CGRect(x: origin.x, y: origin.y, width: 0, height: 0))
            self.pageControl!.numberOfPages = portfolios.count
            self.pageControl?.tag = 1
            navigationController?.navigationBar.addSubview(self.pageControl!)
            
            setPageControls(self.pageIndex)
        }
    }
    
    func removePageControl() {
        if let views = navigationController?.navigationBar.subviews {
            for view in views {
                let v = view as UIView
                if v.tag == 1 {
                    v.removeFromSuperview()
                }
            }
        }
    }
    
    func setPageControls(_ index: Int) {
        guard portfolios.count > 1 else {
            return
        }
        self.pageControl?.currentPage = pageIndex
        navigationItem.title = String(portfolios[pageIndex].name)
        // force redraw navigation bar
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.navigationController?.navigationBar.setNeedsDisplay()
    }
    
    // right after the animation is completed
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            let firstViewController = pageViewController.viewControllers?.first as? TradeItemController
            if let itemViewController = firstViewController {
                self.pageIndex = itemViewController.itemIndex
            }
            setPageControls(pageIndex)
        }
    }
    
    //  called before the actual transition takes place
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let firstViewController = pendingViewControllers.first as? TradeItemController
        if let itemViewController = firstViewController {
            setPageControls(itemViewController.itemIndex)
        }
    }
    
    func history() {
        if HelpersMethond.sharedInstance.checkLogin() {
            performSegue(withIdentifier: "HistoryManagerViewController", sender: self)
        } else {
            self.tabBarController?.selectedIndex = 4
            Toast.makeText("请先登陆ヾ(=^▽^=)ノ").show()
        }
    }
    
    func addPortfolio(_ sender: UIBarButtonItem) {
        if HelpersMethond.sharedInstance.checkLogin() {
            performSegue(withIdentifier: "PortfolioManagerViewController", sender: self)
        } else {
            self.tabBarController?.selectedIndex = 4
            Toast.makeText("请登陆后再新建组合吧ヾ(=^▽^=)ノ").show()
        }
    }
}
