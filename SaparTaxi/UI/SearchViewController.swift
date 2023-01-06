//
//  SearchViewController.swift
//  Sappar
//
//  Created by Max on 31.12.2022.
//

import Foundation
import UIKit
import CoreLocation

@objc(SearchViewController)
class SearchViewController: UIViewController {    
    
    @IBOutlet weak var mainView: UIView?
    @IBOutlet weak var searchAddress: UISearchBar?
    @IBOutlet weak var resaltSearchTableView: UITableView?
    
    let indentifire = "ResultSearchCell"
   
    var addresses = [Location]() {
        didSet {
            DispatchQueue.main.async {
                self.resaltSearchTableView?.reloadData()
            }
        }
    }
    
    var completion: ((Location)->Void)?
    var location: Location?
    
    var timer = Timer()
    let delay = 0.5
    var textSearch: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchAddress?.text = location?.address
        searchAddress?.delegate = self
        resaltSearchTableView?.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mainView?.addSubview(createBackButton())
    }
    
    @objc func geocodingRequest() {
        guard let coordinate = location?.coordinate, let textSearch = textSearch else { return }
        GeocodingService.getPlaces(string: textSearch, center: coordinate) { [weak self] (locations) in
            self?.addresses = locations
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(geocodingRequest), userInfo: nil, repeats: false)

        textSearch = searchText
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: indentifire, for: indexPath)
        let resultCell = cell as? ResultSearchCell
        let address = addresses[indexPath.row]
        
        resultCell?.addressLabel?.text = address.address
        resultCell?.fullAddressLabel?.text = address.desc
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = addresses[indexPath.row]
        completion?(address)
        navigationController?.popViewController(animated: true)
    }
}

class ResultSearchCell: UITableViewCell {
    @IBOutlet weak var addressLabel: UILabel?
    @IBOutlet weak var fullAddressLabel: UILabel?    
}
