//
//  LibraryPlaylistCreationRequest.swift
//  MKMusicCrafter
//
//  Created by Greem on 11/18/24.
//

import Foundation
import MusicKit
struct LibraryPlaylistCreationRequest:Codable {
    var attributes: Attributes
    var relationships: Relationships
    struct Attributes: Codable {
        let name: String
        let description: String
    }
    struct Relationships: Codable {
        var tracks: Tracks
        
        struct Tracks: Codable {
            var data: [Data]
            struct Data: Codable {
                let id: String
                let type: String
            }
        }
    }
    init(name: String, description: String, songs: [Song]){
        self.attributes = .init(name: name, description: description)
        let datas:[Relationships.Tracks.Data] = songs.map{ .init(id: $0.id.rawValue, type: "songs") }
        self.relationships = Relationships(tracks: .init(data: datas))
    }
}
