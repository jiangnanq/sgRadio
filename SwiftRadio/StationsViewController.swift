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
    var currentTrack: Track?
    var refreshControl: UIRefreshControl!
    var firstTime = true
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register 'Nothing Found' cell xib
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")
        
        preferredStatusBarStyle
        
        // Load Data
        loadStationsFromJSON()
        
        // Setup TableView
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        // Setup Pull to Refresh
        setupPullToRefresh()
        
        // Create NowPlaying Animation
        createNowPlayingAnimation()
        
        // Set AVFoundation category, required for background audio
        var error: NSError?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                with: .defaultToSpeaker)
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            if DEBUG_LOG { print("Failed to set audio session category.  Error: \(error)") }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "狮城电台"
        
        // If a station has been selected, create "Now Playing" button to get back to current station
        if !firstTime {
            createNowPlayingBarButton()
        }
        
        // If a track is playing, display title & artist information and animation
        if currentTrack != nil && currentTrack!.isPlaying {
            let title = currentStation!.stationName + ": " + currentTrack!.title + " - " + currentTrack!.artist + "..."
            stationNowPlayingButton.setTitle(title, for: UIControlState())
            nowPlayingAnimationImageView.startAnimating()
        } else {
            nowPlayingAnimationImageView.stopAnimating()
            nowPlayingAnimationImageView.image = UIImage(named: "NowPlayingBars")
        }
        
    }

    //*****************************************************************
    // MARK: - Setup UI Elements
    //*****************************************************************
    
    func setupPullToRefresh() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.backgroundColor = UIColor.black
        self.refreshControl.tintColor = UIColor.white
        self.refreshControl.addTarget(self, action: #selector(StationsViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    func createNowPlayingAnimation() {
        nowPlayingAnimationImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingAnimationImageView.animationDuration = 0.7
    }
    
    func createNowPlayingBarButton() {
        if self.navigationItem.rightBarButtonItem == nil {
            let btn = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action:#selector(StationsViewController.nowPlayingBarButtonPressed))
            btn.image = UIImage(named: "btn-nowPlaying")
            self.navigationItem.rightBarButtonItem = btn
        }
    }
    
    //*****************************************************************
    // MARK: - Actions
    //*****************************************************************
    
    func nowPlayingBarButtonPressed() {
        performSegue(withIdentifier: "NowPlaying", sender: self)
    }
    
    @IBAction func nowPlayingPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "NowPlaying", sender: self)
    }
    
    func refresh(_ sender: AnyObject) {
        // Pull to Refresh
        stations.removeAll(keepingCapacity: false)
        loadStationsFromJSON()
        
        // Wait 2 seconds then refresh screen
        let popTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC);
        DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
            self.refreshControl.endRefreshing()
            self.view.setNeedsDisplay()
        }
    }
    
    //*****************************************************************
    // MARK: - Load Station Data
    //*****************************************************************
    
    func loadStationsFromJSON() {
        
        // Turn on network indicator in status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Get the Radio Stations
        DataManager.getStationDataWithSuccess() { (data) in
            
            if DEBUG_LOG { print("Stations JSON Found") }
            
            let json = JSON(data: data!)
            
            if let stationArray = json["station"].array {
                
                for stationJSON in stationArray {
                    let station = RadioStation.parseStation(stationJSON)
                    self.stations.append(station)
                }
                
                // stations array populated, update table on main queue
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.view.setNeedsDisplay()
                }
                
            } else {
                if DEBUG_LOG { print("JSON Station Loading Error") }
            }
            
            // Turn off network indicator in status bar
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NowPlaying" {
            
            self.title = ""
            firstTime = false
            
            let nowPlayingVC = segue.destination as! NowPlayingViewController
            nowPlayingVC.delegate = self
            
            if let indexPath = (sender as? IndexPath) {
                // User clicked on row, load/reset station
                currentStation = stations[indexPath.row]
                nowPlayingVC.currentStation = currentStation
                nowPlayingVC.newStation = true
            
            } else {
                // User clicked on a now playing button
                if let currentTrack = currentTrack {
                    // Return to NowPlaying controller without reloading station
                    nowPlayingVC.track = currentTrack
                    nowPlayingVC.currentStation = currentStation
                    nowPlayingVC.newStation = false
                } else {
                    // Issue with track, reload station
                    nowPlayingVC.currentStation = currentStation
                    nowPlayingVC.newStation = true
                }
            }
        }
    }
}

//*****************************************************************
// MARK: - TableViewDataSource
//*****************************************************************

extension StationsViewController: UITableViewDataSource {
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
            cell.selectionStyle = UITableViewCellSelectionStyle.none
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
            stationNowPlayingButton.setTitle(title, for: UIControlState())
            stationNowPlayingButton.isEnabled = true
            
            performSegue(withIdentifier: "NowPlaying", sender: indexPath)
        }
    }
}

//*****************************************************************
// MARK: - NowPlayingViewControllerDelegate
//*****************************************************************

extension StationsViewController: NowPlayingViewControllerDelegate {
    
    func artworkDidUpdate(_ track: Track) {
        currentTrack?.artworkURL = track.artworkURL
        currentTrack?.artworkImage = track.artworkImage
    }
    
    func songMetaDataDidUpdate(_ track: Track) {
        currentTrack = track
        let title = currentStation!.stationName + ": " + currentTrack!.title + " - " + currentTrack!.artist + "..."
        stationNowPlayingButton.setTitle(title, for: UIControlState())
    }
    
    func trackPlayingToggled(_ track: Track) {
        currentTrack?.isPlaying = track.isPlaying
    }

}
