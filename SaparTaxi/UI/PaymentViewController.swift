//
//  PaymentViewController.swift
//  Sappar
//
//  Created by Max on 01.01.2023.
//

import Foundation
import UIKit
import CoreLocation

struct Price {
    var name: String
    var price: Double
}

class PaymentService {
    static func getPayment(coord: [Double], completion:(([Price])->Void)?) {
        var result = [Price]()
        result.append(Price(name: "yandex", price: 200))
        result.append(Price(name: "bolt", price: 100))
        result.append(Price(name: "uber", price: 300))
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            completion?(result)
        }
    }
    
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
    @IBOutlet weak var companionSwich: UISwitch?
    @IBOutlet weak var addCompanionView: UIView?
    @IBOutlet weak var amountLabel: UILabel?
    @IBOutlet weak var minusButton: UIButton?
    @IBOutlet weak var plusButton: UIButton?
    
    var amountCompanion = 1
    var averagePrice: Double = 0.0
    
    var prices = [Price]() {
        didSet {
            getAveragePrice()
            averagePriceLabel?.text = String(averagePrice)
            setParamSlider()
            loadPriceView?.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        PaymentService.getPayment(coord: [0.1, 3.2]) { [weak self] prices in
            self?.prices = prices
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mainView?.addSubview(createBackButton())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPriceView?.isHidden = false
    }
    
    func getAveragePrice() {
        var sumPrices = 0.0
        for i in prices {
            sumPrices += i.price
        }
        averagePrice = sumPrices/Double(prices.count)
    }
    
    func setParamSlider() {
        let max = averagePrice + averagePrice/100*10
        let min = averagePrice - averagePrice/100*10
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
        averagePriceLabel?.text = String(sender.value)
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
}
