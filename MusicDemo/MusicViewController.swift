//
//  MusicViewController.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/28/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import GoogleMobileAds

public var currentTrack:Track!
public var cycleType:Int = 0 //0. loop, 1. shuffer, 2. loop one

class MusicViewController: UIViewController {
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var song_artwork: UIImageView!
    @IBOutlet weak var song_artwork_border: UIImageView!
    @IBOutlet var song_title: CBAutoScrollLabel!
    @IBOutlet var song_username: CBAutoScrollLabel!
    @IBOutlet var like_button: UIButton!
    @IBOutlet var begin_time_label: UILabel!
    @IBOutlet var end_time_label: UILabel!
    @IBOutlet var previous_song: UIButton!
    @IBOutlet var next_song: UIButton!
    @IBOutlet var song_toggle: UIButton!
    @IBOutlet var song_cycle: UIButton!
    @IBOutlet var song_more: UIButton!
    @IBOutlet var song_slider: UISlider!
    @IBOutlet weak var bannerView: GADBannerView!
    var visualEffectView: UIVisualEffectView = UIVisualEffectView()
    var songDurationTimer: NSTimer!
    var isPlayingCurrent = false
    
    var track:Track!

    static func shareInstance() -> MusicViewController {
        let shareMusicVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("MusicView") as! MusicViewController
        return shareMusicVC
    }
    
