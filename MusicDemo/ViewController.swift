//
//  ViewController.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/13/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import AVFoundation
import AVKit
import MediaPlayer
import JGProgressHUD

public var tracksShow = [Track]()
public var tophit = [Track]()
public var audioPlayer = STKAudioPlayer()
//public let searchController = UISearchController(searchResultsController: nil)
public var currentIndex: Int!
public var source = 1 //0 - trackshows, 1 - tophit, 2 - playlist

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate{
    @IBOutlet var tableView: UITableView!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    var popMenu: PopMenu!
    var tophitTitle = ""
    
    var isShowTrack = false
    var isTopHit = false
    
    var clientid = "a204192a74c9b0597d7fb11170d08752"
    
    //var isSearch =  false
    
    var HUD: JGProgressHUD!
    
    //var DurationTimer: NSTimer!
    
    var tracks = [Track]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.clearColor()
        let idgroup = ["60947","16605","25722","10335","8951","27434"]
        let groupTitle = ["Top 40 Hits", "Top 40 Mashups and Remixes", "Top 40, POP, Dance remixes", "Pop/Club Top 40 DJ Live Mixes & Mixtapes!", "Top 40 Remixes", "Top 40 Club Mixes"]
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.indicator.hidden = false
        self.indicator.hidesWhenStopped = true
        self.indicator.startAnimating()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let index = Int(arc4random()) % idgroup.count
            tophit = self.loadTopHit(idgroup[index])
            self.tophitTitle = groupTitle[index]
            dispatch_async(dispatch_get_main_queue(), {
                self.indicator.stopAnimating()
                if tophit.count > 0 {
                    self.isTopHit = true
                    self.tableView.reloadData()
                }
            })
        })
        
        /*
        //setup search controller
        searchController.searchResultsUpdater = self
        //definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        //self.navigationController?.navigationBar.translucent = false
        searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar
        */
        
        self.syAddSearchBarInPosition(CGPointMake(10, 10), topInsetsOfInputBar: 20)
        self.sySearchInputBar.inputTextField.delegate = self
        self.sySearchInputBar.inputTextField.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        self.sySearchButton.placeholder = "Search"
        let result = self.storyboard?.instantiateViewControllerWithIdentifier("SearchResultView") as! SearchResultViewController
        self.sySearchResultsViewController = result
        self.sySearchButton.expanded = true
        
        //DurationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.updateToolbar), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        HUD = JGProgressHUD()
        HUD.textLabel.text = "Connecting"
        /*if self.respondsToSelector("edgesForExtendedLayout") {
            self.tableView.setContentOffset(CGPointMake(0, -20), animated: true)
        } else {
            self.tableView.setContentOffset(CGPointMake(0, searchController.searchBar.frame.size.height), animated: true)
        }*/
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "SearchView")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    func textFieldDidChange(textField: UITextField!) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "searchSong", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        if textField.text != "" {
            let str = textField.text
            (self.sySearchResultsViewController as! SearchResultViewController).tracks.removeAll(keepCapacity: false)
            (self.sySearchResultsViewController as! SearchResultViewController).tableView.reloadData()
            (self.sySearchResultsViewController as! SearchResultViewController).indicator.hidden = false
            (self.sySearchResultsViewController as! SearchResultViewController).indicator.startAnimating()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                tracksShow.removeAll(keepCapacity: false)
                let list = self.loadTracks(str!)
                dispatch_async(dispatch_get_main_queue(), {
                    if str == textField.text && textField.text != "" {
                        (self.sySearchResultsViewController as! SearchResultViewController).tracks.removeAll(keepCapacity: false)
                        tracksShow = list
                        if tracksShow.count > 0 {
                            if tracksShow.count < 5 {
                                for i in 0 ..< tracksShow.count
                                {
                                    (self.sySearchResultsViewController as! SearchResultViewController).tracks.append(tracksShow[i])
                                }
                            } else {
                                (self.sySearchResultsViewController as! SearchResultViewController).tracks.append(tracksShow[0])
                                (self.sySearchResultsViewController as! SearchResultViewController).tracks.append(tracksShow[1])
                                (self.sySearchResultsViewController as! SearchResultViewController).tracks.append(tracksShow[2])
                                (self.sySearchResultsViewController as! SearchResultViewController).tracks.append(tracksShow[3])
                                (self.sySearchResultsViewController as! SearchResultViewController).tracks.append(tracksShow[4])
                            }
                        }
                        (self.sySearchResultsViewController as! SearchResultViewController).str = str!
                        (self.sySearchResultsViewController as! SearchResultViewController).isSearchFinish = true
                        (self.sySearchResultsViewController as! SearchResultViewController).indicator.stopAnimating()
                        (self.sySearchResultsViewController as! SearchResultViewController).tableView.reloadData()
                    }
                })
            })
        } else {
            (self.sySearchResultsViewController as! SearchResultViewController).indicator.stopAnimating()
            (self.sySearchResultsViewController as! SearchResultViewController).tableView.reloadData()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("Keyword: \(textField.text!)")
        return true
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 70 {
            self.sySearchButton.expanded = false
        } else {
            self.sySearchButton.expanded = true
        }
    }
    
    /*func updateToolbar(){
        
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
        
        let mainView = self.parentViewController?.parentViewController as! MainViewController
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
    }*/
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if(isShowTrack){
                return tracksShow.count
            } else {
                if isTopHit {
                    return tophit.count + 1
                } else {
                    return 1
                }
            }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(isShowTrack){
                return 100
            } else {
                if isTopHit {
                    if indexPath.row == 0 {
                        return 44
                    } else {
                        return 100
                    }
                } else {
                    return self.view.bounds.height - 70
                }
            }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let track: Track
        if(isShowTrack){
                track = tracksShow[indexPath.row]
                let cell = tableView.dequeueReusableCellWithIdentifier("cellTrackDetail", forIndexPath: indexPath) as! TrackDetailTableViewCell
                cell.username.text = track.username
                cell.title_song.text = track.title_song
                if track.artwork_url != "null" {
                    cell.img.af_setImageWithURL(NSURL(string: track.artwork_url)!)
                } else {
                    cell.img.image = UIImage(named: "ic_artwork")
                }
                cell.duration.text = track.duration
                cell.playback.text = track.playback_count
                cell.btnMor.tag = indexPath.row
                cell.btnMor.addTarget(self, action: #selector(ViewController.showMenu(_:)), forControlEvents: .TouchUpInside)
                self.tableView.scrollEnabled = true
                return cell
            } else {
                if isTopHit {
                    self.tableView.scrollEnabled = true
                    if indexPath.row == 0 {
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellTopHit", forIndexPath: indexPath) as! TopHitCell
                        cell.label.text = tophitTitle
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0)
                        return cell
                    } else {
                        track = tophit[indexPath.row-1]
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellTrackDetail", forIndexPath: indexPath) as! TrackDetailTableViewCell
                        cell.username.text = track.username
                        cell.title_song.text = track.title_song
                        if track.artwork_url != "null" {
                            cell.img.af_setImageWithURL(NSURL(string: track.artwork_url)!)
                        } else {
                            cell.img.image = UIImage(named: "ic_artwork")
                        }
                        cell.duration.text = track.duration
                        cell.playback.text = track.playback_count
                        cell.btnMor.tag = indexPath.row
                        cell.btnMor.addTarget(self, action: #selector(ViewController.showMenu(_:)), forControlEvents: .TouchUpInside)
                        cell.backgroundColor = UIColor.clearColor()
                        return cell
                    }
                } else {
                    let cellPreSearch = tableView.dequeueReusableCellWithIdentifier("cellPreSearch", forIndexPath: indexPath)
                    cellPreSearch.selectionStyle = UITableViewCellSelectionStyle.None
                    self.tableView.scrollEnabled = false
                    return cellPreSearch
                }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "tapPlaySong", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        /*if searchController.active && searchController.searchBar.text != "" {
            if indexPath.row != tracks.count {
                source = 0
                let mainView = self.parentViewController?.parentViewController as! MainViewController
                if tracks[indexPath.row].artwork_url != "null" {
                    mainView.song_artwork.af_setImageWithURL(NSURL(string: tracks[indexPath.row].artwork_url)!)
                } else {
                    mainView.song_artwork.image = UIImage(named: "ic_artwork")
                }
                mainView.song_title.text = tracks[indexPath.row].title_song
                mainView.userName.text = tracks[indexPath.row].username
                
                self.isShowTrack = true
                self.tableView.reloadData()
                searchController.active = false
                
                mainView.labelFirst.text = ""
                
                tophit.removeAll(keepCapacity: false)
                
                self.HUD.showInView(self.view, animated: true)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    currentIndex = indexPath.row
                    MusicHandler.configNowPlayingInfo()
                    dispatch_async(dispatch_get_main_queue(), {
                        let url = NSURL(string: self.tracks[indexPath.row].stream_url)
                        let dataSource = STKAudioPlayer.dataSourceFromURL(url!)
                        audioPlayer.setDataSource(dataSource, withQueueItemId: SampleQueueId(url: url, andCount: 0))
                        let musicview = self.storyboard?.instantiateViewControllerWithIdentifier("MusicView") as! MusicViewController
                        self.presentViewController(musicview, animated: true, completion: nil)
                        self.HUD.dismiss()
                    })
                })
            } else {
                isSearch = true
                searchController.active = false
                self.isShowTrack = true
                self.tableView.reloadData()
            }
        } else { */
            if(isShowTrack) {
                source = 0
                let mainView = self.parentViewController?.parentViewController as! MainViewController
                if tracksShow[indexPath.row].artwork_url != "null" {
                    mainView.song_artwork.af_setImageWithURL(NSURL(string: tracksShow[indexPath.row].artwork_url)!)
                } else {
                    mainView.song_artwork.image = UIImage(named: "ic_artwork")
                }
                
                mainView.song_title.text = tracksShow[indexPath.row].title_song
                mainView.userName.text = tracksShow[indexPath.row].username
                
                mainView.labelFirst.text = ""
                
                tophit.removeAll(keepCapacity: false)
                
                self.HUD.showInView(self.view, animated: true)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    currentIndex = indexPath.row
                    MusicHandler.configNowPlayingInfo()
                    dispatch_async(dispatch_get_main_queue(), {
                        let url = NSURL(string: tracksShow[indexPath.row].stream_url)
                        let dataSource = STKAudioPlayer.dataSourceFromURL(url!)
                        audioPlayer.setDataSource(dataSource, withQueueItemId: SampleQueueId(url: url, andCount: 0))
                        let musicview = self.storyboard?.instantiateViewControllerWithIdentifier("MusicView") as! MusicViewController
                        self.presentViewController(musicview, animated: true, completion: nil)
                        self.HUD.dismiss()
                    })
                })
            } else {
                if isTopHit {
                    if indexPath.row == 0 {
                        
                    } else {
                        source = 1
                        let mainView = self.parentViewController?.parentViewController as! MainViewController
                        if tophit[indexPath.row-1].artwork_url != "null" {
                            mainView.song_artwork.af_setImageWithURL(NSURL(string: tophit[indexPath.row-1].artwork_url)!)
                        } else {
                            mainView.song_artwork.image = UIImage(named: "ic_artwork")
                        }
                        
                        mainView.song_title.text = tophit[indexPath.row-1].title_song
                        mainView.userName.text = tophit[indexPath.row-1].username
                        
                        mainView.labelFirst.text = ""
                        
                        self.HUD.showInView(self.view, animated: true)
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                            currentIndex = indexPath.row-1
                            MusicHandler.configNowPlayingInfo()
                            dispatch_async(dispatch_get_main_queue(), {
                                let url = NSURL(string: tophit[indexPath.row-1].stream_url)
                                let dataSource = STKAudioPlayer.dataSourceFromURL(url!)
                                audioPlayer.setDataSource(dataSource, withQueueItemId: SampleQueueId(url: url, andCount: 0))
                                let musicview = self.storyboard?.instantiateViewControllerWithIdentifier("MusicView") as! MusicViewController
                                self.presentViewController(musicview, animated: true, completion: nil)
                                self.HUD.dismiss()
                            })
                        })
                    }
                } else {
                    
                }
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
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0,0,tableView.frame.size.width,70))
        headerView.backgroundColor = UIColor.clearColor()
        return headerView
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    @IBAction func showMenu(sender: UIButton){
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "showMenuInSearch", label: nil, value: nil)
        tracker.send(event.build() as [NSObject : AnyObject])
        let items = NSMutableArray(capacity: 3)
        var menuItem = MenuItem(title: "Like", iconName: "ic_like_color")
        items.addObject(menuItem)
        menuItem = MenuItem(title: "Add to playlist", iconName: "ic_playlist_color")
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
                let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "LikeSong", label: nil, value: nil)
                tracker.send(event.build() as [NSObject : AnyObject])
                CALayerExt.showHint("Liked this song", view: self.view!)
            }
            if selectedItem.title == "Add to playlist" {
                let tracker = GAI.sharedInstance().defaultTracker
                let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "AddSongToPlaylist", label: nil, value: nil)
                tracker.send(event.build() as [NSObject : AnyObject])
                
                let track:Track!
                if source == 0 {
                    track = tracksShow[sender.tag]
                } /* else if self.isSearch {
                    track = tracksShow[sender.tag]
                } */ else {
                    track = tophit[sender.tag - 1]
                }
                
                let a = playlist.filter(){ $0.title_song == track.title_song && $0.artwork_url == track.artwork_url }
                if a.count > 0 {
                    CALayerExt.showHint("Song already in your playlist", view: self.view)
                } else {
                    let database: COpaquePointer = Database.connectdb1("playlist", type: "sqlite")
                    let query = "INSERT INTO main.playlist (\"song_title\",\"song_artwork\",\"song_duration\",\"song_duration_f\",\"song_username\",\"song_playback_count\",\"song_stream_url\",\"song_permalink_url\") VALUES ('\(track.title_song)','\(track.artwork_url)','\(track.duration)','\(track.duration_f)','\(track.username)','\(track.playback_count)','\(track.stream_url)','\(track.permalink_url)');"
                    Database.db_query(query, database: database)
                    sqlite3_close(database)
                    playlist = UserViewController.loadPlaylist()
                    CALayerExt.showHint("Added song to playlist", view: self.view)
                }
            }
            if selectedItem.title == "Share" {
                let tracker = GAI.sharedInstance().defaultTracker
                let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "shareSong", label: nil, value: nil)
                tracker.send(event.build() as [NSObject : AnyObject])
                
                let activityViewController = UIActivityViewController(
                    activityItems: [NSURL(string: tracksShow[sender.tag].permalink_url)!],
                    applicationActivities: nil)
                self.presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
        popMenu.showMenuAtView(self.view)
    }
    
    func toString(input: AnyObject!, isTime: Bool = false ) -> String {
        if input is NSNull {
            return "null"
        }
        if input is NSNumber {
            if isTime {
                let second = (NSInteger(input as! NSNumber) / 1000)%60
                let minutes = (NSInteger(input as! NSNumber) / (1000*60))%60
                return String(format: "%d:%.2d", arguments: [minutes,second])
            }
        }
        return input as! String
    }
    
    func numToString(num: NSNumber) -> String {
        if num as Int > 1000000 {
            return String(format: "%.1fM", arguments: [(num.doubleValue)/1000000])
        }
        if num as Int > 1000 {
            return String(format: "%.1fM", arguments: [(num.doubleValue)/1000])
        }
        return num.stringValue
    }
    
    func loadTracks(input: String) -> [Track]{
        var list = [Track]()
        let SAMPLE = "http://api.soundcloud.com/users/197567455/tracks.json?client_id=\(clientid)&q="
        let query = input.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let url = SAMPLE + query!
        let data = NSData(contentsOfURL: NSURL(string: url)!)
        do {
            if data != nil {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                if let songs = json as? [[String: AnyObject]] {
                    for song in songs {
                        if let stream = song["streamable"] as? Bool {
                            if(stream){
                                var playc = ""
                                if let play = song["playback_count"] as? NSNumber {
                                    playc = numToString(play)
                                }
                                let dic = song["user"] as! NSDictionary
                                let artwork_url_tmp = self.toString(song["artwork_url"]!)
                                let artwork_url = artwork_url_tmp.stringByReplacingOccurrencesOfString("large", withString: "t500x500")
                                list.append(Track(title_song:  self.toString(song["title"]!),
                                    artwork_url: artwork_url,
                                    duration: self.toString(song["duration"], isTime: true),
                                    duration_f: song["duration"] as! NSNumber,
                                    username: dic.objectForKey("username")! as! String,
                                    playback_count: playc,
                                    stream_url: "\(self.toString(song["stream_url"]!))?client_id=\(clientid)",
                                    permalink_url: self.toString(song["permalink_url"]!)))
                            }
                        }
                    }
                }
            }
        }
        catch {
            print("error serializing JSON: \(error)")
        }
        return list
    }
    
    func loadTopHit(idgroup: String) -> [Track] {
        var list = [Track]()
        let data = NSData(contentsOfURL: NSURL(string: "http://api.soundcloud.com/groups/\(idgroup)/tracks?client_id=\(clientid)")!)
        do {
            if data != nil {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                if let songs = json as? [[String: AnyObject]] {
                    for song in songs {
                        if let stream = song["streamable"] as? Bool {
                            if(stream){
                                var playc = ""
                                if let play = song["playback_count"] as? NSNumber {
                                    playc = numToString(play)
                                }
                                let dic = song["user"] as! NSDictionary
                                let artwork_url_tmp = self.toString(song["artwork_url"]!)
                                let artwork_url = artwork_url_tmp.stringByReplacingOccurrencesOfString("large", withString: "t500x500")
                                list.append(Track(title_song:  self.toString(song["title"]!),
                                    artwork_url: artwork_url,
                                    duration: self.toString(song["duration"], isTime: true),
                                    duration_f: song["duration"] as! NSNumber,
                                    username: dic.objectForKey("username")! as! String,
                                    playback_count: playc,
                                    stream_url: "\(self.toString(song["stream_url"]!))?client_id=\(clientid)",
                                    permalink_url: self.toString(song["permalink_url"]!)))
                            }
                        }
                    }
                }
            }
        }
        catch {
            print("error serializing JSON: \(error)")
        }
        return list
    }
}

