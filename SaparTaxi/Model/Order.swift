//
//  Order.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import CoreLocation

struct Location {
    let coordinate: CLLocationCoordinate2D
    let address: String
}

enum CarType {
    case standard
    case comfort
}

enum OrderState {
    case new
    case search
    case wait
    case arrived
}

class Order: NSObject {

    var state = OrderState.new
    
    var startLocation: Location?
    var destinations = [Location]()
    var type = CarType.standard
    var price: Double = 0
    
    var driver: String?
    var driverCoord: CLLocationCoordinate2D?
}
