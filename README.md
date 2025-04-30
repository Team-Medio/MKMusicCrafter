<h1>개요</h1>
<h3>[소개]</h3>
<p>Apple의 First-Party 프레임워크인 MusicKit을 이용해 음악 검색, 재생 등 음악 관련 기능을 앱에서 구현할 수 있게 해주는 패키지입니다. Youtube, Shazam을 통해 얻은 데이터를 바탕으로 Apple Music에 검색해 도출된 결과를 바탕으로 사용자에게 음악 서비스 및 재생목록 옮기기를 제공합니다.</p>
<h3>[플로우]</h3>
<img src="https://github.com/user-attachments/assets/bcd5e7c6-5a7c-4f09-9416-147533cb1c7d" width="800" />

<p><strong>검색어/ID</strong> by Youtube/Shazam → MusicSearch → Song 객체 → 미리듣기 / 편집 → 내 음악 플레이리스트로 옮기기</p>
<h1>주요 기능</h1>
<h2>주요 데이터 모델</h2>
<h3><strong><code>Song</code></strong> | Apple Music의 노래 정보를 나타내는 모델 객체</h3>
<p><a href="https://developer.apple.com/documentation/musickit/song">https://developer.apple.com/documentation/musickit/song</a></p>
<p>이는 MusicKit에서 제공하는 Song으로 제목, 아티스트, 앨범 등 Apple Music의 음원 데이터를 캡슐화한 객체입니다. 음악 재생, 플레이리스트 생성 등 MusicKit의 주요 기능을 사용하려면 Song객체가 필요하고, 이 Song객체는 애플 뮤직 음악 검색인 CatalogSearch- 메서드의 반환값으로 얻을 수 있습니다</p>
<h3><strong><code>MKSongDurationInfo</code></strong> | 노래의 제목, 아티스트, 재생 시간을 담는 구조체</h3>
<pre><code class="language-swift">public struct MKSongDurationInfo : Sendable {
    public init(title: String, artist: String, duration: Int) {
        self.title = title
        self.artist = artist
        self.duration = duration
    }
    
    public let title: String
    public let artist: String
    public let duration: Int
}
</code></pre>
<p>Youtube에서 추출한 음악정보 중 MusicKit에 검색할 때 필요한 데이터 입니다. Youtube에서 얻은 노래 제목, 가수명, 노래 시간이 캡슐화 되어있습니다</p>
<h2>1. 음악 검색: <code>MKCatalogSearcher</code></h2>
<h3>1-1. 일반 검색 | 검색어/ID를 통해서 결과로 Song객체(또는 배열)를 찾아내는 메서드</h3>
<img src="https://github.com/user-attachments/assets/2e3454ad-9322-4a02-8496-5b90cd429131" width="800" />

<p>MusicKit에서는 검색에 관한 두가지 메서드를 제공합니다. String기반으로 검색할 수 있는 MusicCatalogSearchRequest()와, Song ID 기반으로 검색할 수 잇는 MusicCatalogResourceRequest() 가 있습니다. searchMusicTerm(searchTerm: String)메서드를 구현하여 검색어에 따른 Song 결과들을 반환할 수 있게 하였고, searchMusic(musicId: String)메서드를 구현하여 Song ID에 따른 Song 결과를 반환할 수 있게 하였습니다.</p>
<h3>1-2. 병렬 검색 | 검색어/ID를 통해서 병렬적으로 Song객체(또는 배열)를 찾아내는 메서드</h3>
<img src="https://github.com/user-attachments/assets/b82711fe-3fc9-4ae1-8831-11fcb19972bf" width="800"/>


<p>앞선 두 메서드에 병렬처리와 AsyncStream 리턴으로 변경시켜준 음악 검색 메서드입니다. 병렬 처리는 많은 수의 곡을 검색할 때 병렬로 검색하여 결과 처리 속도를 더욱 높이고자 하였으며, AsyncStream으로 리턴하는 것은 이 메서드를 호출하는 지점에서 진행률, 즉 ProgressBar에 퍼센티지를 송출하고자 처리하였습니다.</p>
<h2>2. 음악 재생 | <code>MKMusicPlayer</code></h2>
<img src="https://github.com/user-attachments/assets/a983fcff-8cd4-481e-96d6-e15aa096782c" width="800" />



