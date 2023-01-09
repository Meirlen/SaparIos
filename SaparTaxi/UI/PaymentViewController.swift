//
//  PaymentViewController.swift
//  Sappar
//
//  Created by Max on 01.01.2023.
//

import Foundation
import UIKit
import CoreLocation

struct ResultPrice {
    var amountCompanion: Int?
    var price: Double?
}


@objc(PaymentViewController)
class PaymentViewController: UIViewController {
    
    @IBOutlet weak var loadPriceView: UIView?
    @IBOutlet weak var titleSliderLabel: UILabel?
    @IBOutlet weak var averagePriceLabel: UILabel?
    @IBOutlet weak var topConstr: NSLayoutConstraint?
    @IBOutlet weak var mainView: UIView?
    @IBOutlet weak var priceSlider: UISlider?
    @IBOutlet weak var titleSwichLabel: UILabel?
    @IBOutlet var companionSwich: UISwitch?
    @IBOutlet weak var addCompanionView: UIView?
    @IBOutlet weak var doneButton: UIButton?

    @IBOutlet var plusButton: UIButton?
    @IBOutlet var amountLabel: UILabel?
    @IBOutlet var minusButton: UIButton?

    @IBOutlet weak var darkenedView: UIView?
    @IBOutlet weak var allTaxiTableView: UITableView?
    @IBOutlet weak var heightViewTableView: NSLayoutConstraint?
    
    let heightCellTableView: CGFloat = 44
    var amountCompanion = 1
    var averagePrice: Double = 0.0
    let indentifire = "TaxiCell"
    
    var prices = [TaxiService]() {
        didSet {
            getAveragePrice()
            averagePriceLabel?.text = String(format: "%.0f", averagePrice) + " ₸"
            setParamSlider()
            loadPriceView?.isHidden = true
            allTaxiTableView?.reloadData()
            doneButton?.isEnabled = (averagePrice > 0)
        }
    }
    
    var arrLoc = [Location]()
    
    var completion: ((ResultPrice?)->Void)?
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ApiService.estimateOrder(locations: arrLoc) { [weak self] prices in
            self?.prices = prices
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightViewTableView?.constant = 0
        mainView?.addSubview(createBackButton())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPriceView?.isHidden = false
    }
    
    //MARK: -
    
    func getAveragePrice() {
        if prices.count == 0 {
            averagePrice = 0
            return
        }
        
        var sumPrices = 0.0
        for i in prices {
            sumPrices += i.price
        }
        averagePrice = sumPrices/Double(prices.count)
    }
    
    func setParamSlider() {
        let max = averagePrice + averagePrice/100*25
        let min = averagePrice - averagePrice/100*25
        priceSlider?.maximumValue = Float(max)
        priceSlider?.minimumValue = Float(min)
        priceSlider?.value = Float(averagePrice)
    }
    
    @IBAction func changePrice(_ sender: UISlider) {
        guard let max = priceSlider?.maximumValue, let min = priceSlider?.minimumValue else { return }
        let step = (max - min) / 10
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        if sender.value == Float(averagePrice) {
            titleSliderLabel?.text = "РЕКОМЕНДУЕМАЯ ЦЕНА:"
        }
        else {
            titleSliderLabel?.text = "ВАША ЦЕНА:"
        }
        
        averagePriceLabel?.text = String(format: "%.0f", sender.value)  + " ₸"
    }
    
    @IBAction func companionIsActiv(_ sender: UISwitch) {
        guard let companionSwichIsOn = companionSwich?.isOn else { return }
        self.topConstr?.constant = companionSwichIsOn ? 50 : 8
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
        
        titleSwichLabel?.text = companionSwichIsOn == false ? "Включить режим попутчика" : "Режим попутчика активен"
    }

    @IBAction func amountReduce(_ sender: UIButton) {
        if amountCompanion <= 2 {
            minusButton?.isEnabled = false
        }
        plusButton?.isEnabled = true
        amountCompanion -= 1
        amountLabel?.text = String(amountCompanion)
    }
    
    @IBAction func amountRaise(_ sender: UIButton) {
        if amountCompanion >= 3{
            plusButton?.isEnabled = false
        }
        minusButton?.isEnabled = true
        amountCompanion += 1
        amountLabel?.text = String(amountCompanion)
    }
    
    @IBAction func getPriceOnMapViewController(_ sender: UIButton) {
        let price = Double(priceSlider?.value ?? 0)
        let result = ResultPrice(amountCompanion: amountCompanion, price: price)
        completion?(result)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func showAllTaxis(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.darkenedView?.alpha = 1
            self.darkenedView?.isHidden = false
            self.heightViewTableView?.constant = self.heightCellTableView * CGFloat(self.prices.count)
            self.view.layoutIfNeeded()
            
        })
    }
    
    @IBAction func tapOnDarkenedView(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: {
            self.darkenedView?.alpha = 0
            self.heightViewTableView?.constant = 0
            self.view.layoutIfNeeded()
        }, completion:  {
           (value: Bool) in
            self.darkenedView?.isHidden = true
        })
    }
}

extension PaymentViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prices.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: indentifire, for: indexPath)
        let taxiCell = cell as? TaxiCell
        
        let price = prices[indexPath.row]
        taxiCell?.nameTaxiLabel?.text = price.name
        taxiCell?.typeLabel?.text = price.oneOffer == true ? "Цена гибкая" : "Цена фиксированная"
        taxiCell?.amountButton?.setTitle(String(format: "%.0f", price.price) + " ₸", for: .normal)

        return cell
    }
}

class TaxiCell: UITableViewCell {
    @IBOutlet weak var iconTaxiImage: UIImageView?
    @IBOutlet weak var nameTaxiLabel: UILabel?
    @IBOutlet weak var typeLabel: UILabel?
    @IBOutlet weak var amountButton: UIButton?
}
