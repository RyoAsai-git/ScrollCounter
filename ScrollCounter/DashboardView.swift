import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var usageDataManager: UsageDataManager
    @State private var showMotivationMessage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の総使用時間カード
                    TotalUsageCard()
                    
                    // 使用時間監視状況カード
                    UsageMonitoringCard()
                    
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
            .navigationTitle("使用時間")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // 使用時間更新：プルリフレッシュ時に使用時間を記録
                await simulateUsageUpdate(appName: "ダッシュボード", duration: 120.0)
                
                await usageDataManager.refreshData()
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
        .environmentObject(usageDataManager)
        .onAppear {
            // 画面表示時に使用時間更新とデータ更新
            Task {
                await simulateUsageUpdate(appName: "ダッシュボード", duration: 90.0)
                await usageDataManager.refreshData()
            }
        }
    }
    
    // MARK: - 使用時間更新シミュレーション
    private func simulateUsageUpdate(appName: String, duration: TimeInterval) async {
        print("📱 [DashboardView] 使用時間更新: \(appName) - \(Int(duration))秒")
        NotificationCenter.default.post(
            name: NSNotification.Name("UsageUpdated"),
            object: nil,
            userInfo: [
                "duration": duration,
                "appName": appName
            ]
        )
        print("📤 [DashboardView] 通知送信完了")
    }
}

