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
    
    @IBOutlet weak var mainView: UIView?
    
    override func viewDidLoad() {

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mainView?.addSubview(createBackButton())
    }
}
