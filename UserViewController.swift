//
//  UserViewController.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/23/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit
import JGProgressHUD

public var playlist = [Track]()

class UserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var popMenu: PopMenu!
    var HUD: JGProgressHUD!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, self.tableView.bounds.size.height, 1))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        HUD = JGProgressHUD()
        HUD.textLabel.text = "Connecting"
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "PlaylistView")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewWillLayoutSubviews() {
        playlist = UserViewController.loadPlaylist()
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlist.count > 0 {
            return playlist.count
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRectMake(0,0,tableView.frame.size.width,50))
        footerView.backgroundColor = UIColor.clearColor()
        return footerView
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if playlist.count > 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UserTableViewCell
            if playlist[indexPath.row].artwork_url != "null" {
                cell.img.af_setImageWithURL(NSURL(string: playlist[indexPath.row].artwork_url)!)
            } else {
                cell.img.image = UIImage(named: "ic_artwork")
            }
            cell.title_song.text = playlist[indexPath.row].title_song
            cell.username.text = playlist[indexPath.row].username
            cell.playback_count.text = playlist[indexPath.row].playback_count
            cell.duration.text = playlist[indexPath.row].duration
            cell.btnMore.tag = indexPath.row
            cell.btnMore.addTarget(self, action: #selector(UserViewController.showMenu(_:)), forControlEvents: .TouchUpInside)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("cellNone", forIndexPath: indexPath)
            cell.selectionStyle = .None
            tableView.scrollEnabled = false
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if playlist.count > 0 {
            return 100
        } else {
            return self.view.bounds.height
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if playlist.count > 0 {
            source = 2
            let mainView = self.parentViewController?.parentViewController as! MainViewController
            if playlist[indexPath.row].artwork_url != "null" {
                mainView.song_artwork.af_setImageWithURL(NSURL(string: playlist[indexPath.row].artwork_url)!)
            } else {
                mainView.song_artwork.image = UIImage(named: "ic_artwork")
            }
            
            mainView.song_title.text = playlist[indexPath.row].title_song
            mainView.userName.text = playlist[indexPath.row].username
            
            mainView.labelFirst.text = ""
            
            self.HUD.showInView(self.view, animated: true)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                currentIndex = indexPath.row
                MusicHandler.configNowPlayingInfo()
                dispatch_async(dispatch_get_main_queue(), {
                    let url = NSURL(string: playlist[indexPath.row].stream_url)
                    let dataSource = STKAudioPlayer.dataSourceFromURL(url!)
                    audioPlayer.setDataSource(dataSource, withQueueItemId: SampleQueueId(url: url, andCount: 0))
                    let musicview = self.storyboard?.instantiateViewControllerWithIdentifier("MusicView") as! MusicViewController
                    self.presentViewController(musicview, animated: true, completion: nil)
                    self.HUD.dismiss()
                })
            })
        }
    }
    
    @IBAction func showMenu(sender: UIButton){
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "showMenuInPlaylist", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        
        let items = NSMutableArray(capacity: 3)
        var menuItem = MenuItem(title: "Like", iconName: "ic_like_color")
        items.addObject(menuItem)
        menuItem = MenuItem(title: "Delete song", iconName: "ic_delete_color")
        items.addObject(menuItem)
        menuItem = MenuItem(title: "Share", iconName: "ic_share_color")
        items.addObject(menuItem)
        
        if popMenu == nil {
            popMenu = PopMenu(frame: self.view.bounds, items: items as [AnyObject])
            popMenu.menuAnimationType = PopMenuAnimationType.Sina
        }
        if popMenu.isShowed {
            return
        }
        popMenu.didSelectedItemCompletion = {
            selectedItem in
            if selectedItem.title == "Like" {
                let tracker = GAI.sharedInstance().defaultTracker
                let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "LikedSong", label: nil, value: nil)
                tracker.send(event.build() as [NSObject : AnyObject])
                CALayerExt.showHint("Liked this song", view: self.view!)
            }
            if selectedItem.title == "Delete song" {
                let tracker = GAI.sharedInstance().defaultTracker
                let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "DeleteSongInPlaylist", label: nil, value: nil)
                tracker.send(event.build() as [NSObject : AnyObject])
                let database = Database.connectdb1("playlist", type: "sqlite")
                let query = "DELETE FROM main.playlist WHERE song_title = '\(playlist[sender.tag].title_song)' AND song_artwork = '\(playlist[sender.tag].artwork_url)';"
                Database.db_query(query, database: database)
                sqlite3_close(database)
                playlist = UserViewController.loadPlaylist()
                self.tableView.reloadData()
                CALayerExt.showHint("Delete song complete", view: self.view!)
            }
            if selectedItem.title == "Share" {
                let tracker = GAI.sharedInstance().defaultTracker
                let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "shareSong", label: nil, value: nil)
                tracker.send(event.build() as [NSObject : AnyObject])
                let activityViewController = UIActivityViewController(
                    activityItems: [NSURL(string: playlist[sender.tag].permalink_url)!],
                    applicationActivities: nil)
                self.presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
        popMenu.showMenuAtView(self.view)
    }
    
    static func loadPlaylist() -> [Track] {
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
