//
//  SearchViewController.swift
//  Sappar
//
//  Created by Max on 31.12.2022.
//

import Foundation
import UIKit

@objc(SearchViewController)
class SearchViewController: UIViewController {    
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        navigationController?.isNavigationBarHidden = false
        
        navigationItem.leftBarButtonItem = createBackButton()
    }
}
