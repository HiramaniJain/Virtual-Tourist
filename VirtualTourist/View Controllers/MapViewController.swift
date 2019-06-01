//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Heeral on 5/25/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate
{
    
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var deletePinsView: UIView!
    
    
    var markerAnnotation: MKPointAnnotation? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        initializer()
        
        if let markers = fetchAllMarkers() {
            showMarkers(markers)
        }
    }
    // Mark:-  do navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoViewController {
            guard let marker = sender as? Marker else {
                return
            }
            let photoViewController = segue.destination as! PhotoViewController
            photoViewController.marker = marker
            //photoViewController.dataController = dataController
        }
    }
    
    func initializer() {
        navigationItem.rightBarButtonItem = editButtonItem
        deletePinsView.isHidden = true
    }
    
    @IBAction func longPressedOnMap(_ sender: UILongPressGestureRecognizer) {
        
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            
            markerAnnotation = MKPointAnnotation()
            markerAnnotation!.coordinate = locCoord
            
            print("\(#function) Coordinate: \(locCoord.latitude),\(locCoord.longitude)")
            
            mapView.addAnnotation(markerAnnotation!)
            
        } else if sender.state == .changed {
            markerAnnotation!.coordinate = locCoord
        } else if sender.state == .ended {
            
            let _ = Marker(
                latitude: String(markerAnnotation!.coordinate.latitude),
                longitude: String(markerAnnotation!.coordinate.longitude),
                context: DataController.shared().viewContext)
            save()
            
        }
    }
    
    func save() {
         try! DataController.shared().viewContext.save()
    }
    
    func deleteMarker(marker: Marker) {
        try! DataController.shared().viewContext.delete(marker)
        save()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deletePinsView.isHidden = !editing
    }
    
    func showInfo(withTitle: String = "Info", withMessage: String, action: (() -> Void)? = nil) {
        performUIUpdatesOnMain {
            let ac = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(ac, animated: true)
        }
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func fetchAllMarkers() -> [Marker]? {
        var markers: [Marker]?
        let fetchRequest:NSFetchRequest<Marker> = Marker.fetchRequest()
        if let result = try? DataController.shared().viewContext.fetch(fetchRequest) {
            markers = result
        }
        
        return markers
    }
    
    func fetchMarker(latitude: String, longitude: String) -> Marker? {
        let fetchRequest:NSFetchRequest<Marker> = Marker.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
        
        guard let marker = (try! DataController.shared().viewContext.fetch(fetchRequest)).first else {
            return nil
        }
        return marker
    }

    
    func showMarkers(_ markers: [Marker]) {
        for marker in markers where marker.latitude != nil && marker.longitude != nil {
            let annotation = MKPointAnnotation()
            let lat = Double(marker.latitude!)!
            let lon = Double(marker.longitude!)!
            annotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
        //reload map
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            //self.showInfo(withMessage: "No link defined.")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(annotation, animated: true)
        print("\(#function) lat \(annotation.coordinate.latitude) lon \(annotation.coordinate.longitude)")
        let lat = String(annotation.coordinate.latitude)
        let lon = String(annotation.coordinate.longitude)
        if let marker = fetchMarker(latitude: lat, longitude: lon) {
            if isEditing {
                mapView.removeAnnotation(annotation)
                deleteMarker(marker: marker)
                return
            }
            performSegue(withIdentifier: "showPhotos", sender: marker)
        }
    }
}
