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
    
    func getPlaces(string: String, center: CLLocationCoordinate2D, completion:(([Location])->Void)?) {
        let delta = 0.3
        let boxStr = String(format: "%f,%f~%f,%f", center.latitude-delta, center.longitude-delta, center.latitude+delta, center.longitude+delta)
        guard var urlComp = URLComponents(string: "https://suggest-maps.yandex.ru/suggest-geo") else { return }
        urlComp.queryItems = [
            URLQueryItem(name: "apikey", value: "a4018892-4411-4709-97ea-6881ac674715"),
            URLQueryItem(name: "v", value: "7"),
            URLQueryItem(name: "search_type", value: "all"),
            URLQueryItem(name: "lang", value: "ru_RU"),
            URLQueryItem(name: "n", value: "50"),
            URLQueryItem(name: "bbox", value: boxStr),
            URLQueryItem(name: "part", value: string),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = urlComp.url else { return }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, var str = String(data: data, encoding: .utf8) else {
                completion?([])
                return
            }
            str.removeFirst(14) //suggest.apply(
            str.removeLast()
             
            let decoder = JSONDecoder()
            let response = try? decoder.decode(PlacesResponse.self, from: Data(str.utf8))
            completion?(response?.locations ?? [])
        }
        task.resume()
    }
}

struct PlacesResponse: Codable {
    var part: String
    var results: [Place]
    
    var locations: [Location] {
        return results.map { place in
            Location(coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon), address: place.name)
        }
    }
}

struct Place: Codable {
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
