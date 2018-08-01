//
//  ViewController.swift
//  Companion
//
//  Created by David Huang on 4/13/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit

struct MapsResponse: Decodable {
    let status: String
    let routes: [Routes] // array of routes
    
    struct Routes: Decodable {
        let summary: String
        let legs: [Legs] // array of legs
        
        struct Legs: Decodable {
            let duration: Duration
            
            struct Duration: Decodable {
                let value: Double
                let text: String // text value of travel time
            }
        }
    }
}

class ViewController: UIViewController {
    //MARK: Properties
    var selectedBaseIndex: Int = 0;
    var bases = [Base]()
    var access_token: String?
    var refresh_token: String?
    var expires_in: Int?
    
    @IBOutlet weak var baseFButton: UIButton!
    @IBOutlet weak var baseSButton: UIButton!
    @IBOutlet weak var baseTButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSamples()
        updateButtonLabels()
    }
    
    //MARK: Actions
    @IBAction func activateBaseF(_ sender: UIButton) { selectedBaseIndex = 0 }
    @IBAction func activateBaseS(_ sender: UIButton) { selectedBaseIndex = 1 }
    @IBAction func activateBaseT(_ sender: UIButton) { selectedBaseIndex = 2 }
    
    @IBAction func unwindToHome(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? BaseViewController, let base = sourceViewController.base {
            bases[selectedBaseIndex] = base
            updateButtonLabels()
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let baseDetailViewController = segue.destination as? BaseViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        guard let selectedBaseButton = sender as? UIButton else {
            fatalError("Unexpected sender: \(String(describing: sender))")
        }
        var index: Int = 0
        if (selectedBaseButton.tag == senderButtonTag.First.rawValue) {
            index = senderButtonTag.First.rawValue
        } else if (selectedBaseButton.tag == senderButtonTag.Second.rawValue) {
            index = senderButtonTag.Second.rawValue
        } else if (selectedBaseButton.tag == senderButtonTag.Third.rawValue) {
            index = senderButtonTag.Third.rawValue
        }
        // The user used to be able to add Bases, but this feture is gone now
        if index < bases.count {
            baseDetailViewController.base = bases[index]
        } else {
            baseDetailViewController.base = Base(title: "", address: nil, city: nil, state: nil, zip: nil, placeID: nil)
        }
    }
    
    //MARK: Private Functions
    private func loadSamples() {
        guard let base1 = Base(title: "Home", address: "4828 S 194th Ave", city: "Omaha", state: "NE", zip: "68135",
                               placeID: nil) else {
            fatalError("Could not instantiate base1 object")
        }
        guard let base2 = Base(title: "Dorm", address: "6515 Wydown Blvd", city: "St. Louis", state: "MO", zip: "63105",
                               placeID: nil) else {
            fatalError("Could not instantiate base2 object")
        }
        guard let base3 = Base(title: "Empty Base", address: nil, city: nil, state: nil, zip: nil, placeID: nil) else {
            fatalError("Could not instantiate base2 object")
        }
        bases = [base1, base2, base3]
    }
    
    private func updateButtonLabels() {
        var title = ""
        if (!bases.isEmpty) {
            title = bases[0].title
        } else {
            title = "Empty Base"
        }
        baseFButton.setTitle(title, for: .normal)
        if (!bases.isEmpty) {
            title = bases[1].title
        } else {
            title = "Empty Base"
        }
        baseSButton.setTitle(title, for: .normal)
        if (!bases.isEmpty) {
            title = bases[2].title
        } else {
            title = "Empty Base"
        }
        baseTButton.setTitle(title, for: .normal)
    }
}
