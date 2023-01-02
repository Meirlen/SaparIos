//
//  PaymentViewController.swift
//  Sappar
//
//  Created by Max on 01.01.2023.
//

import Foundation
import UIKit

class PaymentViewController: UIViewController {
    
    @IBOutlet weak var titleSwichLabel: UILabel?
    @IBOutlet weak var companionSwich: UISwitch?
    @IBOutlet weak var addCompanionView: UIView?
    @IBOutlet weak var amountLabel: UILabel?
    @IBOutlet weak var minusButton: UIButton?
    @IBOutlet weak var plusButton: UIButton?
    
    var amountCompanion = 1
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        navigationController?.isNavigationBarHidden = false
        
        navigationItem.leftBarButtonItem = createBackButton()
    }
    
    @IBAction func companionIsActiv(_ sender: UISwitch) {
        guard let companionSwichIsOn = companionSwich?.isOn else { return }
        addCompanionView?.isHidden = !companionSwichIsOn
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
