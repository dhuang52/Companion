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
        self.placeID = placeID
    }
    
    func getDuration(originLat: Double, originLong: Double, onFail: @escaping () -> Void, completion: @escaping (MapsResponse.Routes.Legs.Duration) -> Void) {
        let url: String
        if let placeID = self.placeID {
            url = "\(devURLs().directions)/json?origin=\(String(originLat)),\(String(originLong))&destination=place_id:\(placeID)&key=\(google_api_key)"
            print(url)
        } else {
            guard let address = self.address else {
                fatalError("Missing address and place ID")
            }
            url = "\(devURLs().directions)/json?origin=\(String(originLat)),\(String(originLong))&destination=\(formatAddress(address: address))&key=\(google_api_key)"
        }
        HTTPRequestUtils.directionsRequest(url: url, onFail: { () in
            // completion handler within completionhandler, messy, needs to be changed
            onFail()
        }) { (directionsJson) in
            print(directionsJson)
            if (directionsJson.status == "OK") {
                // completion handler within completionhandler, messy, needs to be changed
                completion(directionsJson.routes[0].legs[0].duration)
            }
        }
    }
    
    //MARK: Private Functions
    private func formatAddress(address: String)->String {
        return address.replacingOccurrences(of: " ", with: "+")
    }
}
