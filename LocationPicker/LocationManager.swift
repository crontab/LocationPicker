//
//  LocationManager.swift
//  LocationPicker
//
//  Created on 29/05/2019.
//  Copyright © 2019 Hovik Melikyan. All rights reserved.
//

import Foundation
import CoreLocation


class LocationManager: CLLocationManager, CLLocationManagerDelegate {

	class func request(completion: @escaping (CLLocation?, Error?) -> Void) {
		var manager: LocationManager! = LocationManager()
		manager.delegate = manager
		manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		manager.requestLocation { (location, error) in
			// A trick to retain the manager while in use
			manager = nil
			completion(location, error)
		}
	}


	deinit {
		print("LocationManager: deinit")
	}


	private var completion: ((CLLocation?, Error?) -> Void)? = nil


	override init() {
	}


	private func requestLocation(completion: @escaping (CLLocation?, Error?) -> Void) {
		switch CLLocationManager.authorizationStatus() {

		case .notDetermined:
			self.completion = completion
			requestWhenInUseAuthorization()
			break

		case .restricted, .denied:
			completion(nil, NSError(domain: "com.melikyan.LocationManager", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))

		case .authorizedWhenInUse, .authorizedAlways:
			self.completion = completion
			requestLocation()
			break

		@unknown default:
			fatalError()
		}
	}


	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		if let completion = self.completion {
			self.completion = nil
			completion(nil, error)
		}
	}


	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let completion = self.completion {
			self.completion = nil
			completion(locations.first, nil)
		}
	}
}

