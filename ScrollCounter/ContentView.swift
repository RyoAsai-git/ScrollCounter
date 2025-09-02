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
            // タブ切り替え時に使用時間更新をシミュレート
            let tabName = ["ダッシュボード", "履歴", "設定"][newValue]
            Task {
                await simulateUsageUpdate(appName: "タブ切り替え", duration: 30.0)
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
    
    // MARK: - 使用時間更新シミュレーション
    private func simulateUsageUpdate(appName: String, duration: TimeInterval) async {
        print("🏠 [ContentView] 使用時間更新: \(appName) - \(Int(duration))秒")
        NotificationCenter.default.post(
            name: NSNotification.Name("UsageUpdated"),
            object: nil,
            userInfo: [
                "duration": duration,
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
