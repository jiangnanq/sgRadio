//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import SwiftyJSON
import AVKit

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var slider = UISlider()
    @IBOutlet weak var autoStopButton: UIButton!
    @IBOutlet weak var dataUsageLabel: UILabel!
    @IBOutlet weak var saveSongButton: UIButton!
    
    var mpVolumeSlider = UISlider()
    var player = radioPlayer.sharedInstance

    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set View Title
        self.title = player.currentStation!.stationName
        updateSongName()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongName), name: songTitleNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongName), name: songArtworkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAutoStopInfo), name: autoStopTimerNotification, object: nil)
        setupVolumeSlider()
    }

    @objc func updateSongName() {
        self.songLabel.text = player.track.title
        self.artistLabel.text = player.track.artist
        self.albumImageView.image = player.track.artworkImage

    }
    
    @objc func updateAutoStopInfo() {
        if player.targetTimer != 0 {
            autoStopButton.setTitle("\(player.targetTimer - player.runningTimer)分钟后停止", for: .normal)
        } else {
            autoStopButton.setTitle("自动停止", for: .normal)
        }
        if let p: AVPlayer = player.player {
            if p.timeControlStatus == .playing {
                pauseButton.isEnabled = true
                playButton.isEnabled = false
            } else {
                pauseButton.isEnabled = false
                playButton.isEnabled = true
            }
        }
    }
    
    deinit {
        // Be a good citizen
        NotificationCenter.default.removeObserver(self, name: songTitleNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: songArtworkNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: autoStopTimerNotification, object: nil)
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************

    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        volumeParentView.backgroundColor = UIColor.clear
        let volumeView = MPVolumeView(frame: volumeParentView.bounds)
        for view in volumeView.subviews {
            let uiview: UIView = view as UIView
             if (uiview.description as NSString).range(of: "MPVolumeSlider").location != NSNotFound {
                mpVolumeSlider = (uiview as! UISlider)
            }
        }
        
        let thumbImageNormal = UIImage(named: "slider-ball")
        slider?.setThumbImage(thumbImageNormal, for: UIControl.State())
        
    }

    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************

    @IBAction func playPressed() {
        player.player?.play()
        playButton.isEnabled = false
        pauseButton.isEnabled = true
    }
    
    @IBAction func pausePressed() {
        player.player?.pause()
        pauseButton.isEnabled = false
        playButton.isEnabled = true

    }
    
    @IBAction func volumeChanged(_ sender:UISlider) {
        mpVolumeSlider.value = sender.value
    }
    
    func saveThisSong() {
//        EZLoadingActivity.show("正在收藏", disableUI: false)
//        self.savedSongs?.addOneSong(self.track)
//        let delay = 0.5 * Double(NSEC_PER_SEC)
//        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
//        DispatchQueue.main.asyncAfter(deadline: time) { () -> Void in
//            EZLoadingActivity.hide(success: true, animated: false)
//        }
    }
    
    @IBAction func saveSongToFavorite(_ sender:UIButton){
//        let optionMenu = UIAlertController(title: nil, message: "收藏歌曲", preferredStyle: .actionSheet)
//        let option1 = UIAlertAction(title: "收藏这首歌曲", style: .default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            self.saveThisSong()
//        })
//        let option2 = UIAlertAction(title: "查看收藏夹", style: .default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            self.showSavedSongsList()
//        })
//        let option3 = UIAlertAction(title: "取消", style: .default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            print("Cancel")
//        })
//
//        optionMenu.addAction(option1)
//        optionMenu.addAction(option2)
//        optionMenu.addAction(option3)
//
//        self.present(optionMenu, animated: true, completion: nil)

    }
    func showSavedSongsList() {
        performSegue(withIdentifier: "savedSongs", sender: self)
    }
    
    @IBAction func autoStopPressed() {
        let optionMenu = UIAlertController(title: nil, message: "自动停止", preferredStyle:.actionSheet)
        let option1 = UIAlertAction(title: "15分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.player.targetTimer = self.player.runningTimer + 15
            self.autoStopButton.setTitle("15分钟后停止", for: .normal)
        })
        let option2 = UIAlertAction(title: "30分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.player.targetTimer = self.player.runningTimer + 30
            self.autoStopButton.setTitle("30分钟后停止", for: .normal)
        })
        let option3 = UIAlertAction(title: "60分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.player.targetTimer = self.player.runningTimer + 60
            self.autoStopButton.setTitle("60分钟后停止", for: .normal)
        })
        let option4 = UIAlertAction(title: "停止计时", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.player.targetTimer = 0
            self.autoStopButton.setTitle("自动停止", for: .normal)
        })
        let option5 = UIAlertAction(title: "取消", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancel")
        })

        optionMenu.addAction(option1)
        optionMenu.addAction(option2)
        optionMenu.addAction(option3)
        optionMenu.addAction(option4)
        optionMenu.addAction(option5)

        self.present(optionMenu, animated: true, completion: nil)
        
    }

    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "InfoDetail" {
            let infoController = segue.destination as! InfoDetailViewController
//            infoController.currentStation = currentStation
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "InfoDetail", sender: self)
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            self.saveThisSong()
        }
    }
}

extension NowPlayingViewController:countDelegate {
    func didUpdateEverySeconds(_ statusString: String) {
        if (statusString == "自动停止") {
            self.autoStopButton.setTitle("自动停止", for: UIControl.State())
            pausePressed()
            return
        }
        UIView.performWithoutAnimation({ () -> Void in
            self.autoStopButton.setTitle(statusString, for: UIControl.State())
            self.autoStopButton.layoutIfNeeded()
        })
    }
    
    func didUpdateDataUsage(_ dataUsageString : String) {
        self.dataUsageLabel.text = dataUsageString
    }
}
