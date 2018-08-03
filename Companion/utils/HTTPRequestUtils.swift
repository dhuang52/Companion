//
//  HTTPRequestUtils.swift
//  Companion
//
//  Created by David Huang on 8/1/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit

class HTTPRequestUtils {
    
    static func getAccessToken<T: Decodable>(url: String, authorizationCode: String, responseType: T.Type, onFail: @escaping (ErrorResponse) -> Void, completion: @escaping (T) -> Void) {
        
        let params = [
            "grant_type" : "authorization_code",
            "code": authorizationCode,
            "client_id": safetrek_client_id,
            "client_secret": safetrek_client_secret,
            "redirect_uri": "companion://oauth"
        ]
        guard let accessTokenData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            fatalError("Could not convert parameters for Access Token request to JSON")
        }
        
        guard let requestURL = URL(string: url) else {
            return
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = accessTokenData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            
            if let tokensjson = try? JSONDecoder().decode(responseType.self, from: data) {
                completion(tokensjson)
            } else {
                guard let errorjson = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
                    fatalError("Received an unexpected JSON format")
                }
                onFail(errorjson)
            }
        }
        task.resume()
    }
    
    static func refreshAccessToken<T: Decodable>(url: String, responseType: T.Type, onFail: @escaping (ErrorResponse) -> Void, completion: @escaping (T) -> Void) {
        
        guard let refresh_token = KeychainUtils.getRefreshToken() else {
            fatalError("Unable to get refresh token")
        }
        let params = [
            "grant_type": "refresh_token",
            "client_id": safetrek_client_id,
            "client_secret": safetrek_client_secret,
            "refresh_token": refresh_token
        ]
        guard let refreshData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            fatalError("uh oh")
        }
        
        guard let requestURL = URL(string: url) else {
            return
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = refreshData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            
            if let tokensjson = try? JSONDecoder().decode(responseType.self, from: data) {
                completion(tokensjson)
            } else {
                guard let errorjson = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
                    fatalError("Received an unexpected JSON format")
                }
                onFail(errorjson)
            }
        }
        task.resume()
    }
    
    static func request<T: Decodable>(requestType: String?, url: String, body: Data?, responseType: T.Type, onFail: @escaping (ErrorResponse) -> Void, completion: @escaping (T) -> Void) {
        guard let requestURL = URL(string: url) else {
            return
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = requestType
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let access_token = KeychainUtils.getAccessToken() else {
            fatalError("Unable to get access token")
        }
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }

            if let tokensjson = try? JSONDecoder().decode(responseType.self, from: data) {
                completion(tokensjson)
            } else {
                guard let errorjson = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
                    fatalError("Received an unexpected JSON format")
                }
                onFail(errorjson)
            }
        }
        task.resume()
    }
    
    static func directionsRequest(url: String, onFail: @escaping () -> Void, completion: @escaping (MapsResponse) -> Void) {
        guard let requestURL = URL(string: url) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            
            if let tokensjson = try? JSONDecoder().decode(MapsResponse.self, from: data) {
                completion(tokensjson)
            } else {
                onFail()
            }
        }
        task.resume()
    }
}
