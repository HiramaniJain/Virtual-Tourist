//
//  FlickrApi.swift
//  VirtualTourist
//
//  Created by Heeral on 5/27/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation

class FlickrApi {
    var session = URLSession.shared
    private var tasks: [String: URLSessionDataTask] = [:]
    
    // MARK: Shared Instance
    
    class func shared() -> FlickrApi {
        struct Singleton {
            static var shared = FlickrApi()
        }
        return Singleton.shared
    }
    
    func downloadImage(imageUrl: String, result: @escaping (_ result: Data?, _ error: NSError?) -> Void) {
        guard let url = URL(string: imageUrl) else {
            return
        }
        let task = taskForGETMethod(nil, url, parameters: [:]) { (data, error) in
            result(data, error)
            self.tasks.removeValue(forKey: imageUrl)
        }
        
        if tasks[imageUrl] == nil {
            tasks[imageUrl] = task
        }
    }
    
    func cancelDownload(_ imageUrl: String) {
        tasks[imageUrl]?.cancel()
        if tasks.removeValue(forKey: imageUrl) != nil {
            print("\(#function) task canceled: \(imageUrl)")
        }
    }
    
    func getPhotosByLocation(latitude: Double, longitude: Double, totalPages: Int?, completion: @escaping (_ result: ParsePhotos?, _ error: Error?) -> Void) {
        
        // choosing a random page.
        var page: Int {
            if let totalPages = totalPages {
                let page = min(totalPages, 4000/FlickrParameterValues.PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        let boundingBox = boundingBoxString(latitude: latitude, longitude: longitude)
        
        let parameters = [
            FlickrParameterKeys.Method           : FlickrParameterValues.SearchMethod
            , FlickrParameterKeys.APIKey         : FlickrParameterValues.APIKey
            , FlickrParameterKeys.Format         : FlickrParameterValues.ResponseFormat
            , FlickrParameterKeys.Extras         : FlickrParameterValues.MediumURL
            , FlickrParameterKeys.NoJSONCallback : FlickrParameterValues.DisableJSONCallback
            , FlickrParameterKeys.SafeSearch     : FlickrParameterValues.UseSafeSearch
            , FlickrParameterKeys.BoundingBox    : boundingBox
            , FlickrParameterKeys.PhotosPerPage  : "\(FlickrParameterValues.PhotosPerPage)"
            , FlickrParameterKeys.Page           : "\(page)"
        ]
        
        _ = taskForGETMethod(parameters: parameters) { (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "Could not retrieve data."]
                completion(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
                return
            }
            
            do {
                let parsePhotos = try JSONDecoder().decode(ParsePhotos.self, from: data)
                completion(parsePhotos, nil)
            } catch {
                print("\(#function) error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func boundingBoxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minLongitude = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minLatitude = max(latitude  - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maxLongitude = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maxLatitude = min(latitude  + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minLongitude),\(minLatitude),\(maxLongitude),\(maxLatitude)"
    }
    
    func buildURLFromParameters(_ parameters: [String: String], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value)
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func taskForGETMethod(
        _ method               : String? = nil,
        _ customUrl            : URL? = nil,
        parameters             : [String: String],
        completionHandlerForGET: @escaping (_ result: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let request: NSMutableURLRequest!
        if let customUrl = customUrl {
            request = NSMutableURLRequest(url: customUrl)
        } else {
            request = NSMutableURLRequest(url: buildURLFromParameters(parameters, withPathExtension: method))
        }
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            if let error = error {
                
                // the request got canceled
                if (error as NSError).code == URLError.cancelled.rawValue {
                    completionHandlerForGET(nil, nil)
                } else {
                    sendError("There was an error with your request: \(error.localizedDescription)")
                }
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than valid range")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForGET(data, nil)
            
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
}
