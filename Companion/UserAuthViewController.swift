//
//  UserAuthViewController.swift
//  Companion
//
//  Created by David Huang on 4/18/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit
import SafariServices
import Locksmith

struct Tokens: Decodable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
}

func getQueryStringParameter(url: String, param: String) -> String? {
    guard let url = URLComponents(string: url) else { return nil }
    return url.queryItems?.first(where: { $0.name == param })?.value
}

class UserAuthViewController: UIViewController {
    
    let urls = devURLs()
    var authSession: SFAuthenticationSession?
    var access_token: String?
    var refresh_token: String?
    var expires_in: Int?
    
    // UNSAFE
    let client_id: String = st_client_id
    let client_secret: String = st_client_secret
    let redirect_uri: String = "companion://oauth"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // for debugging purposes
        do {
            print("======== DELETING REFRESH TOKEN ========")
            try Locksmith.deleteDataForUserAccount(userAccount: "user_refresh")
            print("======== DELETING ACCESS TOKEN ========")
            try Locksmith.deleteDataForUserAccount(userAccount: "user_access")
            print("======== DELETING EXPIRES IN ========")
            try Locksmith.deleteDataForUserAccount(userAccount: "user_expire")
        } catch {
            print("======== UNABLE TO DELETE TOKENS ========")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Navigation
    private func toBases() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "newNavigationController") as! UINavigationController
        self.present(newViewController, animated: true, completion: nil)
    }
    
    //MARK: Actions
    @IBAction func authUser(_ sender: UIButton) {
        if( Locksmith.loadDataForUserAccount(userAccount: "user_access") != nil &&
            Locksmith.loadDataForUserAccount(userAccount: "user_refresh") != nil) {
            print("============== TOKENS ALREADY SAVED, MOVING TO NEXT VIEW ==============")
            self.toBases()
        } else {
            let scope: String = "openid%20phone%20offline_access"
            let response_type: String = "code"
            
            let url: String = "\(urls.authorize)?client_id=\(client_id)&scope=\(scope)&response_type=\(response_type)&redirect_uri=\(redirect_uri)"

            guard let authURL = URL(string: url) else {
                fatalError("Could not convert to URL when authenticating user")
            }
            self.authSession = SFAuthenticationSession(url: authURL, callbackURLScheme: redirect_uri,
                                                       completionHandler: { (callBack:URL?, error: Error?) in
                guard error == nil, let successURL = callBack else {
                    print("ERROR", error!)
                    return
                }
                guard let authorizationCode = getQueryStringParameter(url: successURL.absoluteString,
                                                                      param: "code") else {
                    fatalError("Could not get authorization code")
                }
                self.getAccessToken(authorizationCode: authorizationCode)
            })
            self.authSession?.start()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        guard let viewController = segue.destination as? ViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
//        viewController.access_token = UserAuthViewController.access_token
//        viewController.refresh_token = UserAuthViewController.refresh_token
//        viewController.expires_in = UserAuthViewController.expires_in
    }
 */
    
    //MARK: Private Functions
    private func createAlert(title: String, message: String, details: String?) {
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
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getAccessToken(authorizationCode: String) {
        // STEP 3: RETRIEVING AN ACCESS TOKEN
        let url = URL(string: urls.tokens)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let params = [
            "grant_type" : "authorization_code",
            "code": authorizationCode,
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": redirect_uri
        ]
        guard let accessTokenRequest = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            fatalError("could not convert parameters to JSON")
        }
        request.httpBody = accessTokenRequest

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            if let tokensjson = try? JSONDecoder().decode(Tokens.self, from: data) {
                self.access_token = tokensjson.access_token
                self.refresh_token = tokensjson.refresh_token
                self.expires_in = tokensjson.expires_in
            } else {
                guard let tokensjson = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
                    fatalError("Received an unexpected JSON format")
                }
                self.createAlert(title: "Error \(tokensjson.code)", message: tokensjson.message, details: tokensjson.details)
            }
            
            do {
                print("============== SAVING TOKENS TO KEYCHAIN ==============")
                try Locksmith.saveData(data: ["refresh_token": self.refresh_token!], forUserAccount: "user_refresh")
                try Locksmith.saveData(data: ["access_token": self.access_token!], forUserAccount: "user_access")
                try Locksmith.saveData(data: ["expires_in": self.expires_in!], forUserAccount: "user_expire")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "init_date")
                // need to move this outside
                self.toBases()
            } catch {
                self.createAlert(title: "Error",message: "Could not save credentials", details: nil);
            }
        }
        task.resume()
//        self.toBases()
    }
}
