import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var usageDataManager: UsageDataManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAccessibilityAlert = false
    @State private var showingNotificationAlert = false
    @State private var showMotivationMessages = true
    
    var body: some View {
        NavigationView {
            List {
                // アプリ使用状況セクション
                AppUsageSection()
                
                // 通知設定セクション
                NotificationSection()
                
                // 表示設定セクション
                DisplaySection()
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // UserDefaultsから設定を読み込み
            showMotivationMessages = UserDefaults.standard.bool(forKey: "showMotivationMessages")
            if UserDefaults.standard.object(forKey: "showMotivationMessages") == nil {
                // 初回起動時はデフォルトでtrueに設定
                showMotivationMessages = true
                UserDefaults.standard.set(true, forKey: "showMotivationMessages")
            }
        }
        .alert("アクセシビリティ設定", isPresented: $showingAccessibilityAlert) {
            Button("設定を開く") {
                openAccessibilitySettings()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("使用時間を計測するには、設定アプリでScreen Time権限を有効にしてください。")
        }
        .alert("通知設定", isPresented: $showingNotificationAlert) {
            Button("設定を開く") {
                openNotificationSettings()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("通知を受け取るには、設定アプリで通知権限を有効にしてください。")
        }
    }
    
    // MARK: - アプリ使用状況セクション
    @ViewBuilder
    private func AppUsageSection() -> some View {
        Section {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("データ収集状況")
                        .font(.body)
                    
                    Text(usageDataManager.isMonitoring ? "収集中" : "停止中")
                        .font(.caption)
                        .foregroundColor(usageDataManager.isMonitoring ? .green : .red)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: usageDataManager.isMonitoring ? "play.circle.fill" : "pause.circle.fill")
                    .foregroundColor(usageDataManager.isMonitoring ? .green : .orange)
                    .frame(width: 24)
                
                Text("使用時間追跡")
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { usageDataManager.isMonitoring },
                    set: { newValue in
                        if newValue {
                            usageDataManager.startMonitoring()
                        } else {
                            usageDataManager.stopMonitoring()
                        }
                    }
                ))
            }
        } header: {
            Text("使用状況")
        } footer: {
            Text("アプリの使用パターンを記録し、デジタルデトックスをサポートします。すべてのデータは端末内に保存されます。")
        }
    }
    
    // MARK: - 通知設定セクション
    @ViewBuilder
    private func NotificationSection() -> some View {
        Section {
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                Text("通知")
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { notificationManager.isNotificationEnabled },
                    set: { newValue in
                        if newValue && !notificationManager.hasPermission {
                            showingNotificationAlert = true
                        } else {
                            notificationManager.toggleNotifications(newValue)
                        }
                    }
                ))
            }
            
            if notificationManager.isNotificationEnabled {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("通知時刻")
                    
                    Spacer()
                    
                    DatePicker("", selection: Binding(
                        get: { notificationManager.notificationTime },
                        set: { newTime in
                            notificationManager.updateNotificationTime(newTime)
                        }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                }
                
                HStack {
                    Image(systemName: "leaf.arrow.circlepath")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("デトックス通知")
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { notificationManager.detoxNotificationsEnabled },
                        set: { newValue in
                            notificationManager.toggleDetoxNotifications(newValue)
                        }
                    ))
                }
            }
        } header: {
            Text("通知設定")
        } footer: {
            Text("毎日指定した時刻に使用時間をお知らせします。")
        }
    }
    
    // MARK: - 表示設定セクション
    @ViewBuilder
    private func DisplaySection() -> some View {
        Section {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                Text("メッセージ表示")
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { showMotivationMessages },
                    set: { newValue in
                        showMotivationMessages = newValue
                        UserDefaults.standard.set(newValue, forKey: "showMotivationMessages")
                    }
                ))
            }
        } header: {
            Text("表示設定")
        } footer: {
            Text("健康アドバイスやモチベーションメッセージの表示を切り替えできます。")
        }
    }
    
    // MARK: - ヘルパー関数
    private func openAccessibilitySettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UsageDataManager())
            .environmentObject(NotificationManager())
    }
}
