//
//  BaseViewController.swift
//  Companion
//
//  Created by David Huang on 4/14/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit
import GooglePlaces

enum senderButtonTag: Int {
    case First
    case Second
    case Third
}

class BaseViewController: UIViewController, UITextFieldDelegate {
    //MARK: Properties
    @IBOutlet weak var baseTitleTextField: UITextField!
    @IBOutlet weak var baseAddressLabel: UILabel!
    @IBOutlet weak var baseZipCityStateLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var goButton: UIButton!
    
    var base: Base!
    
    // Declare variables to hold address form values from Google Places
    var street_number: String = ""
    var route: String = ""
    var neighborhood: String = ""
    var locality: String = ""
    var administrative_area_level_1: String = ""
    var country: String = ""
    var postal_code: String = ""
    var postal_code_suffix: String = ""
    var placeID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        baseTitleTextField.delegate = self
        baseTitleTextField.layer.masksToBounds = true
        baseTitleTextField.layer.cornerRadius = 5
        
        baseTitleTextField.text = self.base.title
        baseAddressLabel.text = self.base.address
        if self.base.city == "" || self.base.state == "" {
            baseZipCityStateLabel.text = self.base.zip!
        } else {
            baseZipCityStateLabel.text = self.base.zip! + " " + self.base.city! + ", " + self.base.state!
        }

        if(!(baseAddressLabel.text != nil) && (baseZipCityStateLabel.text != nil)) {
            self.goButton.isEnabled = false
        }
        self.hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hides keyboard
        baseTitleTextField.resignFirstResponder()
        // always want to respond to the user pressing the "return" key, so always return true
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) { }
    
    func textFieldDidEndEditing(_ textField: UITextField) { }
    
    //MARK: Navigation
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        base.title = baseTitleTextField.text! // saves any title changes
        if (segue.identifier ?? "" == "track") { // Base page -> track view controller
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let trakcingVC = navigationController.topViewController as? TrackingViewController else {
                fatalError("Unexpected View Controller: \(segue.destination)")
            }
            trakcingVC.base = base
        }
    }
    
    //MARK: Action
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: true)
        baseTitleTextField.text = base.title
    }
    
    @IBAction func editBase(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Set a filter to return only addresses.
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        autocompleteController.autocompleteFilter = filter
        
        present(autocompleteController, animated: true, completion: nil)
    }
    
    // needed for Go button to work
    @IBAction func track(_ sender: UIButton) {}

    // Populate the address form fields.
    func fillAddressForm() {
        base.address = street_number + " " + route
        base.city = locality
        base.state = administrative_area_level_1
        base.placeID = placeID
        if postal_code_suffix != "" {
            base.zip = postal_code + "-" + postal_code_suffix
        } else {
            base.zip = postal_code
        }
        baseAddressLabel.text = base.address
        
        if base.city == "" || base.state == "" {
            baseZipCityStateLabel.text = (base.zip)!
        } else {
            baseZipCityStateLabel.text = (base.zip)! + " " + (base.city)! + ", " + (base.state)! // ZIP City, State
        }
        
        // Clear values for next time.
        street_number = ""
        route = ""
        neighborhood = ""
        locality = ""
        administrative_area_level_1  = ""
        country = ""
        postal_code = ""
        postal_code_suffix = ""
        placeID = ""
        self.goButton.isEnabled = true
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension BaseViewController: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // Print place info to the console.
        
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        placeID = place.placeID
        // Get the address components.
        if let addressLines = place.addressComponents {
            // Populate all of the address fields we can find.
            for field in addressLines {
                switch field.type {
                case kGMSPlaceTypeStreetNumber:
                    street_number = field.name
                case kGMSPlaceTypeRoute:
                    route = field.name
                case kGMSPlaceTypeNeighborhood:
                    neighborhood = field.name
                case kGMSPlaceTypeLocality:
                    locality = field.name
                case kGMSPlaceTypeAdministrativeAreaLevel1:
                    administrative_area_level_1 = field.name
                case kGMSPlaceTypeAdministrativeAreaLevel3:
                    if(locality == "") {
                        locality = field.name
                    }
                case kGMSPlaceTypeCountry:
                    country = field.name
                case kGMSPlaceTypePostalCode:
                    postal_code = field.name
                case kGMSPlaceTypePostalCodeSuffix:
                    postal_code_suffix = field.name
                // Print the items we aren't using.
                default:
                    print("Type: \(field.type), Name: \(field.name)")
                }
            }
        }
        
        // Call custom function to populate the address form.
        fillAddressForm()
        
        // Close the autocomplete widget.
        self.dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Show the network activity indicator.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // Hide the network activity indicator.
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