<p>음악 재생은 MusicKit에서 제공하는 ApplivationMusicPlayer를 사용하면 간단하게 재생이 가능합니다. 재생은 플레이어의 queue에 Song 배열을 대입하고 play() 메서드를 실행하면 되고, 정지는 플레이어 자체에 pause() 메서드를 실행하면 노래가 정지합니다.</p>
<h2>3. 플레이리스트 내 Apple Music으로 옮기기 | <code>MKPlaylistMaker</code></h2>
<img src="https://github.com/user-attachments/assets/0ad251c2-b114-487b-ac6d-9103d6699bc7" width="800" />


<p>iOS의 경우는 MusicKit의 MusicLibrary.shared.createPlaylist로 내 음악 라이브러리로 플레이리스트 생성이 가능합니다. 하지만 MacOS의 경우는 Apple Music API에서 제시하는 Request를 별도로 생성해서 처리해야합니다.</p>
<h1>주요 포인트</h1>
<h2>[Estimate Duration을 통한 노래 검색 정확도 향상]</h2>
<p><a href="https://github.com/DeveloperAcademy-POSTECH/2024-MacC-M14-Medio/pull/107">https://github.com/DeveloperAcademy-POSTECH/2024-MacC-M14-Medio/pull/107</a></p>
<h3>1. 개선 전</h3>
<p>Youtube 영상 댓글/설명의 노래 정보들을 가져올 때 가수명과 노래제목 모두 적혀있는 케이스에서는 정확도가 높았지만, 노래 제목만 적혀있는 케이스에서는 같은 제목의 다른 노래를 가져올 수 있는 가능성이 있었습니다.</p>
<ul>
<li>
<p>예시) Youtube에서 추출한 원본 댓글과 댓글을 바탕으로(제목만 있는 댓글) 검색한 결과 : 총 51곡 중 12곡이 다른 곡 (빨간색)</p>
<pre><code class="language-swift">0:00 Guy For That (Ft. Luke Combs)
2:42 Congratulations (Ft. Quavo)
6:20 Sunflower (Ft. Swae Lee)
8:55 Wrapped Around Your Finger
12:06 Enemies (Ft. DaBaby)
15:20 I Had Some Help (feat. Morgan Wallen)
18:15 I Like You (A Happier Song) (Ft. Doja Cat)
21:25 One Right Now (Ft. The Weeknd)
24:35 Spoil my night (Ft. Swae Lee)
27:47 I'm Gonna Be
31:05 Better Now
34:52 Myself
37:29 Staring At The Sun (Ft. SZA)
40:16 Mourning
42:41 Waiting For Never
45:57 Rich &amp; Sad
49:21 Wow.
51:47 Saint Tropez
54:18 Hateful
57:14 Post Malone - Cooped Up (Ft. Roddy Ricch)
1:00:19 Stay
1:03:41 Allegic
1:06:15 Take What You Want (Ft. Ozzy Osbourne, Travis Scott)
1:10:02 Yours Truly, Austin Post
1:13:39 Go Flex
1:16:34 A Thousand Bad Times
1:20:13 Cold
1:24:39 Deja Vu (ft.Justin Bieber)
1:28:30 Post Malone - Die For Me (Ft. Future, Halsey)
1:32:32 Hollywood's Bleeding
1:35:05 I Fall Apart
1:38:46 I Know
1:41:04 Insane
1:43:52 Lemon Tree
1:47:50 Chemical
1:50:52 Post Malone - On The Road (Ft. Meek Mill &amp; Lil Baby)
1:54:27 Otherside
1:58:15 Over Now
2:02:22 Paranoid
2:06:01 Candy Paint
2:09:47 Circles
2:13:20 Enough Is Enough
2:16:02 Love/Hate Letter to Alcohol (Ft. Fleet Foxes)
2:19:03 Motley Crew
2:22:16 Novacandy
2:25:31 Overdrive
2:27:56 Pour Me A Drink (Ft. Blake Shelton)
2:31:07 Psyco (Ft. Ty Dolla $ign)
2:35:01 Rockstar (Ft. 21 Savage)
2:38:36 Something Real
2:42:01 Goodbyes (Ft. Young Thug)
</code></pre>
<pre><code class="language-swift">0. Guy For That (feat. Luke Combs) - Post Malone
1. Congratulations (feat. Quavo) - Post Malone
2. Sunflower (Spider-Man: Into the Spider-Verse) - Post Malone &amp; Swae Lee
3. Wrapped Around Your Finger - Post Malone
4. Enemies (feat. DaBaby) - Post Malone
5. I Had Some Help (feat. Morgan Wallen) - Post Malone
6. I Like You (A Happier Song) [feat. Doja Cat] - Post Malone
7. One Right Now - Post Malone &amp; The Weeknd
8. Spoil My Night (feat. Swae Lee) - Post Malone
9. I'm Gonna Be (500 Miles) - The Proclaimers
10. Better Now - Post Malone
11. Myself - Bazzi
12. Staring at the Sun (feat. SZA) - Post Malone
13. Mourning - Post Malone
14. Waiting For Never - Post Malone
15. Rich &amp; Sad - Post Malone
16. WOW - IVE
17. Saint-Tropez - Post Malone
18. Hateful - Post Malone
19. Cooped Up (feat. Roddy Ricch) - Post Malone
20. STAY - The Kid LAROI &amp; Justin Bieber
21. Allergic - Post Malone
22. Take What You Want (feat. Ozzy Osbourne &amp; Travis Scott) - Post Malone
23. Yours Truly, Austin Post - Post Malone
24. Go Flex - Post Malone
25. A Thousand Bad Times - Post Malone
26. Cold (feat. Future) - Maroon 5
27. What Do You Mean? - Justin Bieber
28. Die For Me (feat. Future &amp; Halsey) - Post Malone
29. Hollywood's Bleeding - Post Malone
30. I Fall Apart - Post Malone
31. I KNOW ? - Travis Scott
32. Insane - Black Gryph0n &amp; Baasik
33. Lemon Tree - Fool's Garden
34. Chemical - Post Malone
35. On the Road (feat. Meek Mill &amp; Lil Baby) - Post Malone
36. Otherside - Red Hot Chili Peppers
37. Over Now - Calvin Harris, The Weeknd
38. Paranoid - ASH ISLAND
39. Candy Paint - Post Malone
40. Circles - Post Malone
41. Enough Is Enough - Post Malone
42. Love/Hate Letter To Alcohol (feat. Fleet Foxes) - Post Malone
43. Motley Crew - Post Malone
44. Novacandy - Post Malone
45. Overdrive - Post Malone
46. Pour Me A Drink (feat. Blake Shelton) - Post Malone
47. Psycho (feat. Ty Dolla $ign) - Post Malone
48. rockstar (feat. 21 Savage) - Post Malone
49. Something Real - Post Malone
50. Goodbyes (feat. Young Thug) - Post Malone
</code></pre>
</li>
</ul>
<h3>2. 개선 방향</h3>
<p>노래 제목과, 가수명에 대한 데이터가 변할 수 있다는 점을 극복하기 위해, 노래의 불변값인 노래 길이(Duration)을 사용해 검색에 정확도를 높이고자 하였습니다.</p>
<ol>
<li>YTPlaylistExtractor에서 Youtube정보를 추출할 때 각 노래의 시작과 끝을 계산해 노래의 Duration 값을 같이 넘겨줍니다.</li>
<li>MKMusicCrafter에서 검색어 내부에 “가수명”이 포함되어있는지 판단을 합니다.</li>
<li>검색어에 ‘가수명’이 없으면 ‘노래 제목’만 가지고 검색한 상위 결과 노래들 중 Duration이 가장 근사값을 가진 노래를 반한하여 더 정확한 노래를 반환합니다.</li>
</ol>
<h3>3. 상세 코드</h3>
<p><strong>3-1.</strong> ArtistName이 포함되어 있지 않은 경우를 처리하기 위해 isIncludingArtist() 실행합니다</p>
<pre><code class="language-swift">let canSpecifyArtist = MKCatalogSearcher.isIncludingArtist(searchTerm: value.title,
                                                           musicTitle: song?.title ?? &quot;none&quot;,
                                                           artistName: song?.artistName ?? &quot;none&quot;)
