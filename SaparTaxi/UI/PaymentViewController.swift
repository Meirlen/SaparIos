//
//  PaymentViewController.swift
//  Sappar
//
//  Created by Max on 01.01.2023.
//

import Foundation
import UIKit

@objc(PaymentViewController)
class PaymentViewController: UIViewController {
    
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
    
    override func viewDidLoad() {

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mainView?.addSubview(createBackButton())
    }
    
    @IBAction func changePrice(_ sender: UISlider) {
        let step: Float = 0.1
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
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
