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

class stationCell: UICollectionViewCell {
    @IBOutlet weak var staionImage: UIImageView!
}

class StationsViewController: UIViewController {

    @IBOutlet weak var stationCollectionView: UICollectionView!
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
        self.title = "新加坡广播电台"
        let btn = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: self, action:#selector(StationsViewController.nowPlayingBarButtonPressed))
        btn.image = UIImage(named: "btn-nowPlaying")
        self.navigationItem.rightBarButtonItem = btn
        
        // Load Data
        loadStationsFromJSON()
        stationCollectionView.dataSource = self
        stationCollectionView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongName), name: songTitleNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongName), name: songArtworkNotification, object: nil)
    }

    @objc func updateSongName() {
        if let s: RadioStation = player.currentStation {
            let title = s.stationName + ": " + player.track.title + " - " + player.track.artist + "..."
            stationNowPlayingButton.setTitle(title, for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        self.title = "狮城电台"
//        // If a station has been selected, create "Now Playing" button to get back to current station
//        if !firstTime {
//            createNowPlayingBarButton()
//        }
    }

    //*****************************************************************
    // MARK: - Setup UI Elements
    //*****************************************************************
//
//    func createNowPlayingBarButton() {
//        if self.navigationItem.rightBarButtonItem == nil {
//            let btn = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: self, action:#selector(StationsViewController.nowPlayingBarButtonPressed))
//            btn.image = UIImage(named: "btn-nowPlaying")
//            self.navigationItem.rightBarButtonItem = btn
//        }
//    }
    
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
                stationCollectionView.reloadData()
            }
        } catch {}
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NowPlaying" {
//            self.title = ""
//            firstTime = false
            let nowPlayingVC = segue.destination as! NowPlayingViewController
            if let indexPath = (sender as? IndexPath) {
                player.currentStation = stations[indexPath.row]
            }
        }
    }
}

//*****************************************************************
// MARK: - TableViewDataSource
//*****************************************************************

extension StationsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stationcell", for: indexPath) as! stationCell
        let image:UIImage = UIImage(named: stations[indexPath.row].stationImageURL)!
        cell.staionImage.image = image
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let title = stations[indexPath.row].stationName + " - Now Playing..."
        stationNowPlayingButton.setTitle(title, for: UIControl.State())
        stationNowPlayingButton.isEnabled = true
        performSegue(withIdentifier: "NowPlaying", sender: indexPath)
    }
}

extension StationsViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.stationCollectionView.bounds.width / 5, height: self.stationCollectionView.bounds.height / 6)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
}

