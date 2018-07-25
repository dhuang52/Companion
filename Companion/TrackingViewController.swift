//
//  TrackingViewController.swift
//  Companion
//
//  Created by David Huang on 4/25/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit
import CoreLocation
import Locksmith

struct RefreshToken: Decodable {
    let access_token: String
    let expires_in: Int
}

struct Alarm: Decodable {
    let id: String
    let status: String
    let services: Services
    let locations: LocationCoordinates
    let created_at: String
    
    struct Services: Decodable {
        let police: Bool
        let fire: Bool
        let medical: Bool
    }
    struct LocationCoordinates: Decodable {
        struct Coordinates: Decodable {
            let lat: Double
            let lng: Double
            let accuracy: Int
        }
        let coordinates: [Coordinates]
    }
}

class TrackingViewController: UIViewController {
    
    @IBOutlet weak var arrived: UIButton!
    var base: Base?
    var lattitude: Double?
    var longitude: Double?
    var timer = Timer()
    var didNotArrive: Bool = false
    var alarm: Alarm?
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        self.arrived.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // time it takes to travel from current location to the Base
    func startTimer(timeInterval: TimeInterval) {
        print("starting timer")
        DispatchQueue.main.async { // Timers need to be run on a run loop on the main thread
            self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: (#selector(TrackingViewController.checkLocation)), userInfo: nil, repeats: false)
        }
    }
    
    // A leniency period for the user to press arrived
    func startAlarmTimer(timeInterval: TimeInterval) {
        print("starting alarm timer")
        DispatchQueue.main.async { // Timers need to be run on a run loop on the main thread
            self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: (#selector(TrackingViewController.setupAlarm)), userInfo: nil, repeats: false)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: Action
    @IBAction func cancel(_ sender: UIButton) {
        self.destroyTimers()
        if(alarm != nil) {
            self.cancelAlarm()
        }
        dismiss(animated: true, completion: nil)
    }
    @IBAction func confirmArrived(_ sender: UIButton) {
        self.destroyTimers()
        if(alarm != nil) {
            self.cancelAlarm()
        }
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Private Functions
    private func startTracking() {
        // locationManager.requestLocation()
        // need to put guards around this, not safe
        base?.getDuration(originLat: self.lattitude!, originLong: self.longitude!, completion: { (duration) -> Void in
            let durationSec: Double = duration.value
            self.startTimer(timeInterval: 1) // for debugging purposes
        })
    }
    
    // will create a handler for this function soon
    private func createAlarm() -> Bool {
        print("========== createAlarm ==========")
        guard let lat = self.lattitude else {
            return false
        }
        guard let lng = self.longitude else {
            return false
        }
        let url = URL(string: "https://api-sandbox.safetrek.io/v1/alarms")
        // in event of road accident, Police and Medical services seem most appropriate
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let params = [
            "services" : [
                "police" : true,
                "fire": false,
                "medical": true
            ],
            "location.coordinates": [
                "lat": lat,
                "lng": lng,
                "accuracy": 5
            ]
        ]
        let access_dict = Locksmith.loadDataForUserAccount(userAccount: "user_access")
        if let access_token = access_dict!["access_token"] as? String {
            print("========== CONVERTED TO STRING ==========")
            print(access_token)
            request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        }
        let alarmData = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.httpBody = alarmData
        var requestSuccess = false
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                requestSuccess = false
                print(error!)
                return
            }
            guard let data = data else {
                requestSuccess = false
                print("Data is empty")
                return
            }
            guard let tokensjson = try? JSONDecoder().decode(Alarm.self, from: data) else {
                requestSuccess = false
                return
            }
            // should just use normal try with catch block
            self.alarm = try? JSONDecoder().decode(Alarm.self, from: data)
            print(self.alarm!.id)
            requestSuccess = true
            print(tokensjson)
        }
        task.resume()
        return requestSuccess
    }
    
    private func cancelAlarm() {
        let url = URL(string: "https://api-sandbox.safetrek.io/v1/alarms/" + self.alarm!.id + "/status")
        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"
        let access_dict = Locksmith.loadDataForUserAccount(userAccount: "user_access")
        if let access_token = access_dict!["access_token"] as? String {
            print("========== CONVERTED TO STRING ==========")
            print(access_token)
            request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "status": "CANCELED"
        ]
        let requestCancel = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.httpBody = requestCancel
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                fatalError("Could not convert response to JSON");
            }
            print("CANCELED")
            print(json)
        }
        task.resume()
    }
    
    private func getNewAccessToken() {
        print("========== getNewAccessToken ==========")
        let url = URL(string: "https://login-sandbox.safetrek.io/oauth/token")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let refresh_dict = Locksmith.loadDataForUserAccount(userAccount: "user_refresh")
        guard let refresh_token = refresh_dict!["refresh_token"] as? String else {
            fatalError("Could not convert refresh_token to string inside getNewAccessToken")
        }
        let params = [
            "grant_type": "refresh_token",
            "client_id": st_client_id,
            "client_secret": st_client_secret,
            "refresh_token": refresh_token
        ]
        let accessTokenRequest = try? JSONSerialization.data(withJSONObject: params, options: [])
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
            let tokensjson = try! JSONDecoder().decode(RefreshToken.self, from: data)
            do {
                try Locksmith.updateData(data: ["access_token": tokensjson.access_token], forUserAccount: "user_access")
                try Locksmith.updateData(data: ["expires_in": tokensjson.expires_in], forUserAccount: "user_expire")
            } catch {
                print("========= COULD NOT UPDATE TOKENS =========")
            }
            self.createAlarm()
        }
        task.resume()
    }
    
    @objc private func checkLocation() {
        // create prompt
        self.arrived.isHidden = false
        
        // start timer
        // 5 represents a leniency period for the user to press the Arrive button
        self.startAlarmTimer(timeInterval: 5)
        // if they confirm arrival:
            // leave page
        // otherwise
            // start alarm
    }
    
    @objc private func setupAlarm() {
        didNotArrive = true
        print("creating alarm")
        // gets user's current location
        locationManager.requestLocation()
    }
    
    private func destroyTimers() {
        DispatchQueue.main.async { // Be sure to destroy timer and thread it was created on
            print("timer invalidated")
            self.timer.invalidate()
        }
    }
}

extension TrackingViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lat = locations.last?.coordinate.latitude, let long = locations.last?.coordinate.longitude {
            self.lattitude = lat
            self.longitude = long
            if(didNotArrive) {
                let time_since = Date().timeIntervalSince1970 - UserDefaults.standard.double(forKey: "init_date")
                let expire_dictionary = Locksmith.loadDataForUserAccount(userAccount: "user_expire")
                if let expire_in = expire_dictionary!["expires_in"] as? Double {
                    if( time_since > expire_in ) {
                        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "init_date")
                        getNewAccessToken() // after refreshing access token, calls createAlarm within method
                    } else {
                        // return value from function will be used
                        createAlarm()
                    }
                }
            } else {
                startTracking()
            }
        } else {
            print("No coordinates")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
