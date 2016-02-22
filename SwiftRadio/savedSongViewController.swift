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
            cell.textLabel?.text = self.allSavedSongs[indexPath.row].componentsSeparatedByString(",")[0]
            cell.detailTextLabel?.text = self.allSavedSongs[indexPath.row].componentsSeparatedByString(",")[1]
        }

        return cell
    }
    
}