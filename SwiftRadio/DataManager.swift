//
//  DataManager.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/24/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class DataManager {
    
    //*****************************************************************
    // Helper class to get either local or remote JSON
    //*****************************************************************
    
    class func getStationDataWithSuccess(_ success: @escaping ((_ metaData: Data?) -> Void)) {

        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            if useLocalStations {
                getDataFromFileWithSuccess() { data in
                    success(data)
                }
            } else {
                loadDataFromURL(URL(string: stationDataURL)!) { data, error in
                    if let urlData = data {
                        success(urlData)
                    }
                }
            }
        }
    }
    
    //*****************************************************************
    // Load local JSON Data
    //*****************************************************************
    
    class func getDataFromFileWithSuccess(_ success: @escaping (_ data: Data) -> Void) {
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            
            let filePath = Bundle.main.path(forResource: "stations", ofType:"json")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath!),
                    options: NSData.ReadingOptions.uncached)
                success(data)
            } catch {
                fatalError()
            }
        }
    }
    
    
    class func getSongsFromFileWithSuccess(_ success: @escaping (_ songs: [String]) -> Void){
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async{
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let documentsDirectoryPath = URL(string: documents)!
            let readPath = documentsDirectoryPath.appendingPathComponent("songs.txt")
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: readPath.absoluteString) {
                fileManager.createFile(atPath: readPath.absoluteString, contents: nil, attributes: nil)
            }
            do {
                let content = try String(contentsOfFile: readPath.absoluteString, encoding: String.Encoding.utf8)
                success (content.components(separatedBy: "\n"))
            } catch _ as NSError {
                print ("read songs file failed")
            }
        }
        
    }
    
    class func saveFavoriteSongToFile (_ allSongs: [String]){
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsDirectoryPath = URL(string: documents)!
        let writePath = documentsDirectoryPath.appendingPathComponent("songs.txt")
        let joined = allSongs.joined(separator: "\n")
        do {
            try joined.write(toFile: writePath.absoluteString, atomically: true, encoding: String.Encoding.utf8)
        } catch _ as NSError {
            print ("fail when write to the song file")
        }
    }
    //*****************************************************************
    // Get LastFM/iTunes Data
    //*****************************************************************
    
    class func getTrackDataWithSuccess(_ queryURL: String, success: @escaping ((_ metaData: Data?) -> Void)) {

        loadDataFromURL(URL(string: queryURL)!) { data, _ in
            // Return Data
            if let urlData = data {
                success(urlData)
            } else {
                if DEBUG_LOG { print("API TIMEOUT OR ERROR") }
            }
        }
    }
    
    //*****************************************************************
    // REUSABLE DATA/API CALL METHOD
    //*****************************************************************
    
    class func loadDataFromURL(_ url: URL, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.allowsCellularAccess          = true
        sessionConfig.timeoutIntervalForRequest     = 15
        sessionConfig.timeoutIntervalForResource    = 30
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        let session = URLSession(configuration: sessionConfig)
        
        // Use NSURLSession to get data from an NSURL
        let loadDataTask = session.dataTask(with: url, completionHandler: { data, response, error in
            if let responseError = error {
                completion(nil, responseError as NSError)
                
                if DEBUG_LOG { print("API ERROR: \(error)") }
                
                // Stop activity Indicator
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(domain:"io.codemarket", code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code has unexpected value."])
                    
                    if DEBUG_LOG { print("API: HTTP status code has unexpected value") }
                    
                    completion(nil, statusError)
                    
                } else {
                    
                    // Success, return data
                    completion(data, nil)
                }
            }
        })
        
        loadDataTask.resume()
    }
}
