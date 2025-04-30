//
//  File.swift
//  MKMusicCrafter
//
//  Created by Greem on 11/18/24.
//

import Foundation

extension URLRequest {
    init(
        developerToken: String,
        userToken: String,
        playlistCreationRequest: LibraryPlaylistCreationRequest) throws {
        let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists")!
        self.init(url: url)
        self.httpMethod = "POST"
        self.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        self.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        self.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.httpBody = try JSONEncoder().encode(playlistCreationRequest)
    }
}
