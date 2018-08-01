//
//  KeychainUtils.swift
//  Companion
//
//  Created by David Huang on 7/31/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit
import Locksmith

class KeychainUtils {
    
    static func getAccessToken()->String? {
        let access_dict = Locksmith.loadDataForUserAccount(userAccount: "user_access")
        guard let access_token = access_dict!["access_token"] as? String else {
            print("UNABLE TO CONVERT ACCESS TOKEN TO STRING")
            return nil
        }
        print("CONVERTED ACCESS TOKEN TO STRING")
        return access_token
    }
    
    static func getRefreshToken()->String? {
        let refresh_dict = Locksmith.loadDataForUserAccount(userAccount: "user_refresh")
        guard let refresh_token = refresh_dict!["refresh_token"] as? String else {
            print("UNABLE TO CONVERT REFRESH TOKEN TO STRING")
            return nil
        }
        return refresh_token
    }
}