/* extension ViewController: UISearchResultsUpdating{
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if(searchController.searchBar.text != "") {
            let str = searchController.searchBar.text
            tracks.removeAll(keepCapacity: false)
            self.tableView.reloadData()
            self.indicator.hidden = false
            self.indicator.startAnimating()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                tracksShow.removeAll(keepCapacity: false)
                let list = self.loadTracks(str!)
                dispatch_async(dispatch_get_main_queue(), {
                    if str == searchController.searchBar.text && searchController.searchBar.text != "" {
                        self.tracks.removeAll(keepCapacity: false)
                        tracksShow = list
                        if tracksShow.count > 0 {
                            if tracksShow.count < 5 {
                                for var i=0; i<tracksShow.count; i++
                                {
                                    self.tracks.append(tracksShow[i])
                                }
                            } else {
                                self.tracks.append(tracksShow[0])
                                self.tracks.append(tracksShow[1])
                                self.tracks.append(tracksShow[2])
                                self.tracks.append(tracksShow[3])
                                self.tracks.append(tracksShow[4])
                            }                            
                        }
                        self.tableView.reloadData()
                        self.indicator.stopAnimating()
                    }
                })
            })
        } else {
            self.indicator.stopAnimating()
            self.tableView.reloadData()
        }
    }
} */