// MARK: - 使用時間監視状況カード
struct UsageMonitoringCard: View {
    @EnvironmentObject var usageDataManager: UsageDataManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "touchid")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("使用時間監視状況")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Circle()
                    .fill(usageDataManager.isMonitoring ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(0.8)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("検出状態")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(usageDataManager.isMonitoring ? "監視中" : "停止中")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(usageDataManager.isMonitoring ? .green : .red)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("今日の記録")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                                            Text(usageDataManager.formatDuration(usageDataManager.todayTotalDuration))
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
                    
                    Text("\(usageDataManager.topApps.count)")
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

// MARK: - 今日の総使用時間カード
struct TotalUsageCard: View {
    @EnvironmentObject var usageDataManager: UsageDataManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("今日の総使用時間")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Text(usageDataManager.formatDuration(usageDataManager.todayTotalDuration))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .onAppear {
                        print("🖼️ [TotalUsageCard] 表示時間: \(usageDataManager.formatDuration(usageDataManager.todayTotalDuration))")
                    }
                
                Text("使用時間")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // プログレスバー（1日4時間注意ライン）
            VStack(spacing: 8) {
                HStack {
                    Text("今日の使用状況")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int((usageDataManager.todayTotalDuration / 14400) * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: min(usageDataManager.todayTotalDuration / 14400, 1.0))
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
    @EnvironmentObject var usageDataManager: UsageDataManager
    
    var motivationMessage: String {
        let duration = usageDataManager.todayTotalDuration
        let yesterdayDuration = usageDataManager.yesterdayTotalDuration
        
        if duration > yesterdayDuration && duration > 7200 { // 2時間
            let diff = duration - yesterdayDuration
            return "⚠️ 昨日より\(usageDataManager.formatDurationShort(diff))多く使用中...休憩時間を増やしませんか？"
        } else if duration >= 14400 { // 4時間
            return "🚨 使用時間が4時間に...デジタル疲労が心配です"
        } else if duration >= 10800 { // 3時間
            return "⏰ 3時間の使用...30分の休憩をお勧めします"
        } else if duration >= 7200 { // 2時間
            return "💭 2時間も画面を見続けています...目を休めませんか？"
        } else if duration >= 3600 { // 1時間
            return "📱 1時間の使用...適度な休憩を心がけましょう"
        } else if duration >= 1800 { // 30分
            return "👀 30分の使用...瞬きを忘れずに"
        } else if duration >= 900 { // 15分
            return "😌 15分の使用...まだ健康的な範囲です"
        } else if duration >= 300 { // 5分
            return "👍 適度な使用時間をキープしています"
        } else {
            return "✨ 今日は控えめな使用...素晴らしい自制心です！"
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
    @EnvironmentObject var usageDataManager: UsageDataManager
    @State private var showAllTime = false
    
    var currentApps: [AppUsageData] {
        showAllTime ? usageDataManager.allTimeTopApps : usageDataManager.topApps
    }
    
    var rankingTitle: String {
        showAllTime ? "歴代ランキング" : "今日のランキング"
    }
    
    var periodText: String {
        if showAllTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "ja_JP")
            let startDate = formatter.string(from: usageDataManager.appStartDate)
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
                    
                    Text("アプリを使用してデータを蓄積しましょう！")
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
                                                            distance: app.duration,
                                topAppDistance: currentApps.first?.duration ?? 1,
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
                
                Text("\(UsageDataManager.formatDuration(distance)) 使用\(isAllTime ? " (累計)" : "")")
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
    @EnvironmentObject var usageDataManager: UsageDataManager
    @State private var showingRestMode = false
    
    var conversionText: String {
        let duration = usageDataManager.todayTotalDuration
        
        if duration >= 28800 { // 8時間
            return "⚠️ 8時間も画面を見続けています...深刻なデジタル疲労の危険性"
        } else if duration >= 21600 { // 6時間
            return "😰 6時間の使用時間...目と首の健康が心配です"
        } else if duration >= 18000 { // 5時間
            return "📱💦 5時間も画面に集中...デジタルデトックスが必要かも"
        } else if duration >= 14400 { // 4時間
            return "🚇😵 4時間の連続使用...外の景色を見ませんか？"
        } else if duration >= 10800 { // 3時間
            return "⏰ 3時間の使用時間...散歩で気分転換はいかがですか？"
        } else if duration >= 7200 { // 2時間
            return "🚶‍♀️ 2時間の画面時間...リアルな活動も大切です"
        } else if duration >= 5400 { // 1.5時間
            return "⛵ 1.5時間の使用...目を休めて遠くを見ましょう"
        } else if duration >= 3600 { // 1時間
            return "🏃‍♂️ 1時間の使用時間...適度な休憩を取りましょう"
        } else if duration >= 2700 { // 45分
            return "📱🤔 45分の使用...まだ健康的な範囲内です"
        } else if duration >= 1800 { // 30分
            return "🏃‍♂️ 30分の使用...良いペースを保っています"
        } else if duration >= 1200 { // 20分
            return "🏢 20分の使用時間...首のストレッチを忘れずに"
        } else if duration >= 900 { // 15分
            return "🏃‍♂️ 15分の使用...立ち上がって体を動かしましょう"
        } else if duration >= 600 { // 10分
            return "🗼 10分の使用...瞬きを意識してください"
        } else if duration >= 300 { // 5分
            return "🏊‍♂️ 5分の使用...健康的な利用です"
        } else if duration >= 180 { // 3分
            return "⚽ 3分の使用...外の緑も見てくださいね"
        } else if duration >= 60 { // 1分
            return "🏃‍♂️ 1分の使用...まだ適度な範囲です"
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
        .fullScreenCover(isPresented: $showingRestMode) {
            DigitalRestModeView(
                restDuration: getRecommendedRestDuration(),
                isPresented: $showingRestMode
            )
        }
    }
    
        private func startDigitalDetox() {
        let duration = usageDataManager.todayTotalDuration
        var detoxMessage = ""
        var recommendedDuration = 5 // デフォルト5分
        
        if duration >= 14400 { // 4時間
            detoxMessage = "⚠️ 今日の使用時間が4時間を超えています。\n30分間の本格的な休憩で目と体を回復させましょう。"
            recommendedDuration = 30
        } else if duration >= 7200 { // 2時間
            detoxMessage = "⏰ 今日の使用時間を見直し、20分間画面から離れませんか？\n🌿 散歩、読書、瞑想などをお試しください。"
            recommendedDuration = 20
        } else if duration >= 3600 { // 1時間
            detoxMessage = "📱 適度な休憩を取りましょう！\n👀 10分間の休憩で20-20-20ルールを実践してみませんか？"
            recommendedDuration = 10
        } else {
            detoxMessage = "😊 良いペースです！5分間の軽い休憩で、この調子をキープしましょう。"
            recommendedDuration = 5
        }
        
        let alert = UIAlertController(
            title: "デジタルデトックスのお誘い",
            message: detoxMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "\(recommendedDuration)分休憩する", style: .default) { _ in
            showingRestMode = true
        })
        
        alert.addAction(UIAlertAction(title: "後で", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // 推奨休憩時間を取得
    private func getRecommendedRestDuration() -> Int {
        let duration = usageDataManager.todayTotalDuration
        
        if duration >= 14400 { // 4時間
            return 30
        } else if duration >= 7200 { // 2時間
            return 20
        } else if duration >= 3600 { // 1時間
            return 10
        } else {
            return 5
        }
    }
}

// MARK: - デジタル休憩モード画面
struct DigitalRestModeView: View {
    @State private var timeRemaining: Int
    @State private var isActive = true
    @State private var timer: Timer?
    @State private var originalBrightness: CGFloat = 0.5
    @Binding var isPresented: Bool
    
    let restDuration: Int // 分単位
    
    init(restDuration: Int, isPresented: Binding<Bool>) {
        self.restDuration = restDuration
        self._timeRemaining = State(initialValue: restDuration * 60) // 秒に変換
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // 暗い背景（画面を暗くする効果）
            Color.black
                .ignoresSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                // デトックスアイコン
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 10)
                
                // タイトル
                Text("デジタル休憩中")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // 残り時間表示
                Text(formatTime(timeRemaining))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 5)
                
                // 休憩メッセージ
                VStack(spacing: 15) {
                    Text("目を休めて、深呼吸をしましょう")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("👀 遠くを見つめる\n🧘‍♀️ 軽いストレッチ\n💧 水分補給")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 早期終了ボタン
                VStack(spacing: 15) {
                    Button("休憩を終了") {
                        endRestMode()
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    
                    Text("推奨休憩時間: \(restDuration)分")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startRestMode()
        }
        .onDisappear {
            restoreBrightness()
            timer?.invalidate()
        }
        .preferredColorScheme(.dark) // ダークモード強制
    }
    
    // MARK: - 休憩モード開始
    private func startRestMode() {
        // 現在の明度を保存
        originalBrightness = UIScreen.main.brightness
        
        // 画面を暗くする
        UIScreen.main.brightness = 0.1
        
        // タイマー開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // 時間終了
                endRestMode()
            }
        }
        
        // 画面をアクティブに保つ（スリープ防止）
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // MARK: - 休憩モード終了
    private func endRestMode() {
        timer?.invalidate()
        restoreBrightness()
        UIApplication.shared.isIdleTimerDisabled = false
        
        // デトックス完了メッセージ
        if timeRemaining <= 0 {
            // 完了通知を表示（実装可能）
            showCompletionMessage()
        }
        
        isPresented = false
    }
    
    // MARK: - 明度復元
    private func restoreBrightness() {
        // 元の明度に戻す（少し遅延を入れて自然に）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIScreen.main.brightness = originalBrightness
        }
    }
    
    // MARK: - 時間フォーマット
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - 完了メッセージ
    private func showCompletionMessage() {
        let alert = UIAlertController(
            title: "休憩完了！🎉",
            message: "お疲れさまでした。\n引き続き健康的なデジタルライフを心がけましょう。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UsageDataManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
