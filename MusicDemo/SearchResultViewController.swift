//
//  SearchResultViewController.swift
//  MusicDemo
//
//  Created by Tuan Le on 3/20/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit
import JGProgressHUD

class SearchResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var str = ""
    var tracks = [Track]()
    var isSearchFinish = false
    
    var HUD: JGProgressHUD!
    var visualEffectView: UIVisualEffectView = UIVisualEffectView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(white: 0.9, alpha: 0.5)
        tableView.backgroundColor = UIColor(white: 0.9, alpha: 0.0)
        
        if !visualEffectView.isDescendantOfView(self.backgroundView) {
            let blurEffect: UIVisualEffect!
            blurEffect = UIBlurEffect(style: .Light)
            visualEffectView = UIVisualEffectView(effect: blurEffect)
            visualEffectView.frame = self.view.bounds
            self.backgroundView.addSubview(visualEffectView)
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.indicator.hidden = false
        self.indicator.hidesWhenStopped = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        tracks.removeAll(keepCapacity: false)
        self.tableView.reloadData()
        HUD = JGProgressHUD()
        HUD.textLabel.text = "Connecting"
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "SearchResultView")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.parentViewController?.sySearchInputBar.inputTextField.endEditing(true)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchFinish && str != "" && tracks.count > 0 {
            return tracks.count + 1
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isSearchFinish && str != "" {
            if indexPath.row != tracks.count {
                return 50
            } else {
                return 44
            }
        } else {
            return 44
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isSearchFinish && str != "" {
            let track: Track
            if indexPath.row != tracks.count {
                track = tracks[indexPath.row]
                let cell = tableView.dequeueReusableCellWithIdentifier("cellSearch", forIndexPath: indexPath) as! SearchResultTableViewCell
                if track.artwork_url != "null" {
                    cell.art_work.af_setImageWithURL(NSURL(string: track.artwork_url)!)
                } else {
                    cell.art_work.image = UIImage(named: "ic_artwork")
                }
                cell.songTitle.text = track.title_song
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("cellAll", forIndexPath: indexPath) as UITableViewCell
                cell.textLabel?.text = "View all result for '\(str)'"
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("cellAll", forIndexPath: indexPath) as UITableViewCell
            cell.textLabel?.text = "View all result for '\(str)'"
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.row != tracks.count {
            source = 0
            let mainView = self.parentViewController?.parentViewController?.parentViewController as! MainViewController
            mainView.song_title.text = tracks[indexPath.row].title_song
            mainView.song_title.text = tracks[indexPath.row].username
            mainView.labelFirst.text = ""
            if tracks[indexPath.row].artwork_url != "null" {
                mainView.song_artwork.af_setImageWithURL(NSURL(string: tracks[indexPath.row].artwork_url)!)
            } else {
                mainView.song_artwork.image = UIImage(named: "ic_artwork")
            }
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
                    (self.parentViewController as! ViewController).isShowTrack = true
                    (self.parentViewController as! ViewController).tableView.reloadData()
                    (self.parentViewController)?.sySearchInputBar.inputTextField.text = nil
                    (self.parentViewController)?.sySearchInputBar.cancelAction(self)
                })
            })
        } else {
            tophit.removeAll(keepCapacity: false)
            (self.parentViewController as! ViewController).isShowTrack = true
            (self.parentViewController as! ViewController).tableView.reloadData()
            (self.parentViewController)?.sySearchInputBar.inputTextField.text = nil
            (self.parentViewController)?.sySearchInputBar.cancelAction(self)
        }
        
        //(self.parentViewController)?.sySearchInputBar.inputTextField.text = nil
        //(self.parentViewController)?.sySearchInputBar.cancelAction(self)
    }
}
