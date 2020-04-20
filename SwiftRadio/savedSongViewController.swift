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
    @IBOutlet weak var selectSegment: UISegmentedControl!
    var savedSong:[String] = UserDefaults.standard.array(forKey: "SavedSongs") as? [String] ?? []
    var recentSong:[String] = UserDefaults.standard.array(forKey: "RecentSongs") as? [String] ?? []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "收藏"
        savedSongTable.dataSource = self
        savedSongTable.delegate = self
        // Do view setup here.
    }
    
    @IBAction func selectpage() {
        savedSongTable.reloadData()
    }
}

extension savedSongViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in savedSongTable: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ savedSongTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectSegment.selectedSegmentIndex == 0 ? savedSong.count:recentSong.count
    }
    
    func tableView(_ savedSongTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = savedSongTable.dequeueReusableCell(withIdentifier: "song", for: indexPath)
        cell.textLabel?.backgroundColor = UIColor.clear
        cell.textLabel?.text = selectSegment.selectedSegmentIndex == 0 ? savedSong[indexPath.row]:recentSong[indexPath.row]
        return cell
    }
    
}
