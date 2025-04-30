import Testing
import MusicKit
@testable import MKMusicCrafter

@Test func playSongTest() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
 
    let authProvider = MKAuthProvider()
    let mkMusicPlayer = MKMusicPlayer(musicAuthProvider: authProvider)
    
    var searchRequest = MusicCatalogSearchRequest(term: "Psycho", types: [Song.self])
    searchRequest.limit = 1
    
    let searchResponse = try await searchRequest.response()
    
    guard let song = searchResponse.songs.first else {
        return
    }
    Task {
        do {
            print(song)
            try await mkMusicPlayer.startMusic(song: song)
            print("Playing Song Succeed")
            #expect(true)
        } catch {
            print(error)
        }
    }

}
