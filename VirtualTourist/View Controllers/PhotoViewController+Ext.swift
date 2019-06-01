//
//  PhotoViewController+Ext.swift
//  VirtualTourist
//
//  Created by Heeral on 5/27/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension PhotoViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
     // Populate view
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoView.identifier, for: indexPath) as! PhotoView
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        cell.tickButton.isHidden = true
        
        return cell
     }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if !(selectedIndexes.contains(indexPath)) {
            selectedIndexes.add(indexPath)
        }
        
        updateCollectionButtonTitle()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        //remove the selected cell contents from _selectedCells arr when cell is De-Selected
        
        selectedIndexes.remove(indexPath)
        collectionView.reloadItems(at: [indexPath])
        
        updateCollectionButtonTitle()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        let photoViewCell = cell as! PhotoView
        photoViewCell.imageUrl = photo.imageUrl!
        configImage(using: photoViewCell, photo: photo, collectionView: collectionView, index: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying: UICollectionViewCell, forItemAt: IndexPath) {
        
        if collectionView.cellForItem(at: forItemAt) == nil {
            return
        }
        
        let photo = fetchedResultsController.object(at: forItemAt)
        if let imageUrl = photo.imageUrl {
            FlickrApi.shared().cancelDownload(imageUrl)
        }
    }
}

extension PhotoViewController {
    private func configImage(using cell: PhotoView, photo: Photo, collectionView: UICollectionView, index: IndexPath) {
        if let imageData = photo.image {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = UIImage(data: Data(referencing: imageData as NSData))
        } else {
            if let imageUrl = photo.imageUrl {
                cell.activityIndicator.startAnimating()
                FlickrApi.shared().downloadImage(imageUrl: imageUrl) { (data, error) in
                    if let error = error {
                        self.performUIUpdatesOnMain {
                            cell.activityIndicator.stopAnimating()
                            print(error)
                        }
                        return
                    } else if let data = data {
                        self.performUIUpdatesOnMain {
                            
                            if let currentCell = collectionView.cellForItem(at: index) as? PhotoView {
                                if currentCell.imageUrl == imageUrl {
                                    currentCell.imageView.image = UIImage(data: data)
                                    cell.activityIndicator.stopAnimating()
                                }
                            }
                            photo.image = NSData(data: data) as Data
                            DispatchQueue.global(qos: .background).async {
                                self.save()
                            }
                        }
                    }
                }
            }
        }
    }
}
