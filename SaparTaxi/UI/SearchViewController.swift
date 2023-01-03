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
    @IBOutlet weak var searchAddress: UISearchBar?
    @IBOutlet weak var resaltSearchTableView: UITableView?
    
    let indentifire = "ResultSearchCell"
    var part: String?
    
    var completion: ((Place)->Void)?
    
    override func viewDidLoad() {
        self.searchAddress?.delegate = self
        resaltSearchTableView?.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mainView?.addSubview(createBackButton())
    }
    
    func finish(place: Place) {
        completion?(place)
        completion = nil
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        part = searchText
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
//        return datasource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: indentifire, for: indexPath)
        let resultCell = cell as? ResultSearchCell
        return cell
    }
}

class ResultSearchCell: UITableViewCell {
    @IBOutlet weak var addressLabel: UILabel?
    @IBOutlet weak var fullAddressLabel: UILabel?    
}
