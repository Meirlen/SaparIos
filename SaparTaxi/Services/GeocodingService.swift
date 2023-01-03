//
//  GeocodingService.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import CoreLocation

class GeocodingService: NSObject {

    static let shared = GeocodingService()
    private var geocoder = CLGeocoder()
    
    func getAddress(coordinate: CLLocationCoordinate2D, completion:((CLLocationCoordinate2D, String?)->Void)?) {
        //TODO: Cache & round
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemarks = placemarks else {
                completion?(coordinate, nil)
                return
            }
            var result: String?
            for pl in placemarks {
                if let addr = pl.fullAddress {
                    result = addr
                    break
                }
            }
            completion?(coordinate, result)
        }
        
    }
    
    func getPlaces(string: String, completion:(([Location])->Void)?) {
//        geocoder.geocodeAddressString(<#T##addressString: String##String#>, completionHandler: <#T##CLGeocodeCompletionHandler##CLGeocodeCompletionHandler##([CLPlacemark]?, Error?) -> Void#>)
        
        /*
         curl --location --request GET 'https://suggest-maps.yandex.ru/suggest-geo?apikey=a4018892-4411-4709-97ea-6881ac674715&v=7&search_type=all&lang=ru_RU&n=50&bbox=71.18039008452863,50.90665734917379~71.71611852833287,51.29543426733995&part=абая'
         */
    }
}

struct Place {
    var name: String
    var desc: String
    var lat: Double
    var lon: Double
}

extension CLPlacemark {
    var fullAddress: String? {
        let components = [name, thoroughfare, subThoroughfare, subLocality ?? locality, subAdministrativeArea ?? administrativeArea]
        let result = components.compactMap({$0}).joined(separator: ", ")
        return result.count > 0 ? result : nil
    }
}
