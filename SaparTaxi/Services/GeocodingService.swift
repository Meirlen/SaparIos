//
//  GeocodingService.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import CoreLocation

class GeocodingService: NSObject {

    static let addressPlaceholder = "неизвестное место"
    
    static func getAddress(coordinate: CLLocationCoordinate2D, completion:((CLLocationCoordinate2D, String?)->Void)?) {
        //TODO: Cache & round
        ApiService.getAddress(coordinate: coordinate, completion: completion)
    }
    
    static func getPlaces(string: String, center: CLLocationCoordinate2D?, completion:(([Location])->Void)?) {
        let boxStr = "71.18039008452863,50.90665734917379~71.71611852833287,51.29543426733995"
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
                DispatchQueue.main.async {
                    completion?([])
                }
                
                return
            }
            str.removeFirst(14) //suggest.apply(
            str.removeLast()
             
            let decoder = JSONDecoder()
            let response = try? decoder.decode(PlacesResponse.self, from: Data(str.utf8))
            DispatchQueue.main.async {
                completion?(response?.locations ?? [])
            }
        }
        task.resume()
    }
}

//MARK: -

struct PlacesResponse: Codable {
    var part: String
    var results: [Place]
    
    var locations: [Location] {
        return results.compactMap { place in
            guard let coord = place.coordinate, place.insideKrg else { return nil }
            let desc = place.desc ?? ""
            return Location(coordinate: coord, address: place.name, desc: desc)
        }
    }
}

struct Place: Codable {
    var name: String
    var desc: String?
    var lat: Double?
    var lon: Double?
    
    var insideKrg: Bool {
        guard let coord = coordinate else { return false }
        let minLat = 49.67348
        let maxLat = 50.15371
        let minLon = 72.84576
        let maxLon = 73.442825
        return (coord.latitude <= maxLat && coord.latitude >= minLat) && (coord.longitude <= maxLon && coord.longitude >= minLon)
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lon = lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

extension CLPlacemark {
    var fullAddress: String? {
        let components = [name, thoroughfare, subThoroughfare, subLocality ?? locality, subAdministrativeArea ?? administrativeArea]
        let result = components.compactMap({$0}).joined(separator: ", ")
        return result.count > 0 ? result : nil
    }
}
