import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    @State private var showMotivationMessage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日のスクロール距離カード
                    TotalDistanceCard()
                    
                    // スクロール検出状況カード
                    ScrollDetectionStatusCard()
                    
                    // モチベーションメッセージ
                    if showMotivationMessage {
                        MotivationCard()
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                    
                    // アプリ別ランキング
                    AppRankingCard()
                    
                    // ネタ換算カード
                    HumorConversionCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("スクロール距離")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // スクロール検出：プルリフレッシュ時にスクロール距離を記録
                await simulateScrollDetection(appName: "ダッシュボード", distance: 50.0)
                
                await scrollDataManager.refreshData()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showMotivationMessage = true
                }
                
                // 3秒後にメッセージを非表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showMotivationMessage = false
                    }
                }
            }
        }
        .environmentObject(scrollDataManager)
        .onAppear {
            // 画面表示時にスクロール検出とデータ更新
            Task {
                await simulateScrollDetection(appName: "ダッシュボード", distance: 30.0)
                await scrollDataManager.refreshData()
            }
        }
    }
    
    // MARK: - スクロール検出シミュレーション
    private func simulateScrollDetection(appName: String, distance: Double) async {
        print("📱 [DashboardView] スクロール検出: \(appName) - \(distance)m")
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollDetected"),
            object: nil,
            userInfo: [
                "distance": distance,
                "appName": appName
            ]
        )
        print("📤 [DashboardView] 通知送信完了")
    }
}

