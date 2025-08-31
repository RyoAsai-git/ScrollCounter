import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var scrollDataManager = ScrollDataManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ダッシュボード画面
            DashboardView()
                .environmentObject(scrollDataManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("ダッシュボード")
                }
                .tag(0)
            
            // グラフ画面
            ChartView()
                .environmentObject(scrollDataManager)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("履歴")
                }
                .tag(1)
            
            // 設定画面
            SettingsView()
                .environmentObject(scrollDataManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { newTab in
            // タブ切り替え時にスクロール検出をシミュレート
            let tabName = ["ダッシュボード", "履歴", "設定"][newTab]
            Task {
                await simulateScrollDetection(appName: "タブ切り替え", distance: 15.0)
            }
        }
        .onAppear {
            // アプリ起動時の初期化処理
            Task {
                await scrollDataManager.requestAccessibilityPermission()
                await notificationManager.requestNotificationPermission()
                scrollDataManager.startMonitoring()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // アプリがバックグラウンドに移行する時の処理
            scrollDataManager.saveCurrentData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // アプリがフォアグラウンドに復帰する時の処理
            Task {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
