import SwiftUI

struct PassingStatsView: View {
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
        VStack(spacing: 16) {
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
            
            VStack(spacing: 24) {
                // 총 패스
                if let homeTotalPasses = Int(homeStats["Total passes"]?.displayValue ?? "0"),
                   let awayTotalPasses = Int(awayStats["Total passes"]?.displayValue ?? "0") {
                    StatisticItem(
                        title: "총 패스",
                        leftValue: "\(homeTotalPasses)",
                        rightValue: "\(awayTotalPasses)",
                        showProgressBar: true,
                        showPercentage: true
                    )
                }
                
                // 패스 정확도
                if let homePassAccuracy = homeStats["Passes %"]?.displayValue,
                   let awayPassAccuracy = awayStats["Passes %"]?.displayValue {
                    StatisticItem(
                        title: "패스 정확도",
                        leftValue: homePassAccuracy,
                        rightValue: awayPassAccuracy,
                        showProgressBar: true,
                        showPercentage: false // 이미 % 포함되어 있음
                    )
                }
                
                // 크로스
                if let homeCrosses = homeStats["Crosses total"],
                   let awayCrosses = awayStats["Crosses total"] {
                    StatisticItem(
                        title: "크로스",
                        leftValue: homeCrosses.displayValue,
                        rightValue: awayCrosses.displayValue,
                        showProgressBar: true,
                        showPercentage: true
                    )
                }
                
                // 긴 패스
                if let homeLongBalls = homeStats["Long Balls Accurate"],
                   let awayLongBalls = awayStats["Long Balls Accurate"] {
                    StatisticItem(
                        title: "긴 패스",
                        leftValue: homeLongBalls.displayValue,
                        rightValue: awayLongBalls.displayValue,
                        showProgressBar: true,
                        showPercentage: true
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
}
