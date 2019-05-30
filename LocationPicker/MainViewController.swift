//
//  MainViewController.swift
//  LocationPicker
//
//  Created on 29/05/2019.
//  Copyright © 2019 Hovik Melikyan. All rights reserved.
//

import UIKit
import CoreLocation


class MainViewController: UIViewController, MapViewDelegate, MapViewAutocompleteDelegate {

	@IBOutlet weak var mapView: MapView!
	@IBOutlet weak var placeContainer: UIView!
	@IBOutlet weak var placeNameLabel: UILabel!
	@IBOutlet weak var placeAddr1Label: UILabel!


	private let defaultZoom: Float = 15
//	private let defaultCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 48.853169, longitude: 2.369080) // Place de la Bastille


	private var selectedPlace: Place? {
		didSet {
			placeInfoShown = selectedPlace != nil
			if let place = selectedPlace {
				placeNameLabel.text = place.poiName ?? (place.formattedAddress != nil ? "Address" : String(format: "%.5f,%.5f", place.coordinate.latitude, place.coordinate.longitude))
				placeAddr1Label.text = place.formattedAddress
				mapView.set(coordinate: place.coordinate, zoom: mapView.camera.zoom, animated: true)
			}
		}
	}


	private var placeInfoShown: Bool {
		get {
			return placeContainer.isHidden
		}
		set {
			guard newValue != !placeContainer.isHidden else {
				return
			}
			placeContainer.isHidden = false
			placeContainer.alpha = newValue ? 0 : 1
			UIView.animate(withDuration: 0.2, animations: {
				self.placeContainer.alpha = newValue ? 1 : 0
			}) { (finished) in
				if finished {
					self.placeContainer.isHidden = !newValue
				}
			}
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		mapView.initializeForPicker(delegate: self, autocompleteDelegate: self)

		LocationManager.request { (location, error) in
			if let error = error {
				print("LocationManager error: \(error)")
			}
			else if let location = location {
				self.mapView.set(coordinate: location.coordinate, zoom: self.defaultZoom, animated: false)
			}
		}

		placeContainer.isHidden = true
	}


	@IBAction func searchAction(_ sender: UIBarButtonItem) {
		mapView.launchAutocomplete(from: self, sourceView: sender.value(forKey: "view") as? UIView)
	}


	@IBAction func confirmPlaceAction(_ sender: Any) {
		// TODO:
	}


	var delayedRefresh: DispatchWorkItem?


	func mapView(_ mapView: MapView, didChange coordinate: CLLocationCoordinate2D, zoom: Float) {
		if let delayedRefresh = delayedRefresh {
			delayedRefresh.cancel()
			self.delayedRefresh = nil
		}
		delayedRefresh = DispatchWorkItem(block: {
			mapView.nearbyAddress(completion: { (place, error) in
				self.selectedPlace = place
			})
		})
		DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: delayedRefresh!)
	}


	func mapView(_ mapView: MapView, didTapOnPlace partialPlaceInfo: Place) {
		selectedPlace = partialPlaceInfo
		if let placeId = partialPlaceInfo.placeId {
			mapView.fetchPlace(byId: placeId) { (place, error) in
				if let place = place {
					self.selectedPlace = place
				}
			}
		}
	}


	func mapView(_ mapView: MapView, didAutocompleteWithPlace place: Place) {
		selectedPlace = place
	}
}

