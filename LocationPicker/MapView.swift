//
//  MapView.swift
//  LocationPicker
//
//  Created on 29/05/2019.
//  Copyright © 2019 Hovik Melikyan. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlacePicker


// Don't forget to initialize the APIs with these keys in AppDelegate
#error("Get your own API keys from Google")
let kMapsAPIKey = ""
let kPlacesAPIKey = ""



class Place {
	let coordinate: CLLocationCoordinate2D
	let placeId: String?
	let poiName: String?
	let formattedAddress: String?
	let locality: String?
	let country: String?


	fileprivate init(from coordinate: CLLocationCoordinate2D, placeId: String, placeName: String) {
		self.coordinate = coordinate
		self.placeId = placeId
		poiName = placeName
		formattedAddress = nil
		locality = nil
		country = nil
	}


	fileprivate init(from place: GMSPlace) {
		coordinate = place.coordinate
		placeId = place.placeID
		poiName = place.name
		formattedAddress = place.formattedAddress
		locality = place.addressComponents?.first(where: { $0.types.contains("locality") })?.name
		country = place.addressComponents?.first(where: { $0.types.contains("country") })?.shortName
	}


	fileprivate init(from address: GMSAddress) {
		coordinate = address.coordinate
		placeId = nil
		poiName = nil
		formattedAddress = address.lines?.joined(separator: ", ")
		locality = address.locality
		country = address.country
	}


	fileprivate init(from coordinate: CLLocationCoordinate2D) {
		self.coordinate = coordinate
		placeId = nil
		poiName = nil
		formattedAddress = nil
		locality = nil
		country = nil
	}
}



protocol MapViewDelegate: class {
	func mapView(_ mapView: MapView, didChange coordinate: CLLocationCoordinate2D, zoom: Float)
	func mapView(_ mapView: MapView, didTapOnPlace partialPlaceInfo: Place)
}



protocol MapViewAutocompleteDelegate: class {
	func mapView(_ mapView: MapView, didAutocompleteWithPlace place: Place)
}



class MapView: GMSMapView, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate {

	private weak var mapViewDelegate: MapViewDelegate?
	private weak var autocompleteDelegate: MapViewAutocompleteDelegate?
	private var isGestureMove: Bool = false


	func initializeForPicker(delegate: MapViewDelegate?, autocompleteDelegate: MapViewAutocompleteDelegate?) {
		super.delegate = self
		self.mapViewDelegate = delegate
		self.autocompleteDelegate = autocompleteDelegate
		isMyLocationEnabled = true
		settings.rotateGestures = false
		settings.myLocationButton = true
		// mapStyle = try! GMSMapStyle(contentsOfFileURL: Bundle.main.url(forResource: "gms-map-style", withExtension: "json")!)
	}


	func set(coordinate: CLLocationCoordinate2D, zoom: Float, animated: Bool) {
		let camera = GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: 0)
		if animated {
			animate(to: camera)
		}
		else {
			self.camera = camera
		}
	}


	var coordinate: CLLocationCoordinate2D {
		return camera.target
	}


	var coordinateBounds: GMSCoordinateBounds {
		return GMSCoordinateBounds(region: projection.visibleRegion())
	}


	func nearbyAddress(completion: @escaping (Place?, Error?) -> Void) {
		GMSGeocoder().reverseGeocodeCoordinate(coordinate) { (response, error) in
			if let result = response?.firstResult() {
				completion(Place(from: result), nil)
			}
			else {
				completion(nil, error)
			}
		}
	}


	func fetchPlace(byId placeId: String, completion: @escaping (Place?, Error?) -> Void) {
		GMSPlacesClient.shared().fetchPlace(fromPlaceID: placeId, placeFields: .all, sessionToken: nil) { (place, error) in
			if let place = place {
				completion(Place(from: place), nil)
			}
			else {
				completion(nil, error)
			}
		}
	}


	func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
		isGestureMove = gesture
	}


	func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
		if isGestureMove {
			mapViewDelegate?.mapView(self, didChange: position.target, zoom: position.zoom)
		}
		isGestureMove = false
	}


	func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
		mapViewDelegate?.mapView(self, didTapOnPlace: Place(from: location, placeId: placeID, placeName: name))
	}


	func launchAutocomplete(from parent: UIViewController, sourceView: UIView?) {
		let autocomplete = GMSAutocompleteViewController()
		autocomplete.autocompleteBounds = coordinateBounds
		autocomplete.delegate = self
		autocomplete.modalPresentationStyle = .popover
		if let sourceView = sourceView, let popover = autocomplete.popoverPresentationController {
			popover.sourceView = sourceView
			popover.sourceRect = sourceView.bounds
		}
		parent.present(autocomplete, animated: true, completion: nil)
	}


	func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
		print("Autocomplete: \(place)")
		autocompleteDelegate?.mapView(self, didAutocompleteWithPlace: Place(from: place))
		viewController.dismiss(animated: true, completion: nil)
	}


	func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
		// dismiss(animated: true, completion: nil)
	}


	func wasCancelled(_ viewController: GMSAutocompleteViewController) {
		viewController.dismiss(animated: true, completion: nil)
	}
}
