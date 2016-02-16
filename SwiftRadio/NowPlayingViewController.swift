//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer

//*****************************************************************
// Protocol
// Updates the StationsViewController when the track changes
//*****************************************************************

protocol NowPlayingViewControllerDelegate: class {
    func songMetaDataDidUpdate(track: Track)
    func artworkDidUpdate(track: Track)
    func trackPlayingToggled(track: Track)
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
    
    var currentStation: RadioStation!
    var downloadTask: NSURLSessionDownloadTask?
    var iPhone4 = false
    var justBecameActive = false
    var newStation = true
    var nowPlayingImageView: UIImageView!
    let radioPlayer = Player.radio
    var track: Track!
    var mpVolumeSlider = UISlider()
    var sleepTimer = NSTimer()
    var sleepCounter: Count?
    
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
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "didBecomeActiveNotificationReceived",
            name:"UIApplicationDidBecomeActiveNotification",
            object: nil)
        
        // Notification for MediaPlayer metadata updated
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("metadataUpdated:"),
            name:MPMoviePlayerTimedMetadataUpdatedNotification,
            object: nil);
        
        // Check for station change
        if newStation {
            track = Track()
            stationDidChange()
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
        self.sleepCounter = Count.sharedInstance
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
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name:"UIApplicationDidBecomeActiveNotification",
            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: MPMoviePlayerTimedMetadataUpdatedNotification,
            object: nil)
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    func setupPlayer() {
        radioPlayer.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        radioPlayer.view.sizeToFit()
        radioPlayer.movieSourceType = MPMovieSourceType.Streaming
        radioPlayer.fullscreen = false
        radioPlayer.shouldAutoplay = true
        radioPlayer.prepareToPlay()
        radioPlayer.controlStyle = MPMovieControlStyle.None
    }
  
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        volumeParentView.backgroundColor = UIColor.clearColor()
        let volumeView = MPVolumeView(frame: volumeParentView.bounds)
        for view in volumeView.subviews {
            let uiview: UIView = view as UIView
             if (uiview.description as NSString).rangeOfString("MPVolumeSlider").location != NSNotFound {
                mpVolumeSlider = (uiview as! UISlider)
            }
        }
        
        let thumbImageNormal = UIImage(named: "slider-ball")
        slider?.setThumbImage(thumbImageNormal, forState: .Normal)
        
    }
    
    func stationDidChange() {
        radioPlayer.stop()
        
        radioPlayer.contentURL = NSURL(string: currentStation.stationStreamURL)
        radioPlayer.prepareToPlay()
        radioPlayer.play()
        
        updateLabels("Loading Station...")
        
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
    }
    
    @IBAction func pausePressed() {
        track.isPlaying = false
        
        playButtonEnable()
        
        radioPlayer.pause()
        updateLabels("Station Paused...")
        nowPlayingImageView.stopAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(self.track)
    }
    
    @IBAction func volumeChanged(sender:UISlider) {
        mpVolumeSlider.value = sender.value
    }
    
    @IBAction func autoStopPressed() {
        let optionMenu = UIAlertController(title: nil, message: "Auto stop in", preferredStyle:.ActionSheet)
        let option1 = UIAlertAction(title: "15mins", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Will stop in 15mins")
            self.sleepCounter?.startTimer(900)
        })
        let option2 = UIAlertAction(title: "30mins", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Will stop in 30mins")
            self.sleepCounter?.startTimer(1800)
        })
        let option3 = UIAlertAction(title: "45mins", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Will stop in 45mins")
            self.sleepCounter?.startTimer(2700)
        })
        let option4 = UIAlertAction(title: "60mins", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Will stop in 60mins")
            self.sleepCounter?.startTimer(3600)
        })
        let option5 = UIAlertAction(title: "Cancel", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        optionMenu.addAction(option1)
        optionMenu.addAction(option2)
        optionMenu.addAction(option3)
        optionMenu.addAction(option4)
        optionMenu.addAction(option5)
        
        self.presentViewController(optionMenu, animated: true, completion: nil)
        
    }
    
    

    //*****************************************************************
    // MARK: - UI Helper Methods
    //*****************************************************************
    
    func convert(var st: String) ->String{
        
        var byte:[UInt8] = []
        for codeUnit in st.unicodeScalars{
            byte.append(UInt8(codeUnit.value))
        }
        
        let t1 = NSData(bytes: byte, length: byte.count)
        let t2 = String(data: t1, encoding: NSUTF8StringEncoding)
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
    
    func updateLabels(statusMessage: String = "") {
        
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
            stationDescLabel.hidden = true
        } else {
            stationDescLabel.hidden = false
            stationDescLabel.text = currentStation.stationDesc
        }
    }
    
    func playButtonEnable(enabled: Bool = true) {
        if enabled {
            playButton.enabled = true
            pauseButton.enabled = false
            track.isPlaying = false
        } else {
            playButton.enabled = false
            pauseButton.enabled = true
            track.isPlaying = true
        }
    }
    
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = UIViewAutoresizing.None
        nowPlayingImageView.contentMode = UIViewContentMode.Center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7
        
        // Create Top BarButton
        let barButton = UIButton(type: UIButtonType.Custom)
        barButton.frame = CGRectMake(0, 0, 40, 40);
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
        stationDescLabel.hidden = false
    }
    
    func updateAlbumArtwork() {
        track.artworkLoaded = false
        if track.artworkURL.rangeOfString("http") != nil {
            
            // Hide station description
            dispatch_async(dispatch_get_main_queue()) {
                //self.albumImageView.image = nil
                self.stationDescLabel.hidden = false
            }
            
            // Attempt to download album art from an API
            if let url = NSURL(string: track.artworkURL) {
                
                self.downloadTask = self.albumImageView.loadImageWithURL(url) { (image) in
                    
                    // Update track struct
                    self.track.artworkImage = image
                    self.track.artworkLoaded = true
                    
                    // Turn off network activity indicator
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                    // Animate artwork
                    self.albumImageView.animation = "wobble"
                    self.albumImageView.duration = 2
                    self.albumImageView.animate()
                    self.stationDescLabel.hidden = true

                    // Update lockscreen
                    self.updateLockScreen()
                    
                    // Call delegate function that artwork updated
                    self.delegate?.artworkDidUpdate(self.track)
                }
            }
            
            // Hide the station description to make room for album art
            if track.artworkLoaded && !self.justBecameActive {
                self.stationDescLabel.hidden = true
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
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Construct either LastFM or iTunes API call URL
        let queryURL: String
        if useLastFM {
            queryURL = String(format: "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=%@&artist=%@&track=%@&format=json", apiKey, track.artist, track.title)
        } else {
            queryURL = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song", track.artist, track.title)
        }
        
        let escapedURL = queryURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        // Query API
        DataManager.getTrackDataWithSuccess(escapedURL!) { (data) in
            
            if DEBUG_LOG {
                print("API SUCCESSFUL RETURN")
                print("url: \(escapedURL!)")
            }
            
            let json = JSON(data: data)
            
            if useLastFM {
                // Get Largest Sized LastFM Image
                if let imageArray = json["track"]["album"]["image"].array {
                    
                    let arrayCount = imageArray.count
                    let lastImage = imageArray[arrayCount - 1]
                    
                    if let artURL = lastImage["#text"].string {
                        
                        // Check for Default Last FM Image
                        if artURL.rangeOfString("/noimage/") != nil {
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
                    let newURL = artURL.stringByReplacingOccurrencesOfString("100x100", withString: "225x225")
                    
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "InfoDetail" {
            let infoController = segue.destinationViewController as! InfoDetailViewController
            infoController.currentStation = currentStation
        }
    }
    
    @IBAction func infoButtonPressed(sender: UIButton) {
        performSegueWithIdentifier("InfoDetail", sender: self)
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen() {
        
        // Update notification/lock screen
        let albumArtwork = MPMediaItemArtwork(image: track.artworkImage!)
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    override func remoteControlReceivedWithEvent(receivedEvent: UIEvent?) {
        super.remoteControlReceivedWithEvent(receivedEvent)
        
        if receivedEvent!.type == UIEventType.RemoteControl {
            
            switch receivedEvent!.subtype {
            case .RemoteControlPlay:
                playPressed()
            case .RemoteControlPause:
                pausePressed()
            default:
                break
            }
        }
    }
    
    //*****************************************************************
    // MARK: - MetaData Updated Notification
    //*****************************************************************
    
    func metadataUpdated(n: NSNotification)
    {
        if(radioPlayer.timedMetadata != nil && radioPlayer.timedMetadata.count > 0)
        {
            startNowPlayingAnimation()
            
            let firstMeta: MPTimedMetadata = radioPlayer.timedMetadata.first as! MPTimedMetadata
            let metaData = firstMeta.value as! String
            print("meta data is:\(metaData)")
            var stringParts = [String]()
            if metaData.rangeOfString(" - ") != nil {
                stringParts = metaData.componentsSeparatedByString(" - ")
            } else {
                stringParts = metaData.componentsSeparatedByString("-")
            }
            let currentSongName = track.title
            if (currentStation.stationName == "UFM1003") && (metaData.rangeOfString("artist") != nil){
                let metaData1003 = metaData.stringByRemovingPercentEncoding
                let track1003 = metaData.componentsSeparatedByString("track")[1].componentsSeparatedByString("artist")[0].stringByRemovingPercentEncoding?.componentsSeparatedByString("\"")[2]
                let artist1003 = metaData.componentsSeparatedByString("artist")[1].componentsSeparatedByString("next_song")[0].stringByRemovingPercentEncoding?.componentsSeparatedByString("\"")[2]
                stringParts = []
                stringParts = [artist1003!,track1003!]
                print (artist1003,track1003)
                track.artist = artist1003!
                track.title = track1003!
            } else if (currentStation.stationName != "UFM1003"){
                 // Set artist & songvariables
                track.artist = self.convert(stringParts[0])
                track.title = self.convert(stringParts[0])
                if stringParts.count > 1 {
                    track.title = self.convert(stringParts[1])
                }
            }
    
            if track.artist == "" && track.title == "" {
                track.artist = currentStation.stationDesc
                track.title = currentStation.stationName
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
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
    func didUpdateEverySeconds(statusString: String) {
        if (statusString == "Sleep") {
            self.autoStopButton.setTitle("Sleep", forState: UIControlState.Normal)
            pausePressed()
            return
        }
        UIView.performWithoutAnimation({ () -> Void in
            self.autoStopButton.setTitle(statusString, forState: UIControlState.Normal)
            self.autoStopButton.layoutIfNeeded()
        })
    }
}
