//
//  UIUitls.swift
//  Companion
//
//  Created by David Huang on 7/31/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit

class UIUtils {
    
    static func createAlert(title: String, message: String, details: String?) -> UIAlertController {
        let formattedMessage = details != nil ? "\(message). \(details!)." : "\(message)."
        let alert = UIAlertController(title: title, message: formattedMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
            case .cancel:
                print("cancel")
            case .destructive:
                print("destructive")
            }}))
        return alert
    }
}
