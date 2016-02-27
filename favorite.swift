//
//  favorite.swift
//  新加坡中文电台
//
//  Created by Jiang Nan Qing on 19/2/16.
//  Copyright © 2016 CodeMarket.io. All rights reserved.
//

import Foundation

class favoriteSongs: NSObject {
    var favoriteTracks = [String]()
    static let sharedInstance = favoriteSongs()
    override init() {
        super.init()
        DataManager.getSongsFromFileWithSuccess() { songs in
            self.favoriteTracks = songs
        }
    }
    
    func addOneSong(aTrack:Track) {
        let aSong = aTrack.title + ","+aTrack.artist + "," + aTrack.artworkURL
        if !self.favoriteTracks.contains(aSong){
            self.favoriteTracks.append(aSong)
            DataManager.saveFavoriteSongToFile(self.favoriteTracks)
        }
    }
    
    func clearAllSongs() {
        self.favoriteTracks=[]
        DataManager.saveFavoriteSongToFile(self.favoriteTracks)
    }
    
    func showAllSongs() {
        DataManager.getSongsFromFileWithSuccess() { songs in
            for oneSong in songs {
                print (oneSong)
            }
        }
    }
    
    func checkSongExist(aTrack:Track) -> Bool {
        let aSong = aTrack.title + "," + aTrack.artist + "," + aTrack.artworkURL
        return self.favoriteTracks.contains(aSong)
    }
    
    func allSongsInText() -> String {
        var allSongText = ""
        for aSong in self.favoriteTracks {
            if aSong != ""{
                let title = aSong.componentsSeparatedByString(",")[0]
                let artist = aSong.componentsSeparatedByString(",")[1]
                let songInfo = title + ":" + artist
                allSongText = allSongText + "\n" + songInfo
            }
        }
        return allSongText
    }
    
    func saveAllSongs() {
        DataManager.saveFavoriteSongToFile(self.favoriteTracks)
    }
}