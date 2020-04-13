//
//  StationsViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/19/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
import SwiftyJSON

class StationsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stationNowPlayingButton: UIButton!
    @IBOutlet weak var nowPlayingAnimationImageView: UIImageView!
    
    var stations = [RadioStation]()
    var currentStation: RadioStation?
    var player = radioPlayer.sharedInstance
    var firstTime = true
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register 'Nothing Found' cell xib
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")

        // Load Data
        loadStationsFromJSON()
        
        // Setup TableView
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        NotificationCenter.default.addObserver(self, selector: #selector(updateSongName), name: songTitleNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongName), name: songArtworkNotification, object: nil)
        // Set AVFoundation category, required for background audio
        var error: NSError?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            if DEBUG_LOG { print("Failed to set audio session category.  Error: \(error)") }
        }
    }

    @objc func updateSongName() {
        if let s: RadioStation = player.currentStation {
            let title = s.stationName + ": " + player.track.title + " - " + player.track.artist + "..."
            stationNowPlayingButton.setTitle(title, for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "狮城电台"
        // If a station has been selected, create "Now Playing" button to get back to current station
        if !firstTime {
            createNowPlayingBarButton()
        }
        
        // If a track is playing, display title & artist information and animation
//        if currentTrack != nil && currentTrack!.isPlaying {
//            let title = currentStation!.stationName + ": " + currentTrack!.title + " - " + currentTrack!.artist + "..."
//            stationNowPlayingButton.setTitle(title, for: UIControl.State())
//            nowPlayingAnimationImageView.startAnimating()
//        } else {
//            nowPlayingAnimationImageView.stopAnimating()
//            nowPlayingAnimationImageView.image = UIImage(named: "NowPlayingBars")
//        }
        
    }

    //*****************************************************************
    // MARK: - Setup UI Elements
    //*****************************************************************
    
    
    func createNowPlayingBarButton() {
        if self.navigationItem.rightBarButtonItem == nil {
            let btn = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: self, action:#selector(StationsViewController.nowPlayingBarButtonPressed))
            btn.image = UIImage(named: "btn-nowPlaying")
            self.navigationItem.rightBarButtonItem = btn
        }
    }
    
    //*****************************************************************
    // MARK: - Actions
    //*****************************************************************
    
    @objc func nowPlayingBarButtonPressed() {
        performSegue(withIdentifier: "NowPlaying", sender: self)
    }
    
    @IBAction func nowPlayingPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "NowPlaying", sender: self)
    }
    
    
    //*****************************************************************
    // MARK: - Load Station Data
    //*****************************************************************
    
    func loadStationsFromJSON() {
        // Get the Radio Stations
        let filePath = Bundle.main.path(forResource: "stations", ofType:"json")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath!),
                    options: NSData.ReadingOptions.uncached)
            let json = try JSON(data: data)
            if let stationArray = json["station"].array {
                for stationJSON in stationArray {
                    let station = RadioStation.parseStation(stationJSON)
                    self.stations.append(station)
                }
                tableView.reloadData()
            }
        } catch {}
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NowPlaying" {
            self.title = ""
            firstTime = false
            let nowPlayingVC = segue.destination as! NowPlayingViewController
            if let indexPath = (sender as? IndexPath) {
                player.currentStation = stations[indexPath.row]
            }
//            else {
                // User clicked on a now playing button
//                if let currentTrack = currentTrack {
                    // Return to NowPlaying controller without reloading station
//                    nowPlayingVC.track = currentTrack
//                    nowPlayingVC.currentStation = currentStation
//                    nowPlayingVC.newStation = false
//                } else {
                    // Issue with track, reload station
//                    nowPlayingVC.currentStation = currentStation
//                    nowPlayingVC.newStation = true
//                }
//            }
        }
    }
}

//*****************************************************************
// MARK: - TableViewDataSource
//*****************************************************************

extension StationsViewController: UITableViewDataSource {
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if stations.count == 0 {
            return 1
        } else {
            return stations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if stations.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFound", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationTableViewCell
            // alternate background color
            if indexPath.row % 2 == 0 {
                cell.backgroundColor = UIColor.clear
            } else {
                cell.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            }
            // Configure the cell...
            let station = stations[indexPath.row]
            cell.configureStationCell(station)
            return cell
        }
    }
}

//*****************************************************************
// MARK: - TableViewDelegate
//*****************************************************************

extension StationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if !stations.isEmpty {
            // Set Now Playing Buttons
            let title = stations[indexPath.row].stationName + " - Now Playing..."
            stationNowPlayingButton.setTitle(title, for: UIControl.State())
            stationNowPlayingButton.isEnabled = true
            performSegue(withIdentifier: "NowPlaying", sender: indexPath)
        }
    }
}

