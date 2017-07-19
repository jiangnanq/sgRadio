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
    func numberOfSections(in savedSongTable: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ savedSongTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.savedSongs?.favoriteTracks.count == 0 {
            return 1
        } else {
            return (self.savedSongs?.favoriteTracks.count)!
        }
    }
    
    func tableView(_ savedSongTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = savedSongTable.dequeueReusableCell(withIdentifier: "song", for: indexPath)
        cell.textLabel?.backgroundColor = UIColor.clear
        let aSong = self.allSavedSongs[indexPath.row]
        if !(aSong=="") {
            if let label = cell.textLabel {
                label.text = self.allSavedSongs[indexPath.row].components(separatedBy: ",")[0]
            }
            if let detailLabel = cell.detailTextLabel {
                detailLabel.text = self.allSavedSongs[indexPath.row].components(separatedBy: ",")[1]
            }
        }

        return cell
    }
    
}

extension savedSongViewController:UITableViewDelegate {
    func tableView(_ savedSongTable: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ savedSongTable: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.allSavedSongs.remove(at: indexPath.row)
            self.savedSongs?.favoriteTracks.remove(at: indexPath.row)
            self.savedSongs?.saveAllSongs()
            var selectIndex = [IndexPath]()
            selectIndex.append(indexPath)
            savedSongTable.deleteRows(at: selectIndex, with: UITableViewRowAnimation.fade)
            DispatchQueue.main.async(execute: { () -> Void in
                self.savedSongTable?.reloadData()
            })            
        }
    }
}
