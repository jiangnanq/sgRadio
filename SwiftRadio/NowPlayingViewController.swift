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
import Spring

//*****************************************************************
// Protocol
// Updates the StationsViewController when the track changes
//*****************************************************************

protocol NowPlayingViewControllerDelegate: class {
    func songMetaDataDidUpdate(_ track: Track)
    func artworkDidUpdate(_ track: Track)
    func trackPlayingToggled(_ track: Track)
}

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var slider = UISlider()
    @IBOutlet weak var autoStopButton: UIButton!
    @IBOutlet weak var dataUsageLabel: UILabel!
    @IBOutlet weak var saveSongButton: UIButton!
    
    var currentStation: RadioStation!
    var downloadTask: URLSessionDownloadTask?
    var iPhone4 = false
    var justBecameActive = false
    var newStation = true
    var nowPlayingImageView: UIImageView!
    let radioPlayer = Player.radio
    var track: Track!
    var mpVolumeSlider = UISlider()
    var sleepTimer = Timer()
    var sleepCounter: Count?
    var savedSongs: favoriteSongs?
    
    weak var delegate: NowPlayingViewControllerDelegate?
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        self.title = currentStation.stationName
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Setup MPMoviePlayerController
        // If you're building an app for a client, you may want to
        // replace the MediaPlayer player with a more robust 
        // streaming library/SDK. Preferably one that supports interruptions, etc.
        // Most of the good streaming libaries are in Obj-C, however they
        // will work nicely with this Swift code.
        setupPlayer()
        
        // Notification for when app becomes active
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.didBecomeActiveNotificationReceived),
            name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        
        // Notification for MediaPlayer metadata updated
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.metadataUpdated(_:)),
            name:NSNotification.Name.MPMoviePlayerTimedMetadataUpdated,
            object: nil);
        self.sleepCounter = Count.sharedInstance
        self.savedSongs = favoriteSongs.sharedInstance
        // Check for station change
        if newStation {
            track = Track()
            stationDidChange()
            self.sleepCounter?.stopPlayer()
            self.sleepCounter?.startPlayer()
        } else {
            updateLabels()
            albumImageView.image = track.artworkImage
            
            if !track.isPlaying {
                pausePressed()
            } else {
                nowPlayingImageView.startAnimating()
            }
        }
        
        // Setup slider
        setupVolumeSlider()
        
        self.sleepCounter!.delegate = self
    }
    
    func didBecomeActiveNotificationReceived() {
        // View became active
        updateLabels()
        justBecameActive = true
        updateAlbumArtwork()
    }
    
    deinit {
        // Be a good citizen
        NotificationCenter.default.removeObserver(self,
            name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(self,
            name: NSNotification.Name.MPMoviePlayerTimedMetadataUpdated,
            object: nil)
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    func setupPlayer() {
        radioPlayer.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        radioPlayer.view.sizeToFit()
        radioPlayer.movieSourceType = MPMovieSourceType.streaming
        radioPlayer.isFullscreen = false
        radioPlayer.shouldAutoplay = true
        radioPlayer.prepareToPlay()
        radioPlayer.controlStyle = MPMovieControlStyle.none
    }
  
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
        slider?.setThumbImage(thumbImageNormal, for: UIControlState())
        
    }
    
    func stationDidChange() {
        radioPlayer.stop()
        
        radioPlayer.contentURL = URL(string: currentStation.stationStreamURL)
        radioPlayer.prepareToPlay()
        radioPlayer.play()
        self.setupAudioSession()
        
        updateLabels("摇一摇即可收藏歌曲")
        
        // songLabel animate
        songLabel.animation = "flash"
        songLabel.repeatCount = 3
        songLabel.animate()
        
        resetAlbumArtwork()
        
        track.isPlaying = true
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
 
    func setupAudioSession() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }catch {
            print("error when set player! \(error)" )
        }
    }
    @IBAction func playPressed() {
        track.isPlaying = true
        playButtonEnable(false)
        radioPlayer.play()
        updateLabels()
        
        // songLabel Animation
        songLabel.animation = "flash"
        songLabel.animate()
        
        // Start NowPlaying Animation
        nowPlayingImageView.startAnimating()
        
 
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(self.track)
        
        self.sleepCounter?.startPlayer()
    }
    
    @IBAction func pausePressed() {
        track.isPlaying = false
        
        playButtonEnable()
        
        radioPlayer.pause()
        updateLabels("暂停播放...")
        nowPlayingImageView.stopAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(self.track)
        self.sleepCounter?.stopPlayer()
    }
    
    @IBAction func volumeChanged(_ sender:UISlider) {
        mpVolumeSlider.value = sender.value
    }
    
    func saveThisSong() {
        EZLoadingActivity.show("正在收藏", disableUI: false)
        self.savedSongs?.addOneSong(self.track)
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) { () -> Void in
            EZLoadingActivity.hide(success: true, animated: false)
        }
    }
    @IBAction func saveSongToFavorite(_ sender:UIButton){
        let optionMenu = UIAlertController(title: nil, message: "收藏歌曲", preferredStyle: .actionSheet)
        let option1 = UIAlertAction(title: "收藏这首歌曲", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.saveThisSong()
        })
        let option2 = UIAlertAction(title: "查看收藏夹", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showSavedSongsList()
        })
        let option3 = UIAlertAction(title: "取消", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancel")
        })

        optionMenu.addAction(option1)
        optionMenu.addAction(option2)
        optionMenu.addAction(option3)
        
        self.present(optionMenu, animated: true, completion: nil)

    }
    func showSavedSongsList() {
        performSegue(withIdentifier: "savedSongs", sender: self)
    }
    
    @IBAction func autoStopPressed() {
        let optionMenu = UIAlertController(title: nil, message: "自动停止", preferredStyle:.actionSheet)
        let option1 = UIAlertAction(title: "15分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sleepCounter?.startTimer(900)
        })
        let option2 = UIAlertAction(title: "30分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sleepCounter?.startTimer(1800)
        })
        let option3 = UIAlertAction(title: "45分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sleepCounter?.startTimer(2700)
        })
        let option4 = UIAlertAction(title: "60分钟后", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sleepCounter?.startTimer(3600)
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
    // MARK: - UI Helper Methods
    //*****************************************************************
    
    func convert(_ st: String) ->String{
        var st = st
        
        var byte:[UInt] = []
        for codeUnit in st.unicodeScalars{
            byte.append(UInt(codeUnit.value))
        }
        
        let t1 = Data(bytes: UnsafePointer<UInt>(byte), count: byte.count)
        let t2 = String(data: t1, encoding: String.Encoding.utf8)
        return t2!
    }
    
    func optimizeForDeviceSize() {
        
        // Adjust album size to fit iPhone 4s, 6s & 6s+
        let deviceHeight = self.view.bounds.height
        
        if deviceHeight == 480 {
            iPhone4 = true
            albumHeightConstraint.constant = 106
            view.updateConstraints()
        } else if deviceHeight == 667 {
            albumHeightConstraint.constant = 230
            view.updateConstraints()
        } else if deviceHeight > 667 {
            albumHeightConstraint.constant = 260
            view.updateConstraints()
        }
    }
    
    func updateLabels(_ statusMessage: String = "") {
        
        if statusMessage != "" {
            // There's a an interruption or pause in the audio queue
            songLabel.text = statusMessage
            artistLabel.text = currentStation.stationName
            
        } else {
            // Radio is (hopefully) streaming properly
            if track != nil {
                songLabel.text = track.title
                artistLabel.text = track.artist
            }
        }
        
        // Hide station description when album art is displayed or on iPhone 4
        if track.artworkLoaded || iPhone4 {
            stationDescLabel.isHidden = true
        } else {
            stationDescLabel.isHidden = false
            stationDescLabel.text = currentStation.stationDesc
        }
    }
    
    func playButtonEnable(_ enabled: Bool = true) {
        if enabled {
            playButton.isEnabled = true
            pauseButton.isEnabled = false
            track.isPlaying = false
        } else {
            playButton.isEnabled = false
            pauseButton.isEnabled = true
            track.isPlaying = true
        }
    }
    
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = UIViewAutoresizing()
        nowPlayingImageView.contentMode = UIViewContentMode.center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7
        
        // Create Top BarButton
        let barButton = UIButton(type: UIButtonType.custom)
        barButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40);
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
        
    }
    
    func startNowPlayingAnimation() {
        nowPlayingImageView.startAnimating()
    }
    
    //*****************************************************************
    // MARK: - Album Art
    //*****************************************************************
    
    func resetAlbumArtwork() {
        track.artworkLoaded = false
        track.artworkURL = currentStation.stationImageURL
        updateAlbumArtwork()
        stationDescLabel.isHidden = false
    }
    
    func updateAlbumArtwork() {
        track.artworkLoaded = false
        if track.artworkURL.range(of: "http") != nil {
            
            // Hide station description
            DispatchQueue.main.async {
                //self.albumImageView.image = nil
                self.stationDescLabel.isHidden = false
            }
            
            // Attempt to download album art from an API
            if let url = URL(string: track.artworkURL) {
                
                self.downloadTask = self.albumImageView.loadImageWithURL(url) { (image) in
                    
                    // Update track struct
                    self.track.artworkImage = image
                    self.track.artworkLoaded = true
                    
                    // Turn off network activity indicator
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                    // Animate artwork
                    self.albumImageView.animation = "wobble"
                    self.albumImageView.duration = 2
                    self.albumImageView.animate()
                    self.stationDescLabel.isHidden = true

                    // Update lockscreen
                    self.updateLockScreen()
                    
                    // Call delegate function that artwork updated
                    self.delegate?.artworkDidUpdate(self.track)
                }
            }
            
            // Hide the station description to make room for album art
            if track.artworkLoaded && !self.justBecameActive {
                self.stationDescLabel.isHidden = true
                self.justBecameActive = false
            }
            
        } else if track.artworkURL != "" {
            // Local artwork
            self.albumImageView.image = UIImage(named: track.artworkURL)
            track.artworkImage = albumImageView.image
            track.artworkLoaded = true
            
            // Call delegate function that artwork updated
            self.delegate?.artworkDidUpdate(self.track)
            
        } else {
            // No Station or API art found, use default art
            self.albumImageView.image = UIImage(named: "albumArt")
            track.artworkImage = albumImageView.image
        }
        
        // Force app to update display
        self.view.setNeedsDisplay()
    }

    // Call LastFM or iTunes API to get album art url
    
    func queryAlbumArt() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Construct either LastFM or iTunes API call URL
        let queryURL: String
        if useLastFM {
            queryURL = String(format: "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=%@&artist=%@&track=%@&format=json", apiKey, track.artist, track.title)
        } else {
            queryURL = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song", track.artist, track.title)
        }
        
        let escapedURL = queryURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        // Query API
        DataManager.getTrackDataWithSuccess(escapedURL!) { (data) in
            
            if DEBUG_LOG {
                print("API SUCCESSFUL RETURN")
                print("url: \(escapedURL!)")
            }
            
            let json = JSON(data: data!)
            
            if useLastFM {
                // Get Largest Sized LastFM Image
                if let imageArray = json["track"]["album"]["image"].array {
                    
                    let arrayCount = imageArray.count
                    let lastImage = imageArray[arrayCount - 1]
                    
                    if let artURL = lastImage["#text"].string {
                        
                        // Check for Default Last FM Image
                        if artURL.range(of: "/noimage/") != nil {
                            self.resetAlbumArtwork()
                            
                        } else {
                            // LastFM image found!
                            self.track.artworkURL = artURL
                            self.track.artworkLoaded = true
                            self.updateAlbumArtwork()
                        }
                        
                    } else {
                        self.resetAlbumArtwork()
                    }
                } else {
                    self.resetAlbumArtwork()
                }
            
            } else {
                // Use iTunes API. Images are 100px by 100px
                if let artURL = json["results"][0]["artworkUrl100"].string {
                    let newURL = artURL.replacingOccurrences(of: "100x100", with: "225x225")
                    
                    if DEBUG_LOG { print("iTunes artURL: \(newURL)") }
                    
                    self.track.artworkURL = newURL
                    self.track.artworkLoaded = true
                    self.updateAlbumArtwork()
                } else {
                    self.resetAlbumArtwork()
                }
            }
            
        }
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "InfoDetail" {
            let infoController = segue.destination as! InfoDetailViewController
            infoController.currentStation = currentStation
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "InfoDetail", sender: self)
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen() {
        
        // Update notification/lock screen
        let albumArtwork = MPMediaItemArtwork(image: track.artworkImage!)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    override func remoteControlReceived(with receivedEvent: UIEvent?) {
        super.remoteControlReceived(with: receivedEvent)
        
        if receivedEvent!.type == UIEventType.remoteControl {
            
            switch receivedEvent!.subtype {
            case .remoteControlPlay:
                playPressed()
            case .remoteControlStop:
                pausePressed()
            case .remoteControlTogglePlayPause:
                if track.isPlaying {
                    pausePressed()
                }else {
                    playPressed()
                }
            case .remoteControlPause:
                pausePressed()
            default:
                break
            }
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            self.saveThisSong()
        }
    }
    
    func processMetaData(_ firstMeta:MPTimedMetadata) {
        let metaData = firstMeta.value as! String
        print("meta data is:\(metaData)")
        var stringParts = [String]()
        if metaData.range(of: " - ") != nil {
            stringParts = metaData.components(separatedBy: " - ")
        } else {
            stringParts = metaData.components(separatedBy: "-")
        }
        if #available(iOS 11.0, *) {
            track.artist = stringParts[0]
            track.title = stringParts[1]
        } else {
            track.artist = self.convert(stringParts[0])
            track.title = self.convert(stringParts[0])
        }
        

        if stringParts.count > 1 {
            track.title = stringParts[1]
//            track.title = self.convert(stringParts[1])
        }
        
       
        if track.artist == "" && track.title == "" {
            track.artist = currentStation.stationDesc
            track.title = currentStation.stationName
        }
    }
    //*****************************************************************
    // MARK: - MetaData Updated Notification
    //*****************************************************************
    
    func metadataUpdated(_ n: Notification)
    {
        if(radioPlayer.timedMetadata != nil && radioPlayer.timedMetadata.count > 0)
        {
            startNowPlayingAnimation()
            let currentSongName = track.title
//            let firstMeta: MPTimedMetadata = radioPlayer.timedMetadata.first as! MPTimedMetadata
            self.processMetaData(radioPlayer.timedMetadata.first as! MPTimedMetadata)
            
            DispatchQueue.main.async {
                
                if currentSongName != self.track.title {
                    
                    if DEBUG_LOG {
                        print("METADATA artist: \(self.track.artist) | title: \(self.track.title)")
                    }
                    
                    // Update Labels
                    self.artistLabel.text = self.track.artist
                    self.songLabel.text = self.track.title

                    
                    // songLabel animation
                    self.songLabel.animation = "zoomIn"
                    self.songLabel.duration = 1.5
                    self.songLabel.damping = 1
                    self.songLabel.animate()
                    
                    // Update Stations Screen
                    self.delegate?.songMetaDataDidUpdate(self.track)
                    
                    // Query API for album art
                    self.resetAlbumArtwork()
                    self.queryAlbumArt()
                    self.updateLockScreen()
                    
                }
            }
        }
    }
}
extension NowPlayingViewController:countDelegate {
    func didUpdateEverySeconds(_ statusString: String) {
        if (statusString == "自动停止") {
            self.autoStopButton.setTitle("自动停止", for: UIControlState())
            pausePressed()
            return
        }
        UIView.performWithoutAnimation({ () -> Void in
            self.autoStopButton.setTitle(statusString, for: UIControlState())
            self.autoStopButton.layoutIfNeeded()
        })
    }
    
    func didUpdateDataUsage(_ dataUsageString : String) {
        self.dataUsageLabel.text = dataUsageString
    }
}
