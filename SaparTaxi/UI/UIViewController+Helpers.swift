//
//  UIViewController+Helpers.swift
//  M13_Shop
//
//  Created by Max on 14.10.2022.
//

import UIKit

extension UIViewController {
    
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
    
    func createBackButton(selector: Selector? = nil) -> UIBarButtonItem {
        return createButton(img: UIImage(systemName: "arrow.backward"), selector: selector ?? #selector(back))
    }
    
    func createButton(img: UIImage?, selector: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.setTitle("", for: .normal)
        button.setImage(img, for: .normal)
        button.tintColor = .black
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: -1.0, height: 1.0)
        button.layer.shadowRadius = 2

        button.layer.cornerRadius = 20
        button.backgroundColor = UIColor.white
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.addTarget(self, action: selector, for: UIControl.Event.touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }    
}
