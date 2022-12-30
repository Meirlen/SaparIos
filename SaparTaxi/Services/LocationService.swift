//
//  LocationService.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import CoreLocation

typealias LocationBlock = (CLLocation?) -> Void

class LocationService: NSObject {

    static let shared = LocationService()
    
    private lazy var manager: CLLocationManager = {
        let result = CLLocationManager()
        result.delegate = self
        return result
    }()
    
    var permission: CLAuthorizationStatus {
        return manager.authorizationStatus
    }
    
    private var completion: LocationBlock?
    
    func requestPermission() {
        if permission == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
    }
    
    func requestLocation(completion: @escaping LocationBlock) {
        if permission == .denied || permission == .restricted {
            completion(nil)
            return
        }
        
        self.completion = completion
        if permission == .notDetermined {
            requestPermission()
        } else {
            manager.requestLocation()
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.last)
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let block = completion else { return }
        if permission == .denied || permission == .restricted {
            block(nil)
            completion = nil
        } else {
            requestLocation(completion: block)
        }
    }
}
