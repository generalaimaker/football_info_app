import Foundation

@MainActor
class FixtureDetailViewModel: ObservableObject {
    @Published var events: [FixtureEvent] = []
    @Published var statistics: [TeamStatistics] = []
    @Published var lineups: [TeamLineup] = []
    @Published var topPlayers: [PlayerStats] = []
    @Published var matchPlayerStats: [TeamPlayersStatistics] = []
    @Published var headToHeadFixtures: [Fixture] = []
    @Published var team1Stats: HeadToHeadStats?
    @Published var team2Stats: HeadToHeadStats?
    
    @Published var selectedStatisticType: StatisticType?
    @Published var selectedTeamId: Int?
    @Published var selectedPlayerId: Int?
    
    @Published var isLoadingEvents = false
    @Published var isLoadingStats = false
    @Published var isLoadingLineups = false
    @Published var isLoadingPlayers = false
    @Published var isLoadingMatchStats = false
    @Published var isLoadingHeadToHead = false
    
    @Published var errorMessage: String?
    
    private let service = FootballAPIService.shared
    private let fixtureId: Int
    private let season: Int
    private var currentFixture: Fixture?
    
    init(fixture: Fixture) {
        self.fixtureId = fixture.fixture.id
        self.season = fixture.league.season
        self.currentFixture = fixture
    }
    
