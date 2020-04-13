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

let songTitleNotification = Notification.Name("songTitleNotifcation")
let songArtworkNotification = Notification.Name("songArtworkNotifcation")
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
    var track = Track()

    func playStation() {
        let playerAsset = AVAsset(url: URL(string: currentStation!.stationStreamURL)!)
        playerItem = AVPlayerItem(asset: playerAsset)
        playerItem!.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions(), context: nil)
        player = AVPlayer(playerItem: playerItem)
        self.setupAudioSession()
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

    override func observeValue(forKeyPath: String?, of: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if forKeyPath != "timedMetadata" { return }
        let data: AVPlayerItem = of as! AVPlayerItem
        if let metadta: String = data.timedMetadata?.first?.value as? String {
            let m = metadta.replacingOccurrences(of: "*", with: "")
            if let artist: String = m.components(separatedBy: "-")[0], let songname: String = m.components(separatedBy: "-")[1] {
                if track.title != songname {
                    track.title = songname
                    track.artist = artist
                    NotificationCenter.default.post(name: songTitleNotification, object: nil)
                    print("\(track.title), \(track.artist)")
                    let parameters = [
                        "term": "\(track.artist) \(track.title)",
                        "entity": "song",
                        "limit": "1"
                    ]
                    Alamofire.request("https://itunes.apple.com/search", method: .get, parameters: parameters).response { response in
                        let json = JSON(response.data)
                        let r = json["results"]
                        if let artworkurl: String = r[0]["artworkUrl100"].stringValue {
                            Alamofire.request(artworkurl).responseImage { artwork in
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

//    override func remoteControlReceived(with receivedEvent: UIEvent?) {
//        super.remoteControlReceived(with: receivedEvent)
//
//        if receivedEvent!.type == UIEvent.EventType.remoteControl {
//
//            switch receivedEvent!.subtype {
//            case .remoteControlPlay:
//                playPressed()
//            case .remoteControlStop:
//                pausePressed()
//            case .remoteControlTogglePlayPause:
//                if track.isPlaying {
//                    pausePressed()
//                }else {
//                    playPressed()
//                }
//            case .remoteControlPause:
//                pausePressed()
//            default:
//                break
//            }
//        }
//    }

}
