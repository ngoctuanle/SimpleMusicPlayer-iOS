//
//  MainViewController.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/23/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit
import PagingMenuController
import MediaPlayer

class MainViewController: UIViewController, PagingMenuControllerDelegate {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var labelFirst: UILabel!
    @IBOutlet var song_artwork: UIImageView!
    @IBOutlet var song_title: CBAutoScrollLabel!
    @IBOutlet var userName: CBAutoScrollLabel!
    @IBOutlet var song_play: UIButton!
    @IBOutlet var song_more: UIButton!
    @IBAction func tap_song_play(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "changeSongState", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        if audioPlayer.state == STKAudioPlayerState.Paused {
            song_play.setImage(UIImage(named: "small_pause_button"), forState: .Normal)
            audioPlayer.resume()
        } else {
            song_play.setImage(UIImage(named: "small_play_button"), forState: .Normal)
            audioPlayer.pause()
        }
    }
    @IBAction func tap_song_more(sender: UIButton) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "showMusicView", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        let size:Int!
        if source == 0 {
            size = tracksShow.count
        } else if source == 1 {
            size = tophit.count
        } else {
            size = playlist.count
        }
        if size != 0 && currentTrack != nil {
            //searchController.active = false
            let musicview = self.storyboard?.instantiateViewControllerWithIdentifier("MusicView") as! MusicViewController
            musicview.isPlayingCurrent = true
            self.presentViewController(musicview, animated: true, completion: nil)
        } else {
            CALayerExt.showHint("No song playing", view: self.view)
        }
    }
    
    var visualEffectView: UIVisualEffectView = UIVisualEffectView()
    var DurationTimer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        playlist = loadPlaylist()
        
        // Do any additional setup after loading the view.
        let userController = self.storyboard?.instantiateViewControllerWithIdentifier("UserView") as! UserViewController
        let searchController = self.storyboard?.instantiateViewControllerWithIdentifier("SearchView") as! ViewController
        let aboutController = self.storyboard?.instantiateViewControllerWithIdentifier("AboutView") as! AboutViewController
        //let houseController = self.storyboard?.instantiateViewControllerWithIdentifier("HouseView") as! HouseViewController
        
        let viewControllers = [userController, /*houseController,*/ searchController, aboutController]
        
        let option = PagingMenuOptions()
        option.menuHeight = 40
        option.backgroundColor = UIColor.clearColor()
        option.selectedBackgroundColor = UIColor.clearColor()
        option.textColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.5)
        option.selectedTextColor = UIColor.whiteColor()
        if playlist.count > 0 {
            option.defaultPage = 0
        } else {
            option.defaultPage = 1
        }
        
        let pagingMenu = self.childViewControllers.first as! PagingMenuController
        pagingMenu.delegate = self
        pagingMenu.setup(viewControllers: viewControllers, options: option)
        
        song_title.text = ""
        song_title.textColor = UIColor.whiteColor()
        song_title.labelSpacing = 30
        song_title.pauseInterval = 2.0
        song_title.scrollSpeed = 30
        song_title.textAlignment = NSTextAlignment.Left
        song_title.fadeLength = 15
        song_title.scrollDirection = CBAutoScrollDirection.Left
        song_title.observeApplicationNotifications()
        
        userName.text = ""
        userName.textColor = UIColor.whiteColor()
        userName.pauseInterval = 2.2
        userName.textAlignment = NSTextAlignment.Left
        userName.font = UIFont.systemFontOfSize(13)
        userName.fadeLength = 15
        userName.observeApplicationNotifications()
        
        if !visualEffectView.isDescendantOfView(backgroundView) {
            let blurEffect: UIVisualEffect!
            blurEffect = UIBlurEffect(style: .Light)
            visualEffectView = UIVisualEffectView(effect: blurEffect)
            visualEffectView.frame = self.view.bounds
            backgroundView.addSubview(visualEffectView)
        }
        
        DurationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.updateToolbar), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func updateToolbar(){
        
        /*if isTopHitPlaying {
         source = 1
         } */
        
        var size:Int!
        if source == 0 {
            size = tracksShow.count
        } else if source == 1 {
            size = tophit.count
        } else {
            size = playlist.count
        }
        
        let mainView = self
        if size != 0 && currentIndex != nil {
            var track1:Track!
            if source == 0 {
                track1 = tracksShow[currentIndex]
            } else if source == 1 {
                track1 = tophit[currentIndex]
            } else {
                track1 = playlist[currentIndex]
            }
            
            if track1.artwork_url != "null" {
                mainView.song_artwork.af_setImageWithURL(NSURL(string: track1.artwork_url)!)
            } else {
                mainView.song_artwork.image = UIImage(named: "ic_artwork")
            }
            mainView.song_title.text = track1.title_song
            mainView.userName.text = track1.username
            currentTrack = track1
        }
        
        if audioPlayer.state == STKAudioPlayerState.Paused {
            mainView.song_play.setImage(UIImage(named: "small_play_button"), forState: .Normal)
        } else {
            mainView.song_play.setImage(UIImage(named: "small_pause_button"), forState: .Normal)
        }
    }
    
    func loadPlaylist() -> [Track] {
        var pl = [Track]()
        let database: COpaquePointer = Database.connectdb1("playlist", type: "sqlite")
        let statement: COpaquePointer = Database.db_select("SELECT * FROM playlist", database: database)
        while sqlite3_step(statement) == SQLITE_ROW {
            let rowdata0 = sqlite3_column_text(statement, 0)
            let song_title  = String.fromCString(UnsafePointer<CChar>(rowdata0))
            let rowdata1 = sqlite3_column_text(statement, 1)
            let song_artwork  = String.fromCString(UnsafePointer<CChar>(rowdata1))
            let rowdata2 = sqlite3_column_text(statement, 2)
            let song_duration  = String.fromCString(UnsafePointer<CChar>(rowdata2))
            let rowdata3 = sqlite3_column_double(statement, 3)
            let song_duration_f  = rowdata3
            let rowdata4 = sqlite3_column_text(statement, 4)
            let song_username  = String.fromCString(UnsafePointer<CChar>(rowdata4))
            let rowdata5 = sqlite3_column_text(statement, 5)
            let song_playback_count  = String.fromCString(UnsafePointer<CChar>(rowdata5))
            let rowdata6 = sqlite3_column_text(statement, 6)
            let song_stream_url  = String.fromCString(UnsafePointer<CChar>(rowdata6))
            let rowdata7 = sqlite3_column_text(statement, 7)
            let song_permalink_url = String.fromCString(UnsafePointer<CChar>(rowdata7))
            
            pl.append(Track(title_song: song_title,
                artwork_url: song_artwork,
                duration: song_duration,
                duration_f: song_duration_f as NSNumber,
                username: song_username,
                playback_count: song_playback_count,
                stream_url: song_stream_url,
                permalink_url: song_permalink_url))
        }
        sqlite3_finalize(statement)
        sqlite3_close(database)
        return pl
    }
}