</code></pre>
<ul>
<li>아티스트가 검색어에 있는지 확인하는 메서드</li>
</ul>
<p><code>isIncludingArtist(searchTerm: String, musicTitle: String, artistName: String) -&gt; Bool</code></p>
<ol>
<li>정규식을 이용한 특수문자 제거 메서드 실행합니다 by <code>removeSpecialCharacters()</code></li>
<li>모든 문자를 하나로 붙여서 하나의 긴 문자열로 만듭니다 by <code>normalizeWhitespace()</code></li>
<li>마지막으로 title, artist가 flat한 문자열에 포함되어 있으면 true 반환합니다</li>
</ol>
<pre><code class="language-swift">static func isIncludingArtist(searchTerm: String, musicTitle: String, artistName: String) -&gt; Bool {
    let searchTermProcessed = searchTerm.lowercased().removeSpecialCharacters().normalizeWhitespace()
    let musicTitleProcessed = musicTitle.lowercased().removeSpecialCharacters().normalizeWhitespace()
    let artistNameProcessed = artistName.lowercased().removeSpecialCharacters().normalizeWhitespace()
    
    let isMusicTitleIncluded = searchTermProcessed.contains(musicTitleProcessed)
    let isArtistNameIncluded = searchTermProcessed.contains(artistNameProcessed)
    
    if isMusicTitleIncluded &amp;&amp; isArtistNameIncluded {
        return true
    } else {
        return false
    }
}