// MARK: - スクロール検出状況カード
struct ScrollDetectionStatusCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "touchid")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("スクロール検出状況")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Circle()
                    .fill(scrollDataManager.isMonitoring ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(0.8)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("検出状態")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(scrollDataManager.isMonitoring ? "監視中" : "停止中")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(scrollDataManager.isMonitoring ? .green : .red)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("今日の記録")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(scrollDataManager.todayTotalDistance))m")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("アプリ数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(scrollDataManager.topApps.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - 今日の総スクロール距離カード
struct TotalDistanceCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("今日のスクロール距離")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Text(formatDistance(scrollDataManager.todayTotalDistance))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .onAppear {
                        print("🖼️ [TotalDistanceCard] 表示距離: \(scrollDataManager.todayTotalDistance)m")
                    }
                
                Text("メートル")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // プログレスバー（1日10km目標）
            VStack(spacing: 8) {
                HStack {
                    Text("今日の進捗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int((scrollDataManager.todayTotalDistance / 10000) * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: min(scrollDataManager.todayTotalDistance / 10000, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }
}

// MARK: - モチベーションカード
struct MotivationCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    
    var motivationMessage: String {
        let distance = scrollDataManager.todayTotalDistance
        let yesterdayDistance = scrollDataManager.yesterdayTotalDistance
        
        if distance > yesterdayDistance && distance > 1000 {
            return "🎉 今日も絶好調！昨日より\(Int(distance - yesterdayDistance))m多くスクロールしています"
        } else if distance >= 10000 {
            return "🏃‍♂️ 今日は10km突破！陸上競技場25周レベルです"
        } else if distance >= 5000 {
            return "💪 今日も5km突破！5kmランニング完走レベルです"
        } else if distance >= 3000 {
            return "🚶‍♀️ 今日は3km到達！40分散歩と同じ距離です"
        } else if distance >= 1609 {
            return "🏃‍♂️ 1マイル(1.609km)ランニング達成！"
        } else if distance >= 1000 {
            return "📱 スクロールチェッカーマスターに近づいています"
        } else if distance >= 400 {
            return "🏃‍♂️ 陸上競技場1周(400m)レベル到達！"
        } else if distance >= 100 {
            return "💪 陸上100m走レベルクリア！"
        } else {
            return "📱 今日のスクロール活動、開始です！"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("モチベーション")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(motivationMessage)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
}

// MARK: - アプリ別ランキングカード
struct AppRankingCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    @State private var showAllTime = false
    
    var currentApps: [AppScrollData] {
        showAllTime ? scrollDataManager.allTimeTopApps : scrollDataManager.topApps
    }
    
    var rankingTitle: String {
        showAllTime ? "歴代ランキング" : "今日のランキング"
    }
    
    var periodText: String {
        if showAllTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "ja_JP")
            let startDate = formatter.string(from: scrollDataManager.appStartDate)
            let today = formatter.string(from: Date())
            return "\(startDate) ～ \(today)"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: Date())
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: showAllTime ? "crown.fill" : "list.number")
                        .font(.title2)
                        .foregroundColor(showAllTime ? .yellow : .orange)
                    
                    Text(rankingTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllTime.toggle()
                        }
                    }) {
                        Text(showAllTime ? "今日" : "歴代")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                HStack {
                    Text("計測期間: \(periodText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            if currentApps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text(showAllTime ? "まだ歴代データがありません" : "まだ今日のデータがありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("アプリを使ってスクロールしてみましょう！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(currentApps.enumerated()), id: \.offset) { index, app in
                        AppRankingRow(
                            rank: index + 1, 
                            appName: app.name, 
                            distance: app.distance,
                            topAppDistance: currentApps.first?.distance ?? 1,
                            isAllTime: showAllTime
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - アプリランキング行
struct AppRankingRow: View {
    let rank: Int
    let appName: String
    let distance: Double
    let topAppDistance: Double
    let isAllTime: Bool
    
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)位"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(rankEmoji)
                .font(.title3)
                .frame(width: 40, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(formatDistance(distance)) スクロール\(isAllTime ? " (累計)" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // プログレスバー
            ProgressView(value: distance / (topAppDistance))
                .progressViewStyle(LinearProgressViewStyle(tint: rankColor))
                .frame(width: 60)
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        if isAllTime {
            switch rank {
            case 1: return .yellow
            case 2: return .gray
            case 3: return .orange
            default: return .purple
            }
        } else {
            switch rank {
            case 1: return .yellow
            case 2: return .gray
            case 3: return .orange
            default: return .blue
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }
}

// MARK: - ネタ換算カード
struct HumorConversionCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    
    var conversionText: String {
        let distance = scrollDataManager.todayTotalDistance
        
        if distance >= 42195 {
            return "🏃‍♂️ フルマラソン(42.195km)完走と同じ距離をスクロール！"
        } else if distance >= 21098 {
            return "🏃‍♀️ ハーフマラソン(21.098km)完走と同じ距離をスクロール！"
        } else if distance >= 10000 {
            return "🏃‍♂️ 陸上競技場25周(10km)と同じ距離をスクロール！"
        } else if distance >= 7000 {
            return "🚇 東京駅から渋谷駅(7km)と同じ距離をスクロール！"
        } else if distance >= 5000 {
            return "🏃‍♂️ 5kmランニングと同じ距離をスクロール！"
        } else if distance >= 3000 {
            return "🚶‍♀️ 徒歩約40分(3km)の散歩と同じ距離をスクロール！"
        } else if distance >= 1852 {
            return "⛵ 1海里(1.852km)の航海と同じ距離をスクロール！"
        } else if distance >= 1609 {
            return "🏃‍♂️ 1マイル(1.609km)ランニングと同じ距離をスクロール！"
        } else if distance >= 1000 {
            return "🚶‍♀️ 1kmウォーキングと同じ距離をスクロール！"
        } else if distance >= 800 {
            return "🏃‍♂️ 陸上競技場2周(800m)と同じ距離をスクロール！"
        } else if distance >= 634 {
            return "🏢 東京スカイツリー(634m)の高さ分をスクロール！"
        } else if distance >= 400 {
            return "🏃‍♂️ 陸上競技場1周(400m)と同じ距離をスクロール！"
        } else if distance >= 333 {
            return "🗼 東京タワー(333m)の高さ分をスクロール！"
        } else if distance >= 200 {
            return "🏊‍♂️ 25mプール8往復(200m)と同じ距離をスクロール！"
        } else if distance >= 110 {
            return "⚽ サッカーコート(110m)1面分をスクロール！"
        } else if distance >= 100 {
            return "🏃‍♂️ 陸上100m走と同じ距離をスクロール！"
        } else if distance >= 50 {
            return "🏊‍♂️ 25mプール1往復(50m)と同じ距離をスクロール！"
        } else if distance >= 25 {
            return "🏊‍♂️ 25mプール1本分をスクロール！"
        } else {
            return "🏠 家の中を歩き回った距離をスクロール！"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("今日のスクロール換算")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(conversionText)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                Button("SNSでシェア") {
                    shareToSNS()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
    
    private func shareToSNS() {
        let distance = scrollDataManager.todayTotalDistance
        let text = "今日は\(Int(distance))mスクロールしました！\(conversionText) #スクロールチェッカー #デジタルデトックス"
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(ScrollDataManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
