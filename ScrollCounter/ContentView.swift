import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var usageDataManager = UsageDataManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ダッシュボード画面
            DashboardView()
                .environmentObject(usageDataManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("ダッシュボード")
                }
                .tag(0)
            
            // グラフ画面
            ChartView()
                .environmentObject(usageDataManager)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("履歴")
                }
                .tag(1)
            
            // 設定画面
            SettingsView()
                .environmentObject(usageDataManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { _, newValue in
            // タブ切り替え時にスクロール検出をシミュレート
            let tabName = ["ダッシュボード", "履歴", "設定"][newValue]
            Task {
                await simulateScrollDetection(appName: "タブ切り替え", distance: 15.0)
            }
        }
        .onAppear {
            // アプリ起動時の初期化処理
            Task {
                await usageDataManager.requestAccessibilityPermission()
                await notificationManager.requestNotificationPermission()
                usageDataManager.startMonitoring()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // アプリがバックグラウンドに移行する時の処理
            usageDataManager.saveCurrentData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // アプリがフォアグラウンドに復帰する時の処理
            Task {
                await usageDataManager.refreshData()
            }
        }
    }
    
    // MARK: - スクロール検出シミュレーション
    private func simulateScrollDetection(appName: String, distance: Double) async {
        print("🏠 [ContentView] スクロール検出: \(appName) - \(distance)m")
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollDetected"),
            object: nil,
            userInfo: [
                "distance": distance,
                "appName": appName
            ]
        )
        print("📤 [ContentView] 通知送信完了")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
