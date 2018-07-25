//
//  Base.swift
//  Companion
//
//  Created by David Huang on 4/13/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit
import os.log

class Base: NSObject {
    //MARK: Properties
    var title: String
    var address: String?
    var city: String?
    var state: String?
    var zip: String?
    var placeID: String?
    
    init?(title: String, address: String?, city: String?, state: String?, zip: String?, placeID: String?) {
        guard !title.isEmpty else {
            return nil
        }
        self.title = title
        if address == nil {
            self.address = address
        } else {
            self.address = address!.trimmingCharacters(in: .whitespaces)
        }
        self.city = city ?? ""
        self.state = state ?? ""
        self.zip = zip ?? ""
        self.placeID = placeID ?? ""
    }
    
    //MARK: Private Functions
    private func formatAddress(address: String)->String {
        return address.replacingOccurrences(of: " ", with: "+")
    }
    
    func getDuration(originLat: Double, originLong: Double, completion: @escaping (MapsResponse.Routes.Legs.Duration) -> Void) {
        var duration: MapsResponse.Routes.Legs.Duration?
        var requestURL = ""
        let key = google_api_key
        if !((self.placeID?.isEmpty)!) { // use placeID
            requestURL = "https://maps.googleapis.com/maps/api/directions/json?origin=" + String(originLat) + "," + String(originLong) + "&destination=place_id:" + (self.placeID!) + "&key=" + key
        } else { // use actual address
            requestURL = "https://maps.googleapis.com/maps/api/directions/json?origin=" + String(originLat) + "," +
                String(originLong) + "&destination=" + formatAddress(address: self.address!) + "&key=" + key
        }
        
        guard let url = URL(string: requestURL) else {
            fatalError("Could not convert to URL")
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                fatalError("Could not set data")
            }
            do {
                let base = try JSONDecoder().decode(MapsResponse.self, from: data)
                print("=============GOOGLE MAPPS API RESPONSE=============")
                print(base)
                print("=============STATUS=============")
                print(base.status)
                if base.status == "OK" {
                    duration = base.routes[0].legs[0].duration
                    completion(duration!)
                } else {
                    //                    var alertTitle: String = ""
                    //                    var alertMessage: String = ""
                    if base.status == "NOT_FOUND" {
                        
                    } else if base.status == "ZERO_RESULTS" {
                        
                    } else if base.status == "INVALID_REQUEST" {
                        
                    }
                }
            } catch let jsonErr {
                print("Error serializing json", jsonErr)
            }
        }
        task.resume()
    }
}
