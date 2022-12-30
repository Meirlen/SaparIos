//
//  ViewController.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import UIKit
import MapboxMaps

class ViewController: UIViewController {

    private var mapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myResourceOptions = ResourceOptions(accessToken: "pk.eyJ1IjoibWVpcmxlbiIsImEiOiJjbDhmejY3Y3cwMXQzM3NwNGFuN2hwaW4yIn0.e6jsQjtaKQGtzM5ijU4oJQ")
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions)
        mapView = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
    }


}

