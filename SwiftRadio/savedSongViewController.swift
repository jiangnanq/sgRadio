//
//  savedSongViewController.swift
//  新加坡中文电台
//
//  Created by Jiang Nan Qing on 22/2/16.
//  Copyright © 2016 CodeMarket.io. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class savedSongViewController: UIViewController {

    @IBOutlet weak var savedSongTable: UITableView!
    
    var savedSongs: favoriteSongs?
    var allSavedSongs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.savedSongs = favoriteSongs.sharedInstance
        self.allSavedSongs = (self.savedSongs?.favoriteTracks)!
        
        // Do view setup here.
    }
    
}

extension savedSongViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(savedSongTable: UITableView) -> Int {
        return 1
    }
    
    func tableView(savedSongTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.savedSongs?.favoriteTracks.count == 0 {
            return 1
        } else {
            return (self.savedSongs?.favoriteTracks.count)!
        }
    }
    
    func tableView(savedSongTable: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = savedSongTable.dequeueReusableCellWithIdentifier("song", forIndexPath: indexPath)
        cell.textLabel?.backgroundColor = UIColor.clearColor()
        let aSong = self.allSavedSongs[indexPath.row]
        if !(aSong=="") {
            if let label = cell.textLabel {
                label.text = self.allSavedSongs[indexPath.row].componentsSeparatedByString(",")[0]
            }
            if let detailLabel = cell.detailTextLabel {
                detailLabel.text = self.allSavedSongs[indexPath.row].componentsSeparatedByString(",")[1]
            }
        }

        return cell
    }
    
}

extension savedSongViewController:UITableViewDelegate {
    func tableView(savedSongTable: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(savedSongTable: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.allSavedSongs.removeAtIndex(indexPath.row)
            self.savedSongs?.favoriteTracks.removeAtIndex(indexPath.row)
            self.savedSongs?.saveAllSongs()
            var selectIndex = [NSIndexPath]()
            selectIndex.append(indexPath)
            savedSongTable.deleteRowsAtIndexPaths(selectIndex, withRowAnimation: UITableViewRowAnimation.Fade)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.savedSongTable?.reloadData()
            })            
        }
    }
}