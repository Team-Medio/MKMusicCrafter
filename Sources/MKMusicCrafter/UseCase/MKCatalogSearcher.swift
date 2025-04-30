//
//  MusicCatalogHelper.swift
//  MKMusicCrafter
//
//  Created by TEO on 10/8/24.
//

import MusicKit
import Foundation

// MusicCatalog에서 Song정보 검색 및 반환을 담당하는 클래스
@available(iOS 15.0, *)
public final class MKCatalogSearcher: Sendable {
    
    private let musicAuthProvider: MKAuthProvider

    public init(musicAuthProvider: MKAuthProvider) {
        self.musicAuthProvider = musicAuthProvider
    }
    
    /// MusicTerm을 통해서 결과로 Song을 찾아내는 함수
    public func searchMusicTerm(searchTerm: String, pageSize: Int = 10, currentOffset: Int) async throws -> [Song] {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        
        if status {
            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = pageSize
            searchRequest.offset = currentOffset
            
            do {
                let searchResponse = try await searchRequest.response()
                return searchResponse.songs.map { $0 }
            } catch {
                throw error
            }
        } else {
            print("Please Check your MusicKit Authorization Status")
            return []
        }
    }
    
    
    /// MusicTerm을 통해서 결과로 Song을 찾아내는 함수
    public func searchMusicTerm(searchTerm: String) async throws -> Song? {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        
        if status {
            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = 1
            
            let searchResponse = try await searchRequest.response()
            
            guard let song = searchResponse.songs.first else {
                print("노래를 찾지 못했습니다.")
                return nil
            }
            return song
        } else {
            print("Please Check your MusicKit Authorization Status")
            return nil
        }
    }
    
    
    /// MusicDataArray를 통해서 결과로 [Song?]을  찾아내는 함수
    public func searchMusicDataArray(resultData: [MKSongDurationInfo]) async throws -> [Song?] {
        let before = Date.now
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        let batchSize: Int = 15
        
        guard status else {
            print("Please Check your MusicKit Authorization Status")
            return []
        }
        var allSongs: [(index: Int, song: Song?)] = []
        
        for batchStart in stride(from: 0, to: resultData.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, resultData.count)
            let currentBatch = Array(resultData[batchStart..<batchEnd])

            let resultSongs = try await processBatchByTerm(currentBatch: currentBatch, batchStart: batchStart)
            allSongs.append(contentsOf: resultSongs)
            
            if batchEnd < resultData.count {
                try await Task.sleep(for: .seconds(1))
            }
        }
        let songArray = allSongs.map { $0.song }
        let after = Date.now
        print("Diff Time: ", after.timeIntervalSince1970 - before.timeIntervalSince1970)
        return songArray
    }


    /// MusicDataArray를 통해서 결과로 AsyncThrowingStream<Song?, Error>을  찾아내는 함수
    public func searchMusicDataArrayStream(resultData: [MKSongDurationInfo]) async throws -> AsyncThrowingStream<Song?, Error> {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        guard status else {
            print("Please Check your MusicKit Authorization Status")
            return AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for batchStart in stride(from: 0, to: resultData.count, by: 15) {
                        let batchEnd = min(batchStart + 15, resultData.count)
                        let currentBatch = Array(resultData[batchStart..<batchEnd])
                        
                        let batchResults = try await processBatchByTerm(currentBatch: currentBatch, batchStart: batchStart)
                        
                        for result in batchResults {
                            continuation.yield(result.song)
                        }
                        
                        if batchEnd < resultData.count {
                            try await Task.sleep(for: .seconds(1))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Batch 단위로 병렬처리를 목적으로 모듈화된 함수 (searchMusicDataArray, searchMusicDataArrayStream 함수 내부에서 사용)
    public func processBatchByTerm(currentBatch: [MKSongDurationInfo], batchStart: Int) async throws -> [(index: Int, song: Song?)] {
        let allBatchResults = try await withThrowingTaskGroup(of: (index: Int, song: Song?).self) { group in
            for (localIndex, value) in currentBatch.enumerated() {
                let globalIndex = batchStart + localIndex
                group.addTask {
                    do {
                        var searchRequest = MusicCatalogSearchRequest(term: value.title + " " + value.artist, types: [Song.self])
                        searchRequest.limit = 5
                        let searchResponse = try await searchRequest.response()
                        let song = searchResponse.songs.first
                        // ArtistName이 포함되어 있지 않은 경우를 처리하기 위해 isIncludingArtist() 실행
                        let canSpecifyArtist = MKCatalogSearcher.isIncludingArtist(searchTerm: value.title,
                                                                                   musicTitle: song?.title ?? "none",
                                                                                   artistName: song?.artistName ?? "none")
                        // True: .video 케이스 , False: .official 케이스
                        if value.artist == "" {
                            return (globalIndex, song)
                        } else {
                            if canSpecifyArtist && song != nil {
                                return (globalIndex, song)
                            } else {
                                var tempSongArray: [Song] = []
                                for i in searchResponse.songs {
                                    tempSongArray.append(i)
                                }
                                let result = MKCatalogSearcher.findClosestDurationSong(estimateDuration: value.duration,
                                                                                       searchResults: tempSongArray)
                                return (globalIndex, result)
                            }
                        }
                            
                    } catch {
                        print("Error searching for '\(value.duration)' and '\(value.title)': \(error)")
                        return (globalIndex, nil)
                    }
                }
            }
            var batchResults: [(index: Int, song: Song?)] = []
            for try await result in group {
                batchResults.append(result)
            }
            return batchResults.sorted { $0.index < $1.index }
        }
        return allBatchResults
    }

}


// MusicId로 Apple Music Catalog에서 Song? 및 [Song?] 을 찾는 Case의 메서드
extension MKCatalogSearcher {
    
    /// MusicId를 통해서 결과로 Song을 찾아내는 함수
    public func searchMusic(musicId: String) async throws -> Song? {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        
        if status {
            var resourceRequest = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(rawValue: musicId))
            let resourceResponse = try await resourceRequest.response()
            
            guard let song = resourceResponse.items.first else {
                print("노래를 찾지 못했습니다.")
                return nil
            }
            return song
        } else {
            print("Please Check your MusicKit Authorization Status")
            return nil
        }
    }
    
    /// MusicIdArray를 통해서 결과로 [Song?]을  찾아내는 함수
    public func searchMusicArray(musicIdArray: [String]) async throws -> [Song?] {
        let before = Date.now
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        let batchSize: Int = 15
        
        guard status else {
            print("Please Check your MusicKit Authorization Status")
            return []
        }
        
        var allSongs: [(index: Int, song: Song?)] = []
        
        for batchStart in stride(from: 0, to: musicIdArray.count, by: batchSize) {
            let batchEnd = min(batchStart+batchSize, musicIdArray.count)
            let currentBatch = Array(musicIdArray[batchStart..<batchEnd])
            
            let resultSongs = try await processBatchById(currentBatch: currentBatch, batchStart: batchStart)
            allSongs.append(contentsOf: resultSongs)
            
            // 마지막 배치가 아니면 1초 대기
            if batchEnd < musicIdArray.count {
                try await Task.sleep(for: .seconds(1))
            }
        }
        let songArray = allSongs.map { $0.song }
        
        let after = Date.now
        print("Diff Time: ", after.timeIntervalSince1970 - before.timeIntervalSince1970)
        
        return songArray
    }
    
    /// MusicIdArray를 통해서 결과로 AsyncThrowingStream<Song?, Error>을  찾아내는 함수
    public func searchMusicDataArrayStream(musicIdArray: [String]) async throws -> AsyncThrowingStream<Song?, Error> {
        let status = try await musicAuthProvider.updateSubscriptionStatus()
        guard status else {
            print("Please Check your MusicKit Authorization Status")
            return AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for batchStart in stride(from: 0, to: musicIdArray.count, by: 15) {
                        let batchEnd = min(batchStart + 15, musicIdArray.count)
                        let currentBatch = Array(musicIdArray[batchStart..<batchEnd])
                        
                        let batchResults = try await processBatchById(currentBatch: currentBatch, batchStart: batchStart)
                        
                        for result in batchResults {
                            continuation.yield(result.song)
                        }
                        
                        if batchEnd < musicIdArray.count {
                            try await Task.sleep(for: .seconds(1))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Batch 단위로 병렬처리를 목적으로 모듈화된 함수 (searchMusicArray  함수 내부에서 사용)
    public func processBatchById(currentBatch: [String], batchStart: Int) async throws -> [(index: Int, song: Song?)] {
        let allBatchResults = try await withThrowingTaskGroup(of: (index: Int, song: Song?).self) { group in
            for (localIndex, musicId) in currentBatch.enumerated() {
                let globalIndex = batchStart + localIndex
                group.addTask {
                    do {
                        var searchRequest = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(rawValue: musicId))
                        let resourceResponse = try await searchRequest.response()
                        let song = resourceResponse.items.first
                        
                        return (globalIndex, song)
                    } catch {
                        print("Error searching for song with ID \(musicId): \(error)")
                        return (globalIndex, nil)
                    }
                }
            }
            var batchResults: [(index: Int, song: Song?)] = []
            for try await result in group {
                batchResults.append(result)
            }
            return batchResults.sorted { $0.index < $1.index }
        }
        return allBatchResults
    }
}



extension MKCatalogSearcher {
    
    // Youtube에서 가져온 SearchTerm이 "노래 제목"과 "아티스트" 모두 포함하고 있는지 체크하는 메서드
    static func isIncludingArtist(searchTerm: String, musicTitle: String, artistName: String) -> Bool {
        // 모든 문자열을 전처리: 소문자 변환, 특수문자 제거, 공백 정규화
        let searchTermProcessed = searchTerm.lowercased().removeSpecialCharacters().normalizeWhitespace()
        let musicTitleProcessed = musicTitle.lowercased().removeSpecialCharacters().normalizeWhitespace()
        let artistNameProcessed = artistName.lowercased().removeSpecialCharacters().normalizeWhitespace()
        
        let isMusicTitleIncluded = searchTermProcessed.contains(musicTitleProcessed)
        let isArtistNameIncluded = searchTermProcessed.contains(artistNameProcessed)
        
        if isMusicTitleIncluded && isArtistNameIncluded {
            return true
        } else {
            return false
        }
    }
    
    
    // Apple Music Catalog에서 얻은 노래들의 Duration과 비교하여 가장 가까운 Duration을 가진 노래를 찾아내는 메서드
    static func findClosestDurationSong(estimateDuration: Int, searchResults: [Song]) -> Song? {
        var resultSongDuration: [Int] = []
        
        if searchResults.count == 0 {
            return nil
        } else if searchResults.count == 1 {
            return searchResults[0]
        } else {
            for (index, value) in searchResults.enumerated() {
                let preDuration = value.duration
                resultSongDuration.append(Int(preDuration ?? 0.0))
            }
            
            // 가장 가까운 값의 인덱스 찾기
            let closestIndex = resultSongDuration.indices.min(by: { index1, index2 in
                abs(resultSongDuration[index1] - estimateDuration) < abs(resultSongDuration[index2] - estimateDuration)
            }) ?? 0
            
            return searchResults[closestIndex]
        }
    }
    
}



extension String {
    
    // 특수문자를 제거하는 확장 함수
    func removeSpecialCharacters() -> String {
        // 유지할 문자들: 알파벳, 숫자, 공백
        let pattern = "[^a-zA-Z0-9\\s]"
        return self.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
    }
    
    // 연속된 공백을 하나로 치환하는 함수
    func normalizeWhitespace() -> String {
        return self.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)
    }
}
