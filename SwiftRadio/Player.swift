//
//  Player.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/13/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import MediaPlayer
import AVKit
import Alamofire
import AlamofireImage
import SwiftyJSON

let songTitleNotification = Notification.Name("songTitleNotification")
let songArtworkNotification = Notification.Name("songArtworkNotification")
let autoStopTimerNotification = Notification.Name("autoStopTimerNotification")
//*****************************************************************
// This is a singleton struct using Swift
//*****************************************************************

class radioPlayer: NSObject {
    static let sharedInstance = radioPlayer()
    var player:  AVPlayer?
    var playerItem: AVPlayerItem?
    var currentStation: RadioStation? {
        didSet {
            playStation()
        }
    }
    
    var timer = Timer()
    var track = Track()
    var targetTimer:Int = 0
    var runningTimer:Int = 0
    
//    let reachability = Reachability.forInternetConnection()
    
    override init() {
        super.init()
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(oneMinJob), userInfo: nil, repeats: true)
    }

    @objc func oneMinJob() {
        guard player != nil else {return}
        if self.player!.timeControlStatus == .playing {
            runningTimer += 1
            if targetTimer != 0 {
                if runningTimer >= targetTimer {
                    player!.pause()
                    targetTimer = 0
                }
            }
            NotificationCenter.default.post(name: autoStopTimerNotification, object: nil)
        }
    }
    
    func playStation() {
        let playerAsset = AVAsset(url: URL(string: currentStation!.stationStreamURL)!)
        playerItem = AVPlayerItem(asset: playerAsset)
        playerItem!.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions(), context: nil)
        player = AVPlayer(playerItem: playerItem)
        self.setupAudioSession()
        self.setupRemoteTransportControl()
        player!.play()
    }

    func setupAudioSession() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch {
            print("error when set player! \(error)" )
        }
    }

    func setupRemoteTransportControl() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { event in
            print("receive remote event.")
            self.player?.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { event in
            print("receive pause command.")
            self.player?.pause()
            return .success
        }
    }

    override func observeValue(forKeyPath: String?, of: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if forKeyPath != "timedMetadata" { return }
        let data: AVPlayerItem = of as! AVPlayerItem
        if let metadta: String = data.timedMetadata?.first?.value as? String {
            let m = metadta.replacingOccurrences(of: "*", with: "")
            guard m.contains("-") else {return}
            let artist: String = m.components(separatedBy: "-")[0]
            let songname: String = m.components(separatedBy: "-")[1]
            if track.title != songname {
                track.title = songname
                track.artist = artist
                NotificationCenter.default.post(name: songTitleNotification, object: nil)
                print("\(track.title), \(track.artist)")
                saveRecentSong()
                let parameters = [
                    "term": "\(track.artist) \(track.title)",
                    "entity": "song",
                    "limit": "1"
                ]
                Alamofire.request("https://itunes.apple.com/search", method: .get, parameters: parameters).response { response in
                    let json = JSON(response.data)
                    let r = json["results"]
                    let artworkurl: String = r[0]["artworkUrl100"].stringValue
                    Alamofire.request(artworkurl.replacingOccurrences(of: "100x100", with: "160x160")).responseImage { artwork in
                       if case .success(let image) = artwork.result {
                           self.track.artworkImage = image
                           NotificationCenter.default.post(name: songArtworkNotification, object: nil)
                           self.updateLockScreen()
                       }
                    }
                }
            }
        }
    }

    func updateLockScreen() {
        // Update notification/lock screen
        let albumArtwork = MPMediaItemArtwork(image: track.artworkImage!)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    @objc func dataUsageTotalizer() {
//        if self.reachability!.currentReachabilityStatus().rawValue == ReachableViaWWAN.rawValue {
//            self.playingTimeTotalizer += 1
//            let dataUsageDouble = Double(self.playingTimeTotalizer * 25)
//            var dataUsageString = ""
//            let dataUsageDoubleInM = dataUsageDouble/1000
//            dataUsageString = String(format: "已用%.1fMb流量", dataUsageDoubleInM)
//            self.delegate?.didUpdateDataUsage(dataUsageString)
//        }
    }
    
    func saveCurrentSong() {
        var savedSong:[String] = UserDefaults.standard.array(forKey: "SavedSongs") as? [String] ?? []
        if !savedSong.joined(separator: ",").contains("\(track.title)") {
         if savedSong.count >= 20 {
             savedSong.remove(at: savedSong.count - 1)
         }
         let df = DateFormatter()
         df.dateFormat = "YYYY-MMM-dd HH:mm"
         let ts = df.string(from: Date())
         savedSong.insert("\(ts):\n\(track.artist) - \(track.title)", at: 0)
         UserDefaults.standard.set(savedSong, forKey: "SavedSongs")
        }
    }
    
    func saveRecentSong() {
        var recentSong:[String] = UserDefaults.standard.array(forKey: "RecentSongs") as? [String] ?? []
        if !recentSong.joined(separator: ",").contains("\(track.title)") {
         if recentSong.count >= 20 {
             recentSong.remove(at: recentSong.count - 1)
         }
         let df = DateFormatter()
         df.dateFormat = "YYYY-MMM-dd HH:mm"
         let ts = df.string(from: Date())
         recentSong.insert("\(ts):\n\(track.artist) - \(track.title)", at: 0)
         UserDefaults.standard.set(recentSong, forKey: "RecentSongs")
        }
    }
}

