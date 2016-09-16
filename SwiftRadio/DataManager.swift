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
    
    class func getStationDataWithSuccess(success: ((metaData: NSData!) -> Void)) {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if useLocalStations {
                getDataFromFileWithSuccess() { data in
                    success(metaData: data)
                }
            } else {
                loadDataFromURL(NSURL(string: stationDataURL)!) { data, error in
                    if let urlData = data {
                        success(metaData: urlData)
                    }
                }
            }
        }
    }
    
    //*****************************************************************
    // Load local JSON Data
    //*****************************************************************
    
    class func getDataFromFileWithSuccess(success: (data: NSData) -> Void) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let filePath = NSBundle.mainBundle().pathForResource("stations", ofType:"json")
            do {
                let data = try NSData(contentsOfFile:filePath!,
                    options: NSDataReadingOptions.DataReadingUncached)
                success(data: data)
            } catch {
                fatalError()
            }
        }
    }
    
    
    class func getSongsFromFileWithSuccess(success: (songs: [String]) -> Void){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
            let documentsDirectoryPath = NSURL(string: documents)!
            let readPath = documentsDirectoryPath.URLByAppendingPathComponent("songs.txt")
            let fileManager = NSFileManager.defaultManager()
            if !fileManager.fileExistsAtPath(readPath!.absoluteString!) {
                fileManager.createFileAtPath(readPath!.absoluteString!, contents: nil, attributes: nil)
            }
            do {
                let content = try String(contentsOfFile: readPath!.absoluteString!, encoding: NSUTF8StringEncoding)
                success (songs: content.componentsSeparatedByString("\n"))
            } catch _ as NSError {
                print ("read songs file failed")
            }
        }
        
    }
    
    class func saveFavoriteSongToFile (allSongs: [String]){
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let documentsDirectoryPath = NSURL(string: documents)!
        let writePath = documentsDirectoryPath.URLByAppendingPathComponent("songs.txt")
        let joined = allSongs.joinWithSeparator("\n")
        do {
            try joined.writeToFile(writePath!.absoluteString!, atomically: true, encoding: NSUTF8StringEncoding)
        } catch _ as NSError {
            print ("fail when write to the song file")
        }
    }
    //*****************************************************************
    // Get LastFM/iTunes Data
    //*****************************************************************
    
    class func getTrackDataWithSuccess(queryURL: String, success: ((metaData: NSData!) -> Void)) {

        loadDataFromURL(NSURL(string: queryURL)!) { data, _ in
            // Return Data
            if let urlData = data {
                success(metaData: urlData)
            } else {
                if DEBUG_LOG { print("API TIMEOUT OR ERROR") }
            }
        }
    }
    
    //*****************************************************************
    // REUSABLE DATA/API CALL METHOD
    //*****************************************************************
    
    class func loadDataFromURL(url: NSURL, completion:(data: NSData?, error: NSError?) -> Void) {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.allowsCellularAccess          = true
        sessionConfig.timeoutIntervalForRequest     = 15
        sessionConfig.timeoutIntervalForResource    = 30
        sessionConfig.HTTPMaximumConnectionsPerHost = 1
        
        let session = NSURLSession(configuration: sessionConfig)
        
        // Use NSURLSession to get data from an NSURL
        let loadDataTask = session.dataTaskWithURL(url){ data, response, error in
            if let responseError = error {
                completion(data: nil, error: responseError)
                
                if DEBUG_LOG { print("API ERROR: \(error)") }
                
                // Stop activity Indicator
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(domain:"io.codemarket", code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code has unexpected value."])
                    
                    if DEBUG_LOG { print("API: HTTP status code has unexpected value") }
                    
                    completion(data: nil, error: statusError)
                    
                } else {
                    
                    // Success, return data
                    completion(data: data, error: nil)
                }
            }
        }
        
        loadDataTask.resume()
    }
}
