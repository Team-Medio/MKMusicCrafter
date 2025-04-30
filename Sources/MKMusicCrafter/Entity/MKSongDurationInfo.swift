//
//  File.swift
//  MKMusicCrafter
//
//  Created by TEO on 11/3/24.
//

import Foundation

public struct MKSongDurationInfo : Sendable {
    public init(title: String, artist: String, duration: Int) {
        self.title = title
        self.artist = artist
        self.duration = duration
    }
    
    public let title: String
    public let artist: String
    public let duration: Int
}
