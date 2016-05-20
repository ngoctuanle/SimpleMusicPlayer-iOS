//
//  MusicHandler.swift
//  MusicDemo
//
//  Created by Tuan Le on 2/1/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import Foundation
import MediaPlayer

class MusicHandler {
    static func configNowPlayingInfo() {
        if NSClassFromString("MPNowPlayingInfoCenter") != nil {
            let track1:Track!
            if source == 0 {
                track1 = tracksShow[currentIndex]
            } else if source == 1 {
                track1 = tophit[currentIndex]
            } else {
                track1 = playlist[currentIndex]
            }
            
            let image: UIImage!
            if track1.artwork_url != "null" {
                let data = NSData(contentsOfURL: NSURL(string: track1.artwork_url)!)
                if data != nil {
                    image = UIImage.af_threadSafeImageWithData(data!)
                } else {
                    image = UIImage(named: "ic_artwork")
                }
                
            } else {
                image = UIImage(named: "ic_artwork")
            }
            
            let songInfo: [String: AnyObject]? = [
                
                MPMediaItemPropertyTitle: track1.title_song,
                
                MPMediaItemPropertyArtist: track1.username,
                
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image),
                
                MPNowPlayingInfoPropertyElapsedPlaybackTime: audioPlayer.progress,
                
                MPMediaItemPropertyPlaybackDuration: Int(track1.duration_f) / 1000,
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        }
    }
}