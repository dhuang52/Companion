//
//  HTTPRequestUtils.swift
//  Companion
//
//  Created by David Huang on 8/1/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit

class HTTPRequestUtils {
    
    static func request<T: Decodable>(requestType: String, url: String, body: Data, responseType: T.Type, onFail: @escaping (ErrorResponse) -> Void, completion: @escaping (T) -> Void) {
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
}
