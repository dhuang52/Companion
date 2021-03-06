//
//  errorResponse.swift
//  Companion
//
//  Created by David Huang on 7/30/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import Foundation

struct ErrorResponse: Decodable {
    let code: Int
    let message: String
    let details: String
}
