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
                    
                    // デジタルデトックスタイマーカード
                    DigitalDetoxTimerCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("使用時間")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // データ更新
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
            // 画面表示時にデータ更新
            Task {
                await usageDataManager.refreshData()
            }
        }
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
        GeometryReader { geometry in
            ZStack {
                // 暗い背景（画面を暗くする効果）
                Color.black
                    .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: min(25, geometry.size.height * 0.04)) {
                        // 上部のスペース
                        Spacer()
                            .frame(height: max(20, geometry.safeAreaInsets.top + 20))
                        
                        // デトックスアイコン - サイズを画面に応じて調整
                        Image(systemName: "leaf.fill")
                            .font(.system(size: min(60, geometry.size.height * 0.08)))
                            .foregroundColor(.green)
                            .shadow(color: .green, radius: 8)
                        
                        // タイトル
                        Text("デジタル休憩中")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // 残り時間表示 - サイズを画面に応じて調整
                        Text(formatTime(timeRemaining))
                            .font(.system(size: min(40, geometry.size.width * 0.12), weight: .light, design: .monospaced))
                            .foregroundColor(.green)
                            .shadow(color: .green, radius: 5)
                        
                        // 休憩メッセージ
                        VStack(spacing: 12) {
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
                        .padding(.horizontal, 30)
                        
                        // 中央のスペース
                        Spacer()
                            .frame(height: min(40, geometry.size.height * 0.05))
                        
                        // 早期終了ボタン - Safe Area を考慮
                        VStack(spacing: 12) {
                            Button("休憩を終了") {
                                endRestMode()
                            }
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                            
                            Text("推奨休憩時間: \(restDuration)分")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // 下部のスペース
                        Spacer()
                            .frame(height: max(30, geometry.safeAreaInsets.bottom + 30))
                    }
                    .frame(minHeight: geometry.size.height)
                }
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

// MARK: - デジタルデトックスタイマーカード
struct DigitalDetoxTimerCard: View {
    @State private var selectedMinutes: Int = 15
    @State private var showingTimerMode = false
    @State private var isTimerActive = false
    
    let timerOptions = [5, 10, 15, 30, 45, 60]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("デジタルデトックスタイマー")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("設定した時間だけデジタルデバイスから離れて、心と体をリフレッシュしましょう。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // タイマー時間選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("休憩時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(timerOptions, id: \.self) { minutes in
                                Button(action: {
                                    selectedMinutes = minutes
                                }) {
                                    Text("\(minutes)分")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedMinutes == minutes ? .white : .green)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedMinutes == minutes ? Color.green : Color.green.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // タイマー開始ボタン
                Button(action: {
                    startDetoxTimer()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        
                        Text("\(selectedMinutes)分のデトックス開始")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isTimerActive)
                .opacity(isTimerActive ? 0.6 : 1.0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .fullScreenCover(isPresented: $showingTimerMode) {
            DetoxTimerModeView(
                duration: selectedMinutes * 60,
                isPresented: $showingTimerMode,
                onTimerComplete: {
                    isTimerActive = false
                }
            )
        }
    }
    
    private func startDetoxTimer() {
        isTimerActive = true
        showingTimerMode = true
    }
}

// MARK: - デトックスタイマーモード画面
struct DetoxTimerModeView: View {
    @State private var timeRemaining: Int
    @State private var isActive = true
    @State private var timer: Timer?
    @State private var originalBrightness: CGFloat = 0.5
    @Binding var isPresented: Bool
    
    let duration: Int // 秒単位
    let onTimerComplete: () -> Void
    
    init(duration: Int, isPresented: Binding<Bool>, onTimerComplete: @escaping () -> Void) {
        self.duration = duration
        self._timeRemaining = State(initialValue: duration)
        self._isPresented = isPresented
        self.onTimerComplete = onTimerComplete
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.3),
                        Color.mint.opacity(0.2),
                        Color.blue.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: min(30, geometry.size.height * 0.04)) {
                        // ヘッダー - サイズを画面に応じて調整
                        VStack(spacing: 12) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: min(60, geometry.size.height * 0.08)))
                                .foregroundColor(.green)
                            
                            Text("デジタルデトックス中")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("心と体をリフレッシュする時間です")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)
                        
                        // タイマー表示 - サイズを画面に応じて調整
                        VStack(spacing: 20) {
                            let circleSize = min(180, geometry.size.width * 0.45)
                            ZStack {
                                Circle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 6)
                                    .frame(width: circleSize, height: circleSize)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(duration))
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .mint]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: circleSize, height: circleSize)
                                    .animation(.linear(duration: 1), value: timeRemaining)
                                
                                VStack(spacing: 4) {
                                    Text(formatTime(timeRemaining))
                                        .font(.system(size: min(32, geometry.size.width * 0.08), weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)
                                    
                                    Text("残り時間")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 進捗情報
                            VStack(spacing: 6) {
                                Text("進捗: \(Int((1 - Double(timeRemaining) / Double(duration)) * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                
                                ProgressView(value: 1 - Double(timeRemaining) / Double(duration))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                    .frame(width: min(180, geometry.size.width * 0.45))
                            }
                        }
                        
                        // 推奨活動 - コンパクトに表示
                        VStack(alignment: .leading, spacing: 10) {
                            Text("おすすめの過ごし方")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                RecommendationItem(icon: "figure.walk", text: "散歩する")
                                RecommendationItem(icon: "book", text: "読書する")
                                RecommendationItem(icon: "leaf", text: "瞑想する")
                                RecommendationItem(icon: "cup.and.saucer", text: "お茶を飲む")
                                RecommendationItem(icon: "music.note", text: "音楽を聴く")
                                RecommendationItem(icon: "bed.double", text: "休憩する")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 制御ボタン - 画面下部に固定せず、スクロール可能領域に配置
                        HStack(spacing: 15) {
                            Button(action: {
                                pauseResumeTimer()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: isActive ? "pause.circle" : "play.circle")
                                    Text(isActive ? "一時停止" : "再開")
                                }
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                            
                            Button(action: {
                                stopTimer()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.circle")
                                    Text("終了")
                                }
                                .font(.body)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            setupTimer()
            adjustBrightness()
            disableIdleTimer()
        }
        .onDisappear {
            cleanupTimer()
            restoreBrightness()
            enableIdleTimer()
        }
    }
    
    // MARK: - タイマー制御
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isActive && timeRemaining > 0 {
                timeRemaining -= 1
                
                if timeRemaining == 0 {
                    completeTimer()
                }
            }
        }
    }
    
    private func pauseResumeTimer() {
        isActive.toggle()
    }
    
    private func stopTimer() {
        cleanupTimer()
        isPresented = false
        onTimerComplete()
    }
    
    private func completeTimer() {
        cleanupTimer()
        
        // 完了通知
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 少し待ってから画面を閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPresented = false
            onTimerComplete()
        }
    }
    
    private func cleanupTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - デバイス制御
    private func adjustBrightness() {
        originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.3 // 低い明度に設定
    }
    
    private func restoreBrightness() {
        UIScreen.main.brightness = originalBrightness
    }
    
    private func disableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func enableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: - ヘルパー関数
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - 推奨活動アイテム
struct RecommendationItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UsageDataManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
