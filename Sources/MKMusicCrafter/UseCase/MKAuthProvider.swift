//
//  MKAuthProvider.swift
//  MKMusicCrafter
//
//  Created by TEO on 10/9/24.
//

import MusicKit

public final class MKAuthProvider: Sendable {
    
    public init() {}
    
    
    // 사용자의 Apple Music 라이브러리, 재생 정보 등에 접근할 수 있는 권한을 요청하는 메서드
    public func updateAuthorizationStatus() async -> MusicAuthorization.Status {
        return await MusicAuthorization.request()
    }
    
    // 사용자의 Apple Music 구독 상태를 확인하는 메서드
    public func updateSubscriptionStatus() async throws -> Bool {
        let subscription = try await MusicSubscription.current
        return subscription.canPlayCatalogContent
    }
}
