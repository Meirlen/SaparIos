//
//  ApiService.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import CoreLocation
import Polyline

struct TaxiService: Codable {
    var name: String?
    var price: Double
    var oneOffer = true
}

struct Price: Codable {
    var price: String
}

struct PaymentRequestPoint: Codable {
    let short_text: String
    let fullname: String
    let geo_point: [Double]
    let type: String
    let city: String
}


struct PaymentRequest: Codable {
    let route: [PaymentRequestPoint]
}

//MARK: -

class ApiService: NSObject {
    static let basePath = "http://165.22.13.172:8000/"
    
    static func estimateOrder(locations: [Location], completion:(([TaxiService])->Void)?) {
        guard locations.count >= 2 else {
            completion?([])
            return
        }
        
        let points = locations.map { location in
            let pointCoord = [location.coordinate.latitude, location.coordinate.longitude]
            return PaymentRequestPoint(short_text: location.address, fullname: location.desc, geo_point: pointCoord, type: "geo", city: "Караганда")
        }
        
        
        let requestData = PaymentRequest(route: points)
        
        let data = try? JSONEncoder().encode(requestData)
        
        let path = "mobile/order/estimate"
        guard let url = URL(string: basePath+path), let data = data else {
            completion?([])
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?([])
                }
                return
            }
            
            let decoder = JSONDecoder()
            let response = try? decoder.decode([String:[Price]].self, from: data)
            var result = [TaxiService]()
            response?.forEach({ (key, value) in
                if let item = value.first, let price = Double(item.price.filter("0123456789.,".contains)), price.isNormal, !price.isNaN, price.isFinite {
                    var service = TaxiService(name: key, price: price)
                    service.oneOffer = (value.count == 1)
                    result.append(service)
                }
            })
            DispatchQueue.main.async {
                completion?(result)
            }
        }
        task.resume()
    }
    
    static func getAddress(coordinate: CLLocationCoordinate2D, completion:((CLLocationCoordinate2D, String?)->Void)?) {
        //TODO: Cache & round
        let dict = ["lat": coordinate.latitude, "lon": coordinate.longitude]
        let data = try? JSONSerialization.data(withJSONObject: dict)
        
        let path = "order/geocode"
        guard let url = URL(string: basePath+path), let data = data else {
            completion?(coordinate, nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?(coordinate, nil)
                }
                return
            }
            
            let decoder = JSONDecoder()
            let response = try? decoder.decode([String:String].self, from: data)
            let addr = response?["text"]
            DispatchQueue.main.async {
                completion?(coordinate, addr)
            }
        }
        task.resume()
    }
}

//MARK: -

struct Route: Codable {
    var geometry: String
}

struct RouteResponse: Codable {
    var routes: [Route]
}

class OpenStreetMapService {
    //http://project-osrm.org/docs/v5.7.0/api/?language=Objective-C#general-options
    static func getRoute(locations: [Location], completion:(([CLLocationCoordinate2D])->Void)?) {
        
        let locationStrings = locations.map { location in
            let coord = location.coordinate
            return String(format: "%f,%f", coord.longitude, coord.latitude)
        }
        let path = locationStrings.joined(separator: ";")
        
        guard var urlComp = URLComponents(string: "http://router.project-osrm.org/route/v1/driving/"+path) else { return }
        urlComp.queryItems = [
            URLQueryItem(name: "alternatives", value: "true"),
            URLQueryItem(name: "geometries", value: "polyline")
        ]
        guard let url = urlComp.url else { return }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?([])
                }
                return
            }
             
            let decoder = JSONDecoder()
            let response = try? decoder.decode(RouteResponse.self, from: data)
            let routeStr = response?.routes.first?.geometry ?? ""
            let polyline = Polyline(encodedPolyline: routeStr)
            let coords = polyline.coordinates ?? []
            DispatchQueue.main.async {
                completion?(coords)
            }
        }
        task.resume()
    }
}
