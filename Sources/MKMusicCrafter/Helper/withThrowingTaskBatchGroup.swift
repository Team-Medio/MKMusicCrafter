//
//  withThrowingTaskBatchGroup.swift
//  MKMusicCrafter
//
//  Created by Greem on 11/4/24.
//

import Foundation

/// 배치 사이즈: 한번에 실행할 병렬 Task를 지정합니다
/// stopSeconds: 병렬 Task가 모두 실행 후 일시정지 할 시간을 명시합니다.
func withThrowingTaskBatchGroup<T: Sendable, U:Sendable>(datas:[T],
                                                     batchSize: Int = 15,
                                                     stopSeconds: Int = 1,
                                                     action: @escaping @Sendable (Int, T) async -> (U?)) async throws ->  [U?] {
    
    typealias ResultTypeWithIndex = (index: Int, result: U?)
    
    var results: [ResultTypeWithIndex] = []
    
    for batchStart in stride(from: 0, to: datas.count, by: batchSize) {
        let batchEnd = min(batchStart + batchSize, datas.count)
        let currentBatch = Array(datas[batchStart..<batchEnd])
        
        let allBatchResults: [ResultTypeWithIndex] = try await withThrowingTaskGroup(of: ResultTypeWithIndex.self) { group in
            for (localIndex, value) in currentBatch.enumerated() {
                let globalIndex = batchStart + localIndex
                group.addTask { @Sendable in // Swift6 부터 해당 작업이 외부 캡쳐링에 대한 Sendable을 지킨다는 것을 명시해야합니다.
                    let song: U? = await action(globalIndex, value)
                    return (globalIndex, song)
                }
            }
            var batchResults: [ResultTypeWithIndex] = []
            
            for try await res in group { batchResults.append(res) }
            
            return batchResults.sorted { $0.index < $1.index }
        }
        results.append(contentsOf: allBatchResults)
        
        // 마지막 배치가 아니면 stopSeconds초 대기
        if batchEnd < datas.count { try await Task.sleep(for: .seconds(stopSeconds)) }
    }
    return results.map(\.result)
}
