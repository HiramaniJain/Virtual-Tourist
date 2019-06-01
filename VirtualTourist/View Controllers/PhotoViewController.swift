//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Heeral on 5/25/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, MKMapViewDelegate
{
    var marker: Marker?
    var totalPages: Int? = nil
    var selectedIndexes: NSMutableArray = []
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
        updateFlowLayout(view.frame.size)
        locationMapView.delegate = self
        locationMapView.isZoomEnabled = false
        locationMapView.isScrollEnabled = false
        
        guard let marker = marker else {
            return
        }
        showOnTheMap(marker)
        
        fetchPhotos(marker: marker)
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateFlowLayout(size)
    }
    func updateImages() {
        for photos in fetchedResultsController.fetchedObjects! {
            DataController.shared().viewContext.delete(photos)
        }
        save()
        getPhotosFromFlickr(marker: marker!)
    }
    
    @IBAction func updateDeletePhotos(_ sender: Any) {
        updateCollectionButtonTitle()
        if selectedIndexes.count > 0 {
            deleteSelectedPhotos()
        } else {
            updateImages()
        }
    }
    
    private func fetchSavedPhotos(marker: Marker) {
        let fetchRequest = NSFetchRequest<Photo>(entityName: Photo.name)
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "marker == %@", argumentArray: [marker])
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared().viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("\(#function) Error performing initial fetch: \(error)")
        }
    }
    
    func fetchPhotos(marker: Marker) {
        //Getting saved photos
        fetchSavedPhotos(marker: marker)
        
        //Getting photos from Flickr API if there are no saved photos
        if let photos = marker.photos, photos.count == 0 {
            getPhotosFromFlickr(marker: marker)
        }
         getPhotosFromFlickr(marker: marker)
    }
    
    func getPhotosFromFlickr(marker: Marker) {
        let latitude = Double(marker.latitude!)!
        let longitude = Double(marker.longitude!)!
        
        FlickrApi.shared().getPhotosByLocation(latitude: latitude, longitude: longitude, totalPages: totalPages) { (parsedPhotos, error) in
            if let error = error {
                print(error)
            }
            
            if let parsedPhotos = parsedPhotos {
                self.totalPages = parsedPhotos.photos.pages
                let totalPhotos = parsedPhotos.photos.photo.count
                print("\(#function) Downloading \(totalPhotos) photos.")
                self.storePhotos(parsedPhotos.photos.photo, forMarker: marker)
                if totalPhotos == 0 {
                    print("No photos found for this location")
                }
            }
        }
    }
    
    func storePhotos(_ photos: [ParsePhoto], forMarker: Marker) {
        
        for photo in photos {
            performUIUpdatesOnMain {
                if let url = photo.url {
                    _ = Photo(title: photo.title, imageUrl: url, forMarker: forMarker, context: DataController.shared().viewContext)
                }
                self.save()
            }
        }
    }
    
    func save() {
        try? DataController.shared().viewContext.save()
    }
    
    func showOnTheMap(_ marker: Marker) {
        
        let latitude = Double(marker.latitude!)!
        let longitude = Double(marker.longitude!)!
        let locationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        
        locationMapView.removeAnnotations(locationMapView.annotations)
        locationMapView.addAnnotation(annotation)
        locationMapView.setCenter(locationCoordinate, animated: true)
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func deleteSelectedPhotos() {
        for index in selectedIndexes {
            let deletePhoto = fetchedResultsController.object(at: index as! IndexPath)
            DataController.shared().viewContext.delete(deletePhoto)
        }
        
        collectionView.reloadItems(at: selectedIndexes as! [IndexPath])
        selectedIndexes.removeAllObjects()
        save()
        updateCollectionButtonTitle()
    }
    
    func updateCollectionButtonTitle() {
        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle("Remove Selected Images", for: .normal)
        } else {
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
    
    func updateFlowLayout(_ withSize: CGSize) {
        
        let landscape = withSize.width > withSize.height
        
        let space: CGFloat = landscape ? 5 : 3
        let items: CGFloat = landscape ? 2 : 3
        
        let dimension = (withSize.width - ((items + 1) * space)) / items
        
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout?.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
}

extension PhotoViewController {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}
