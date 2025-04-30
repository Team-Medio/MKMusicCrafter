//
//  MusicCatalogHelper.swift
//  MKMusicCrafter
//
//  Created by TEO on 10/8/24.
//

import MusicKit
import Foundation


public enum MKPlaylistError: Error {
    case missingToken
}

@available(iOS 16.0, *)
public class MKPlaylistMaker {
    
    private let musicAuthProvider: MKAuthProvider
    private let developerTokenProvider:DefaultMusicTokenProvider?
    private let userTokenProvider: MusicUserTokenProvider?
    public init(musicAuthProvider: MKAuthProvider) {
        self.musicAuthProvider = musicAuthProvider
        #if os(macOS)
            self.developerTokenProvider = DefaultMusicTokenProvider()
            self.userTokenProvider = MusicUserTokenProvider()
        #endif
        if ProcessInfo.processInfo.isiOSAppOnMac {
            self.developerTokenProvider = DefaultMusicTokenProvider()
            self.userTokenProvider = MusicUserTokenProvider()
        } else {
            self.developerTokenProvider = nil
            self.userTokenProvider = nil
        }
    }
    
    // 사용자의 Apple Music Library에 플레이리스트를 생성하는 메서드
    public func createPlaylist(playlistName: String, playlistDescription: String, authorDisplayName: String, songs: [Song]) async throws {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        
        if status {
            do {
#if os(macOS)
                try await createPlaylistWithRESTAPI(
                    playlistName: playlistName,
                    playlistDescription: playlistDescription,
                    authorDisplayName: authorDisplayName,
                    songs: songs
                )

#else
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    try await createPlaylistWithRESTAPI(
                        playlistName: playlistName,
                        playlistDescription: playlistDescription,
                        authorDisplayName: authorDisplayName,
                        songs: songs
                    )
                } else {
                    try await createPlaylistWithAppleMusicAPI(
                        playlistName: playlistName,
                        playlistDescription: playlistDescription,
                        authorDisplayName: authorDisplayName,
                        songs: songs
                    )
                }
#endif
            } catch {
                print("Failed to create playlist: \(error)")
                throw error
            }
        } else {
            print("Please sign in to Apple Music.")
        }
    }

    private func createPlaylistWithRESTAPI(
        playlistName: String,
        playlistDescription: String,
        authorDisplayName: String,
        songs: [Song]
    ) async throws {
        guard let developerToken = try await developerTokenProvider?.developerToken(options: .ignoreCache),
              let userToken = try await userTokenProvider?.userToken(for: developerToken, options: .ignoreCache) else {
            throw MKPlaylistError.missingToken
        }
        let libraryPlaylistCreationRequest = LibraryPlaylistCreationRequest(
            name: playlistName,
            description: playlistDescription,
            songs: songs
        )
        let request = try URLRequest(developerToken: developerToken,
                                     userToken: userToken,
                                     playlistCreationRequest: libraryPlaylistCreationRequest)
        let (data, res) = try await URLSession.shared.data(for: request)
    }
    private func createPlaylistWithAppleMusicAPI(
        playlistName: String,
        playlistDescription: String,
        authorDisplayName: String,
        songs: [Song]
    ) async throws {
        let newPlaylist = try await MusicLibrary.shared.createPlaylist(
            name: playlistName,
            description: playlistDescription,
            authorDisplayName: authorDisplayName,
            items: songs
        )
    }
}

