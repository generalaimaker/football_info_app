import SwiftUI

struct AttackingStatsView: View {
    let statistics: [TeamStatistics]
    
    private var homeStats: [String: StatisticValue] {
        guard !statistics.isEmpty else { return [:] }
        let stats = statistics[0].statistics
        return Dictionary(uniqueKeysWithValues: stats.map { ($0.type, $0.value) })
    }
    
    private var awayStats: [String: StatisticValue] {
        guard statistics.count > 1 else { return [:] }
        let stats = statistics[1].statistics
        return Dictionary(uniqueKeysWithValues: stats.map { ($0.type, $0.value) })
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 팀 로고
            HStack {
                AsyncImage(url: URL(string: statistics[0].team.logo)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } placeholder: {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("vs")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                AsyncImage(url: URL(string: statistics[1].team.logo)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } placeholder: {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 40)
            
            // 슈팅 통계
            VStack(spacing: 16) {
                // 전체 슈팅
                if let homeTotalShots = homeStats["Total Shots"],
                   let awayTotalShots = awayStats["Total Shots"] {
                    StatisticItem(
                        title: "전체 슛",
                        leftValue: homeTotalShots.displayValue,
                        rightValue: awayTotalShots.displayValue
                    )
                }
                
                // 유효 슈팅
                if let homeShotsOnTarget = homeStats["Shots on Goal"],
                   let awayShotsOnTarget = awayStats["Shots on Goal"] {
                    StatisticItem(
                        title: "유효 슈팅",
                        leftValue: homeShotsOnTarget.displayValue,
                        rightValue: awayShotsOnTarget.displayValue
                    )
                }
                
                // 빗나간 슈팅
                if let homeShotsOffTarget = homeStats["Shots off Goal"],
                   let awayShotsOffTarget = awayStats["Shots off Goal"] {
                    StatisticItem(
                        title: "빗나간 슈팅",
                        leftValue: homeShotsOffTarget.displayValue,
                        rightValue: awayShotsOffTarget.displayValue
                    )
                }
                
                // 막힌 슈팅
                if let homeShotsBlocked = homeStats["Blocked Shots"],
                   let awayShotsBlocked = awayStats["Blocked Shots"] {
                    StatisticItem(
                        title: "막힌 슛",
                        leftValue: homeShotsBlocked.displayValue,
                        rightValue: awayShotsBlocked.displayValue
                    )
                }
                
                // 골대 맞은 슈팅
                if let homeShotsInsideBox = homeStats["Shots insidebox"],
                   let awayShotsInsideBox = awayStats["Shots insidebox"] {
                    StatisticItem(
                        title: "박스 안 슈팅",
                        leftValue: homeShotsInsideBox.displayValue,
                        rightValue: awayShotsInsideBox.displayValue
                    )
                }
                
                // 박스 바깥 슈팅
                if let homeShotsOutsideBox = homeStats["Shots outsidebox"],
                   let awayShotsOutsideBox = awayStats["Shots outsidebox"] {
                    StatisticItem(
                        title: "박스 바깥 슈팅",
                        leftValue: homeShotsOutsideBox.displayValue,
                        rightValue: awayShotsOutsideBox.displayValue
                    )
                }
                
                // 예상 득점
                if let homeXG = homeStats["expected_goals"],
                   let awayXG = awayStats["expected_goals"] {
                    StatisticItem(
                        title: "예상 득점 (xG)",
                        leftValue: homeXG.displayValue,
                        rightValue: awayXG.displayValue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
}

struct StatisticItem: View {
    let title: String
    let leftValue: String
    let rightValue: String
    
    var body: some View {
        HStack {
            Text(leftValue)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(title)
                .font(.system(.body))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            Text(rightValue)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
