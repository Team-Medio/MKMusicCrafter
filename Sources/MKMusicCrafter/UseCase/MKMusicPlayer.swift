//
//  File.swift
//  MKMusicCrafter
//
//  Created by TEO on 10/24/24.
//

import MusicKit



public class MKMusicPlayer {
    
    private let musicAuthProvider: MKAuthProvider
    
    public init(musicAuthProvider: MKAuthProvider) {
        self.musicAuthProvider = musicAuthProvider
    }
    
    private let musicPlayer = ApplicationMusicPlayer.shared

    
    
    public func startMusic(song: Song) async throws {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        var songChanged: Bool = false
        
        if status {
            if musicPlayer.queue.entries.isEmpty || musicPlayer.queue.entries.first?.title ?? "" != song.title {
                // 큐의 엔트리에 값이 없거나, 이전 곡/이후 곡이 다르다면
                // 큐에 새로운 노래를 셋팅하고, 곡이 변헸다는 사실을 참으로 설정한다
                musicPlayer.queue = [song]
                songChanged = true
            }
            do {
                if !musicPlayer.isPreparedToPlay {
                    try await musicPlayer.prepareToPlay()
                }
                if !songChanged {
                    // 곡이 바뀌지 않았으면 멈춘 지점부터 재생
                    try await musicPlayer.play()
                } else {
                    // 곡이 바뀌었으면 처음+60초 부터 재생
                    try await musicPlayer.play()
                    musicPlayer.playbackTime = 60
                }
            } catch {
                print("musicPlayer.play()을 실행할 수 없습니다: \(error)")
                throw error
            }
        } else {
            print("startMusic()을 위해 Apple Music 구독이 필요합니다")
        }
    }
    
    
    public func stopMusic() async throws {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        
        if status {
            musicPlayer.pause()
        } else {
            print("stopMusic()을 위해 Apple Music 구독이 필요합니다")
        }
    }
    
    
}
