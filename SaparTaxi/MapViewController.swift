//
//  ViewController.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import UIKit
import MapboxMaps

class MapViewController: UIViewController {

    private var mapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MapView(frame: view.bounds, mapInitOptions: MapInitOptions())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(mapView, at: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLocation()
    }
    
    //MARK: -
    
    @IBAction func getFreshLocation() {
        updateLocation()
    }
    
    private func updateLocation() {
        LocationService.shared.requestLocation { [weak self] location in
            if let coord = location?.coordinate {
                let options = CameraOptions(center: coord)
                self?.mapView.mapboxMap.setCamera(to: options)
            }
        }
    }
}

