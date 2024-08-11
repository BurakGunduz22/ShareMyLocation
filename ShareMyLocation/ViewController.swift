import UIKit
import Alamofire
import CoreLocation
import ContactsUI

class ViewController: UIViewController, CLLocationManagerDelegate, CNContactPickerDelegate {

    // Your Twilio credentials
    let accountSID = "accountSID"
    let authToken = "authToken"
    let twilioPhoneNumber = "+twilioPhoneNumber"

    var locationManager: CLLocationManager!
    var geocoder: CLGeocoder!
    var selectedPhoneNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Initialize Geocoder
        geocoder = CLGeocoder()
    }
    
    // MARK: - Location Handling
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocode location to get address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocode failed with error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                // Construct message with address
                if let address = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    let fullAddress = address.joined(separator: ", ")
                    let message = "Güncel Konum: \(fullAddress)"
                    
                    // Send SMS with location details to the selected contact
                    if let phoneNumber = self.selectedPhoneNumber {
                        self.sendSMSTwilio(message: message, to: phoneNumber)
                    } else {
                        print("No selected phone number")
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    // MARK: - Actions
    
    @IBAction func selectContact(_ sender: UIButton) {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        present(contactPicker, animated: true, completion: nil)
    }
    
    // MARK: - CNContactPickerDelegate
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else {
            print("Selected contact does not have a phone number")
            return
        }
        
        // Set selected phone number
        selectedPhoneNumber = phoneNumber
        
        // Request location immediately after selecting contact
        locationManager.requestLocation()
        
        // Dismiss contact picker
        dismiss(animated: true, completion: nil)
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Twilio SMS
    
    func sendSMSTwilio(message: String, to phoneNumber: String) {
        let parameters: [String: Any] = [
            "From": twilioPhoneNumber,
            "To": phoneNumber,
            "Body": message
        ]
        
        let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages.json"
        
        AF.request(url, method: .post, parameters: parameters)
            .authenticate(username: accountSID, password: authToken)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Message sent successfully: \(value)")
                case .failure(let error):
                    print("Error sending message: \(error)")
                }
            }
    }
}