    func loadAllData() {
        Task {
            // 먼저 매치 플레이어 통계를 로드
            await loadMatchPlayerStats()
            
            // 상대전적 로드 (매치 플레이어 통계에 의존)
            await loadHeadToHead()
            
            // 나머지 데이터를 병렬로 로드
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadEvents() }
                group.addTask { await self.loadStatistics() }
                group.addTask { await self.loadLineups() }
            }
        }
    }
    
    // MARK: - Events
    
    func loadEvents() async {
        isLoadingEvents = true
        errorMessage = nil
        
        do {
            var allEvents = try await service.getFixtureEvents(
                fixtureId: fixtureId,
                teamId: selectedTeamId,
                playerId: selectedPlayerId
            )
            
            // 이벤트 정렬 및 필터링
            allEvents.sort { event1, event2 in
                if event1.time.elapsed == event2.time.elapsed {
                    // 같은 시간대의 이벤트는 중요도 순으로 정렬
                    return getEventPriority(event1) > getEventPriority(event2)
                }
                return event1.time.elapsed < event2.time.elapsed
            }
            
            events = allEvents
        } catch {
            errorMessage = "이벤트 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("Load Events Error: \(error)")
        }
        
        isLoadingEvents = false
    }
    
    private func getEventPriority(_ event: FixtureEvent) -> Int {
        switch event.eventCategory {
        case .goal: return 5
        case .var: return 4
        case .card: return 3
        case .substitution: return 2
        case .other: return 1
        }
    }
    
    // MARK: - Statistics
    
    func loadStatistics() async {
        isLoadingStats = true
        errorMessage = nil
        
        do {
            var fetchedStats = try await service.getFixtureStatistics(
                fixtureId: fixtureId,
                teamId: selectedTeamId,
                type: selectedStatisticType
            )
            
            // 통계 데이터 정렬 및 필터링
            if !fetchedStats.isEmpty {
                fetchedStats = fetchedStats.map { teamStats in
                    var stats = teamStats
                    let sortedStatistics = stats.statistics.sorted { stat1, stat2 in
                        getStatisticPriority(stat1.type) > getStatisticPriority(stat2.type)
                    }
                    stats.statistics = sortedStatistics
                    return stats
                }
            }
            
            statistics = fetchedStats
        } catch {
            errorMessage = "통계 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("Load Statistics Error: \(error)")
        }
        
        isLoadingStats = false
    }
    
    private func getStatisticPriority(_ type: String) -> Int {
        switch type {
        case StatisticType.ballPossession.rawValue: return 10
        case StatisticType.shotsOnGoal.rawValue: return 9
        case StatisticType.totalShots.rawValue: return 8
        case StatisticType.saves.rawValue: return 7
        case StatisticType.cornerKicks.rawValue: return 6
        case StatisticType.fouls.rawValue: return 5
        case StatisticType.yellowCards.rawValue, StatisticType.redCards.rawValue: return 4
        case StatisticType.offsides.rawValue: return 3
        case StatisticType.passesAccurate.rawValue: return 2
        default: return 1
        }
    }
    
    // MARK: - Match Player Statistics
    
    func loadMatchPlayerStats() async {
        isLoadingMatchStats = true
        errorMessage = nil
        
        print("📊 Loading match player stats for fixture: \(fixtureId)")
        
        do {
            let stats = try await service.getFixturePlayersStatistics(fixtureId: fixtureId)
            print("📊 Loaded match player stats: \(stats.count) teams")
            
            if stats.isEmpty {
                errorMessage = "선수 통계 정보가 없습니다."
                print("⚠️ No match player stats found")
            } else if stats.count < 2 {
                errorMessage = "양 팀의 선수 통계 정보가 필요합니다."
                print("⚠️ Insufficient team stats: only \(stats.count) team(s)")
            } else {
                print("✅ Team 1: \(stats[0].team.name), Team 2: \(stats[1].team.name)")
            }
            
            matchPlayerStats = stats
            
        } catch {
            errorMessage = "선수 통계 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("❌ Load Match Player Stats Error: \(error)")
        }
        
        isLoadingMatchStats = false
    }
    
    // MARK: - Lineups
    
    func loadLineups() async {
        isLoadingLineups = true
        errorMessage = nil
        
        do {
            lineups = try await service.getFixtureLineups(
                fixtureId: fixtureId,
                teamId: selectedTeamId
            )
            
            // 선발 선수들의 통계 정보 로드
            if !lineups.isEmpty {
                await loadTopPlayersStats()
            }
        } catch {
            errorMessage = "라인업 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("Load Lineups Error: \(error)")
        }
        
        isLoadingLineups = false
    }
    
    // MARK: - Head to Head
    
    func loadHeadToHead() async {
        isLoadingHeadToHead = true
        errorMessage = nil
        
        print("🔄 Loading head to head stats...")
        
        // 매치 선수 통계에서 팀 ID 가져오기
        if matchPlayerStats.isEmpty {
            do {
                matchPlayerStats = try await service.getFixturePlayersStatistics(fixtureId: fixtureId)
                print("📊 Loaded match player stats: \(matchPlayerStats.count) teams")
            } catch {
                errorMessage = "매치 선수 통계를 불러올 수 없습니다: \(error.localizedDescription)"
                print("❌ Failed to load match player stats: \(error)")
                isLoadingHeadToHead = false
                return
            }
        }
        
        // 팀 정보 확인
        guard matchPlayerStats.count >= 2 else {
            errorMessage = "양 팀의 선수 통계가 필요합니다."
            print("❌ Insufficient team stats: only \(matchPlayerStats.count) team(s)")
            isLoadingHeadToHead = false
            return
        }
        
        let team1Id = matchPlayerStats[0].team.id
        let team2Id = matchPlayerStats[1].team.id
        
        print("🆚 Loading head to head for teams: \(team1Id)(\(matchPlayerStats[0].team.name)) vs \(team2Id)(\(matchPlayerStats[1].team.name))")
        
        do {
            // 두 팀의 과거 상대 전적 가져오기
            headToHeadFixtures = try await service.getHeadToHead(team1Id: team1Id, team2Id: team2Id)
            
            if headToHeadFixtures.isEmpty {
                errorMessage = "상대전적 정보가 없습니다."
                print("⚠️ No head to head fixtures found")
                isLoadingHeadToHead = false
                return
            }
            
            print("📊 Loaded \(headToHeadFixtures.count) head to head fixtures")
            
            // 각 팀의 상대 전적 통계 계산
            team1Stats = HeadToHeadStats(fixtures: headToHeadFixtures, teamId: team1Id)
            team2Stats = HeadToHeadStats(fixtures: headToHeadFixtures, teamId: team2Id)
            
            print("✅ Head to head stats calculated successfully")
            
        } catch {
            errorMessage = "상대 전적을 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("❌ Load Head to Head Error: \(error)")
        }
        
        isLoadingHeadToHead = false
    }

    private func loadTopPlayersStats() async {
        isLoadingPlayers = true
        errorMessage = nil
        
        do {
            // 경기의 모든 선수 통계 가져오기
            let matchStats = try await service.getFixturePlayersStatistics(fixtureId: fixtureId)
            
            // 선발 선수 ID 목록
            let starterIds = Set(lineups.flatMap { lineup in
                lineup.startXI.map { $0.id }
            })
            
            print("📊 Processing match stats for \(starterIds.count) starters")
            
            // 모든 선수의 통계를 처리
            var processedStats: [PlayerStats] = []
            
            for teamStats in matchStats {
                for player in teamStats.players {
                    // 선수가 경기에 참여했는지 확인
                    guard let matchStat = player.statistics.first,
                          let position = matchStat.games.position else {
                        continue
                    }
                    
                    // 기본 평점 설정 (참여한 선수는 최소 5.0)
                    let rating = matchStat.games.rating ?? "5.0"
                    
                    // PlayerMatchStats를 PlayerSeasonStats로 변환
                    let seasonStats = [PlayerSeasonStats(
                        team: teamStats.team,
                        league: PlayerLeagueInfo(
                            id: 0,
                            name: "Current Match",
                            country: nil,
                            logo: "",
                            season: self.season
                        ),
                        games: PlayerGames(
                            appearences: 1,
                            lineups: matchStat.games.minutes ?? 0 > 0 ? 1 : 0,
                            minutes: matchStat.games.minutes ?? 0,
                            number: matchStat.games.number,
                            position: position,
                            rating: rating,
                            captain: matchStat.games.captain
                        ),
                        shots: matchStat.shots ?? PlayerShots(total: 0, on: 0),
                        goals: matchStat.goals ?? PlayerGoals(total: 0, conceded: 0, assists: 0, saves: 0),
                        passes: matchStat.passes ?? PlayerPasses(total: 0, key: 0, accuracy: "0"),
                        tackles: matchStat.tackles ?? PlayerTackles(total: 0, blocks: 0, interceptions: 0),
                        duels: matchStat.duels ?? PlayerDuels(total: 0, won: 0),
                        dribbles: matchStat.dribbles ?? PlayerDribbles(attempts: 0, success: 0, past: 0),
                        fouls: matchStat.fouls ?? PlayerFouls(drawn: 0, committed: 0),
                        cards: matchStat.cards ?? PlayerCards(yellow: 0, yellowred: 0, red: 0),
                        penalty: nil
                    )]
                    
                    processedStats.append(PlayerStats(
                        player: player.player,
                        statistics: seasonStats
                    ))
                    print("✅ Processed stats for \(player.player.name)")
                }
            }
            
            // 평점 기준으로 정렬
            topPlayers = processedStats.sorted { player1, player2 in
                let rating1 = Double(player1.statistics.first?.games.rating ?? "0") ?? 0
                let rating2 = Double(player2.statistics.first?.games.rating ?? "0") ?? 0
                return rating1 > rating2
            }
            
            print("📊 Total players processed: \(topPlayers.count)")
            
        } catch {
            errorMessage = "선수 통계 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("❌ Load Top Players Stats Error: \(error)")
        }
        
        isLoadingPlayers = false
    }
    
    // MARK: - Filter Methods
    
    func filterByTeam(_ teamId: Int?) {
        selectedTeamId = teamId
        Task {
            await loadEvents()
            await loadStatistics()
            if teamId != nil {
                await loadLineups()
            }
        }
    }
    
    func filterByPlayer(_ playerId: Int?) {
        selectedPlayerId = playerId
        Task {
            await loadEvents()
        }
    }
    
    func filterByStatisticType(_ type: StatisticType?) {
        selectedStatisticType = type
        Task {
            await loadStatistics()
        }
    }
    
}

// MARK: - Helpers
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}