    @IBAction func dismissTouch(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "touchDismissMusicView", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        currentTrack = track
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didChangeValue(sender: UISlider) {
        audioPlayer.seekToTime(Double(song_slider.value))
        updateSlide()
    }
    
    @IBAction func didTouchMusicToggle(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "touchSongToggle", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        if audioPlayer.state == STKAudioPlayerState.Paused {
            //song_toggle.setImage(UIImage(named: "big_pause_button"), forState: .Normal)
            CALayerExt.resumeLayer(song_artwork.layer)
            CALayerExt.resumeLayer(song_artwork_border.layer)
            audioPlayer.resume()
        } else {
            song_toggle.setImage(UIImage(named: "big_play_button"), forState: .Normal)
            CALayerExt.pauseLayer(song_artwork.layer)
            CALayerExt.pauseLayer(song_artwork_border.layer)
            audioPlayer.pause()
        }
    }
    
    @IBAction func didTouchPreviousSong(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "touchPrevious", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        PreviousSong()
        setupBackgroundImage()
        setupTitleSong()
    }
    
    func PreviousSong() {
        let size:Int!
        let track1:Track!
        if source == 0 {
            size = tracksShow.count
            track1 = tracksShow[currentIndex]
        } else if source == 1 {
            size = tophit.count
            track1 = tophit[currentIndex]
        } else {
            size = playlist.count
            track1 = playlist[currentIndex]
        }
        
        if size == 1{
            CALayerExt.showHint("Now, list only one song", view: self.view)
            return
        }
        if cycleType == 1 && size > 2 {
            currentIndex = getRandomIndex()
        } else {
            if currentIndex == 0 {
                currentIndex = size - 1
            } else {
                currentIndex = currentIndex - 1
            }
        }
        setupStream()
        currentTrack = track1
        MusicHandler.configNowPlayingInfo()
    }
    
    @IBAction func didTouchNextSong(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "touchNext", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        nextSong()
        setupBackgroundImage()
        setupTitleSong()
    }
    
    func nextSong() {
        let size:Int!
        let track1:Track!
        if source == 0 {
            size = tracksShow.count
            track1 = tracksShow[currentIndex]
        } else if source == 1 {
            size = tophit.count
            track1 = tophit[currentIndex]
        } else {
            size = playlist.count
            track1 = playlist[currentIndex]
        }
        
        if size == 1 {
            CALayerExt.showHint("Now, list only one song", view: self.view)
            return
        }
        if cycleType == 1 && size > 2 {
            currentIndex = getRandomIndex()
        } else {
            getNextIndex()
        }
        setupStream()
        currentTrack = track1
        MusicHandler.configNowPlayingInfo()
    }
    
    @IBAction func didTouchCycleSong(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "touchCycle", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        if cycleType == 0 {
            cycleType = 1
            song_cycle.setImage(UIImage(named: "shuffle_icon"), forState: .Normal)
        } else if cycleType == 1 {
            cycleType = 2
            song_cycle.setImage(UIImage(named: "loop_single_icon"), forState: .Normal)
        } else {
            cycleType = 0
            song_cycle.setImage(UIImage(named: "loop_all_icon"), forState: .Normal)
        }
    }
    
    @IBAction func didTouchDownloadSong(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "touchAddSong", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        let alertController = UIAlertController(title: "", message: "You want add this song to your playlist?", preferredStyle: UIAlertControllerStyle.Alert)
        let actionOk = UIAlertAction(title: "OK",style: .Cancel,handler: {
            Void in
            let a = playlist.filter(){ $0.title_song == self.track.title_song && $0.artwork_url == self.track.artwork_url }
            if a.count > 0 {
                CALayerExt.showHint("Song already in your playlist", view: self.view)
            } else {
                let database: COpaquePointer = Database.connectdb1("playlist", type: "sqlite")
                let query = "INSERT INTO main.playlist (\"song_title\",\"song_artwork\",\"song_duration\",\"song_duration_f\",\"song_username\",\"song_playback_count\",\"song_stream_url\",\"song_permalink_url\") VALUES ('\(self.track.title_song)','\(self.track.artwork_url)','\(self.track.duration)','\(self.track.duration_f)','\(self.track.username)','\(self.track.playback_count)','\(self.track.stream_url)','\(self.track.permalink_url)');"
                Database.db_query(query, database: database)
                sqlite3_close(database)
                playlist = UserViewController.loadPlaylist()
                CALayerExt.showHint("Added song to playlist", view: self.view)
            }
        })
        let actionLogout = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)
        alertController.addAction(actionOk)
        alertController.addAction(actionLogout)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isPlayingCurrent == false {
            let track1:Track!
            if source == 0 {
                track1 = tracksShow[currentIndex]
            } else if source == 1 {
                track1 = tophit[currentIndex]
            } else {
                track1 = playlist[currentIndex]
            }
            track = track1
        } else {
            track = currentTrack
        }
        
        song_slider.setThumbImage(UIImage(named: "music_slider_circle"), forState: .Normal)
        song_slider.setThumbImage(UIImage(named: "music_slider_circle"), forState: .Highlighted)
        
        songDurationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(MusicViewController.updateSlide), userInfo: nil, repeats: true)
        if cycleType == 0 {
            song_cycle.setImage(UIImage(named: "loop_all_icon"), forState: .Normal)
        } else if cycleType == 1 {
            song_cycle.setImage(UIImage(named: "shuffle_icon"), forState: .Normal)
        } else {
            song_cycle.setImage(UIImage(named: "loop_single_icon"), forState: .Normal)
        }
    }
    
    override func viewWillAppear(animated: Bool){
        setupBackgroundImage()
        setupTitleSong()
        setupAd()
        if audioPlayer.state == STKAudioPlayerState.Paused {
            CALayerExt.pauseLayer(song_artwork.layer)
            CALayerExt.pauseLayer(song_artwork_border.layer)
        }
        if cycleType == 0 {
            song_cycle.setImage(UIImage(named: "loop_all_icon"), forState: .Normal)
        } else if cycleType == 1 {
            song_cycle.setImage(UIImage(named: "shuffle_icon"), forState: .Normal)
        } else {
            song_cycle.setImage(UIImage(named: "loop_single_icon"), forState: .Normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupAd() {
        //self.bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        self.bannerView.adUnitID = "ca-app-pub-9182085626379132/3738254404"
        self.bannerView.rootViewController = self
        let request = GADRequest()
        //request.testDevices = [ kGADSimulatorID ]
        self.bannerView.loadRequest(request)
    }
    
    func getNextIndex() {
        let size:Int!
        if source == 0 {
            size = tracksShow.count
        } else if source == 1 {
            size = tophit.count
        } else {
            size = playlist.count
        }
        
        if currentIndex == size - 1 {
            currentIndex = 0
        } else {
            currentIndex = currentIndex + 1
        }
    }
    
    func getRandomIndex() -> Int {
        let size:Int!
        if source == 0 {
            size = tracksShow.count
        } else if source == 1 {
            size = tophit.count
        } else {
            size = playlist.count
        }
        
        let t = Int(arc4random()) % size
        return t
    }
    
    func setupStream(){
        let track1:Track!
        if source == 0 {
            track1 = tracksShow[currentIndex]
        } else if source == 1 {
            track1 = tophit[currentIndex]
        } else {
            track1 = playlist[currentIndex]
        }
        
        track = track1
        let url = NSURL(string: track.stream_url)
        let dataSource = STKAudioPlayer.dataSourceFromURL(url!)
        audioPlayer.setDataSource(dataSource, withQueueItemId: SampleQueueId(url: url, andCount: 0))
    }
    
    func setupBackgroundImage(){
        let screenW = UIScreen.mainScreen().bounds.width
        if screenW == 375 {
            song_artwork.layer.cornerRadius = 150/2
        } else if screenW == 320 {
            song_artwork.layer.cornerRadius = 95/2
        } else if screenW == 414 {
            song_artwork.layer.cornerRadius = 189/2
        } else if screenW == 1024 {
            song_artwork.layer.cornerRadius = 799/2
        } else {
            song_artwork.layer.cornerRadius = 543/2
        }
        
        song_artwork.layer.masksToBounds = true
        
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2.0)
        rotateAnimation.duration = 20
        rotateAnimation.repeatCount = Float(track.duration_f) / 20000
        song_artwork.layer.addAnimation(rotateAnimation, forKey: nil)
        song_artwork_border.layer.addAnimation(rotateAnimation, forKey: nil)
        
        if track.artwork_url != "null"{
            song_artwork.af_setImageWithURL(NSURL(string: track.artwork_url)!)
            backgroundImageView.af_setImageWithURL(NSURL(string: track.artwork_url)!)
        } else {
            //song_artwork.image = UIImage(named: "ic_artwork")
            //backgroundImageView.image = UIImage(named: "ic_artwork")
            song_artwork.image = UIImage(named: "Untitled-1")
            backgroundImageView.image = UIImage(named: "Untitled-1")
        }
        
        if !visualEffectView.isDescendantOfView(backgroundView) {
            let blurEffect: UIVisualEffect!
            blurEffect = UIBlurEffect(style: .Light)
            visualEffectView = UIVisualEffectView(effect: blurEffect)
            visualEffectView.frame = self.view.bounds
            backgroundView.addSubview(visualEffectView)
        }
        
        backgroundImageView.startTransitionAnimation()
        song_artwork.startTransitionAnimation()
    }
    
    func setupTitleSong(){
        song_title.text = track.title_song
        song_title.textColor = UIColor.whiteColor()
        song_title.labelSpacing = 30
        song_title.pauseInterval = 2.0
        song_title.font = UIFont.systemFontOfSize(20)
        song_title.scrollSpeed = 30
        song_title.textAlignment = NSTextAlignment.Center
        song_title.fadeLength = 15
        song_title.scrollDirection = .Left
        song_title.observeApplicationNotifications()
        
        song_username.text = track.username
        song_username.textAlignment = .Center
        song_username.textColor = UIColor.whiteColor()
        song_username.pauseInterval = 2.2
        song_username.font = UIFont.systemFontOfSize(15)
        song_username.fadeLength = 15
        song_username.observeApplicationNotifications()
    }
    
    func updateSlide(){
        if audioPlayer.duration != 0 {
            song_slider.minimumValue = 0
            song_slider.maximumValue = Float(track.duration_f)/1000
            song_slider.value = Float(audioPlayer.progress)
        }
        if audioPlayer.state == STKAudioPlayerState.Buffering {
            song_toggle.setImage(UIImage(named: "big_play_button"), forState: .Normal)
        } else {
            if audioPlayer.state != STKAudioPlayerState.Paused {
                song_toggle.setImage(UIImage(named: "big_pause_button"), forState: .Normal)
            }
        }
        if audioPlayer.state == .Stopped {
            if cycleType == 0 {
                getNextIndex()
                setupStream()
                setupBackgroundImage()
                setupTitleSong()
                currentTrack = tracksShow[currentIndex]
                print(currentIndex)
            } else if cycleType == 1 {
                currentIndex = getRandomIndex()
                setupStream()
                setupBackgroundImage()
                setupTitleSong()
                currentTrack = tracksShow[currentIndex]
                print(currentIndex)
            } else {
                setupStream()
                setupBackgroundImage()
                setupTitleSong()
                currentTrack = tracksShow[currentIndex]
                print(currentIndex)
            }
            MusicHandler.configNowPlayingInfo()
        }        
        self.updateProcessLabelValue()
    }
    
    func updateProcessLabelValue(){
        let seconds = audioPlayer.progress % 60;
        let minutes = (audioPlayer.progress / 60) % 60;
        begin_time_label.text = String(format: "%d:%.2d", arguments: [Int(minutes),Int(seconds)])
        end_time_label.text = track.duration
    }
}
