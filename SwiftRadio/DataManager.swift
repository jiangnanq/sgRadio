//
//  DataManager.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/24/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class DataManager {
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
}
