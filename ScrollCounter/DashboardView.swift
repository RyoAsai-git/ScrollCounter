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
                    
                    // デジタルデトックス促進カード
                    DigitalDetoxCard()
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
        
        if distance > yesterdayDistance && distance > 2000 {
            return "⚠️ 昨日より\(Int(distance - yesterdayDistance))m多くスクロール中...休憩時間を増やしませんか？"
        } else if distance >= 10000 {
            return "🚨 スクロール量が10kmに...デジタル疲労が心配です"
        } else if distance >= 5000 {
            return "⏰ 5km分のスクロール...30分の休憩をお勧めします"
        } else if distance >= 3000 {
            return "💭 3km分も画面を見続けています...目を休めませんか？"
        } else if distance >= 1609 {
            return "📱 1マイル分のスクロール...適度な休憩を心がけましょう"
        } else if distance >= 1000 {
            return "👀 1km分のスクロール...瞬きを忘れずに"
        } else if distance >= 400 {
            return "😌 400m分のスクロール...まだ健康的な範囲です"
        } else if distance >= 100 {
            return "👍 適度なスクロール量をキープしています"
        } else {
            return "✨ 今日は控えめなスクロール...素晴らしい自制心です！"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundColor(.green)
                Text("健康アドバイス")
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

// MARK: - デジタルデトックス促進カード
struct DigitalDetoxCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    
    var conversionText: String {
        let distance = scrollDataManager.todayTotalDistance
        
        if distance >= 42195 {
            return "⚠️ フルマラソン分もスクロール...指の疲労が心配です"
        } else if distance >= 21098 {
            return "😰 ハーフマラソン分のスクロール...休憩しませんか？"
        } else if distance >= 10000 {
            return "📱💦 10kmも親指で移動...デジタル疲労に注意"
        } else if distance >= 7000 {
            return "🚇😵 東京駅〜渋谷駅分も画面を見続けました"
        } else if distance >= 5000 {
            return "⏰ 5km分のスクロール...外の散歩はいかがですか？"
        } else if distance >= 3000 {
            return "🚶‍♀️ リアル散歩(3km)より画面を見ています"
        } else if distance >= 1852 {
            return "⛵ 1海里分のスクロール...目を休めましょう"
        } else if distance >= 1609 {
            return "🏃‍♂️ 1マイル分...実際に走った方が健康的かも"
        } else if distance >= 1000 {
            return "📱🤔 1km分のスクロール...ちょっと多くないですか？"
        } else if distance >= 800 {
            return "🏃‍♂️ 競技場2周分...実際の運動も忘れずに"
        } else if distance >= 634 {
            return "🏢 スカイツリー分の縦スクロール...首は大丈夫？"
        } else if distance >= 400 {
            return "🏃‍♂️ 競技場1周分...立ち上がってストレッチを"
        } else if distance >= 333 {
            return "🗼 東京タワー分...目の高さを変えて休憩を"
        } else if distance >= 200 {
            return "🏊‍♂️ プール8往復分...瞬きを忘れていませんか？"
        } else if distance >= 110 {
            return "⚽ サッカーコート分...外の緑を見ませんか？"
        } else if distance >= 100 {
            return "🏃‍♂️ 100m分のスクロール...まだ適度な範囲です"
        } else if distance >= 50 {
            return "🏊‍♂️ プール往復分...良いペースですね"
        } else if distance >= 25 {
            return "😊 適度なスクロール量です"
        } else {
            return "✨ 今日はまだ控えめ...良い習慣です！"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("デジタル使用状況")
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
                Button("デトックス開始") {
                    startDigitalDetox()
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
    
    private func startDigitalDetox() {
        let distance = scrollDataManager.todayTotalDistance
        var detoxMessage = ""
        
        if distance >= 5000 {
            detoxMessage = "⏰ 今日のスクロール量を見直し、30分間デバイスから離れませんか？\n🌿 散歩、読書、瞑想などをお試しください。"
        } else if distance >= 1000 {
            detoxMessage = "📱 適度な休憩を取りましょう！\n👀 20-20-20ルール：20分ごとに20秒間、20フィート先を見る"
        } else {
            detoxMessage = "😊 良いペースです！この調子でバランスの取れたデジタルライフを続けましょう。"
        }
        
        let alert = UIAlertController(
            title: "デジタルデトックスのお誘い",
            message: detoxMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "休憩する", style: .default) { _ in
            // デトックスタイマー開始（実装可能）
        })
        
        alert.addAction(UIAlertAction(title: "後で", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
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