extension String {
    func removeSpecialCharacters() -&gt; String {
        let pattern = &quot;[^a-zA-Z0-9\\\\s]&quot;
        return self.replacingOccurrences(
            of: pattern,
            with: &quot;&quot;,
            options: .regularExpression
        )
    }
    // 연속된 공백을 하나로 치환하는 함수
    func normalizeWhitespace() -&gt; String {
        return self.replacingOccurrences(
            of: &quot;\\\\s+&quot;,
            with: &quot; &quot;,
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)
    }
}
</code></pre>
<p><strong>3-2.</strong> ArtistName이 검색어에 포함되어 있는 경우는 그대로 값을 반환하지만, 그렇지 않다면 <code>findClosestDurationSong()</code> 메서드를 실행해 노래길이가 가장 가까운 노래를 반환합니다.</p>
<pre><code class="language-swift">if canSpecifyArtist || song == nil {
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
</code></pre>
<ul>
<li>가장 근사값을 가진 노래를 찾는 메서드</li>
</ul>
<p><code>findClosestDurationSong(estimateDuration: Int, searchResults: [Song]) -&gt; Song?</code></p>
<pre><code class="language-swift">// Apple Music Catalog에서 얻은 노래들의 Duration과 비교하여 가장 가까운 Duration을 가진 노래를 찾아내는 메서드
static func findClosestDurationSong(estimateDuration: Int, searchResults: [Song]) -&gt; Song? {
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
        
        let closestIndex = resultSongDuration.indices.min(by: { index1, index2 in
            abs(resultSongDuration[index1] - estimateDuration) &lt; abs(resultSongDuration[index2] - estimateDuration)
        }) ?? 0
        
        return searchResults[closestIndex]
    }
}
</code></pre>
<h3>4. 개선 결과</h3>
<p><strong>[성과]</strong></p>

총 곡수(URL) | 개선 전 | 개선 후
-- | -- | --
총 51곡 | 틀린 곡: 12곡 | 틀린 곡: 6곡
총 38곡 | 틀린 곡: 9곡 | 틀린 곡: 6곡
총 45곡 | 틀린 곡: 10곡 | 틀린 곡: 8곡


<p>Youtube영상에 가수명이 적혀있지 않은 영상에서 노래를 추출할 때 전반적인 정확도 평균적으로 40% 상승했습니다. 이는 유의미한 개선 지표로 해당 방법을 채택하는 근거가 되었습니다.</p>
<p>그 외 PR 둘러보기</p>
<hr>
<ul>
<li>withThrowingTaskGroup()을 이용한 음악 검색 병렬 처리</li>
</ul>
<p><a href="https://github.com/DeveloperAcademy-POSTECH/2024-MacC-M14-Medio/pull/97">https://github.com/DeveloperAcademy-POSTECH/2024-MacC-M14-Medio/pull/97</a></p>
<ul>
<li>AsyncStream을 반환하여 곡 검색 진행률을 포착 가능하게 만듦</li>
</ul>
<p><a href="https://github.com/DeveloperAcademy-POSTECH/2024-MacC-M14-Medio/pull/126">https://github.com/DeveloperAcademy-POSTECH/2024-MacC-M14-Medio/pull/126</a></p>
