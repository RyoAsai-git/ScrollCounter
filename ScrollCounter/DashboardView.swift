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
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollDetected"),
            object: nil,
            userInfo: [
                "distance": distance,
                "appName": appName
            ]
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
        
        if distance > yesterdayDistance {
            return "🎉 今日も絶好調！昨日より\(Int(distance - yesterdayDistance))m多くスクロールしています"
        } else if distance > 5000 {
            return "💪 今日も5km突破！指の筋トレが順調です"
        } else if distance > 1000 {
            return "👑 スクロール王の称号に近づいています"
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("アプリ別ランキング")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if scrollDataManager.topApps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("まだデータがありません")
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
                    ForEach(Array(scrollDataManager.topApps.enumerated()), id: \.offset) { index, app in
                        AppRankingRow(
                            rank: index + 1, 
                            appName: app.name, 
                            distance: app.distance,
                            topAppDistance: scrollDataManager.topApps.first?.distance ?? 1
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
                
                Text("\(Int(distance))m スクロール")
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
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

// MARK: - ネタ換算カード
struct HumorConversionCard: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    
    var conversionText: String {
        let distance = scrollDataManager.todayTotalDistance
        
        if distance >= 10000 {
            return "🚄 東京→大阪の新幹線と同じ距離をスクロール！"
        } else if distance >= 5000 {
            return "🏃‍♂️ 5kmマラソンと同じ距離をスクロール！"
        } else if distance >= 1000 {
            return "🚶‍♀️ 東京駅から渋谷駅までの距離をスクロール！"
        } else if distance >= 500 {
            return "🏢 東京スカイツリーを約1往復分スクロール！"
        } else if distance >= 100 {
            return "⚽ サッカーコート1面分をスクロール！"
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
        let text = "今日は\(Int(distance))mスクロールしました！\(conversionText) #スクロール王 #デジタルデトックス"
        
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
