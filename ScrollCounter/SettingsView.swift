import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var scrollDataManager: ScrollDataManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAccessibilityAlert = false
    @State private var showingNotificationAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // アクセシビリティ設定セクション
                AccessibilitySection()
                
                // 通知設定セクション
                NotificationSection()
                
                // 表示設定セクション
                DisplaySection()
                
                // データ管理セクション
                DataManagementSection()
                
                // アプリ情報セクション
                AppInfoSection()
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // 画面表示時にスクロール検出
            Task {
                await simulateScrollDetection(appName: "設定", distance: 20.0)
            }
        }
        .alert("アクセシビリティ設定", isPresented: $showingAccessibilityAlert) {
            Button("設定を開く") {
                openAccessibilitySettings()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("スクロール距離を計測するには、設定アプリでアクセシビリティ権限を有効にしてください。")
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
    
    // MARK: - スクロール検出シミュレーション
    private func simulateScrollDetection(appName: String, distance: Double) async {
        print("⚙️ [SettingsView] スクロール検出: \(appName) - \(distance)m")
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollDetected"),
            object: nil,
            userInfo: [
                "distance": distance,
                "appName": appName
            ]
        )
        print("📤 [SettingsView] 通知送信完了")
    }
    
    // MARK: - アクセシビリティ設定セクション
    @ViewBuilder
    private func AccessibilitySection() -> some View {
        Section {
            HStack {
                Image(systemName: "accessibility")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("アクセシビリティ権限")
                        .font(.body)
                    
                    Text(scrollDataManager.hasAccessibilityPermission ? "有効" : "無効")
                        .font(.caption)
                        .foregroundColor(scrollDataManager.hasAccessibilityPermission ? .green : .red)
                }
                
                Spacer()
                
                if !scrollDataManager.hasAccessibilityPermission {
                    Button("設定") {
                        showingAccessibilityAlert = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            HStack {
                Image(systemName: scrollDataManager.isMonitoring ? "play.circle.fill" : "pause.circle.fill")
                    .foregroundColor(scrollDataManager.isMonitoring ? .green : .orange)
                    .frame(width: 24)
                
                Text("スクロール計測")
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { scrollDataManager.isMonitoring },
                    set: { newValue in
                        if newValue {
                            scrollDataManager.startMonitoring()
                        } else {
                            scrollDataManager.stopMonitoring()
                        }
                    }
                ))
            }
        } header: {
            Text("計測設定")
        } footer: {
            Text("スクロール距離を計測するには、アクセシビリティ権限が必要です。")
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
                
                Button(action: {
                    Task {
                        await notificationManager.sendTestNotification()
                    }
                }) {
                    HStack {
                        Image(systemName: "paperplane")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text("テスト通知を送信")
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        } header: {
            Text("通知設定")
        } footer: {
            Text("毎日指定した時刻にスクロール距離をお知らせします。")
        }
    }
    
    // MARK: - 表示設定セクション
    @ViewBuilder
    private func DisplaySection() -> some View {
        Section {
            NavigationLink(destination: ExcludedAppsView()) {
                HStack {
                    Image(systemName: "app.badge.checkmark")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("計測対象アプリ")
                    
                    Spacer()
                    
                    Text("管理")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .frame(width: 24)
                
                Text("ネタ表示")
                
                Spacer()
                
                Toggle("", isOn: .constant(true)) // 実際のアプリでは設定を保存
            }
        } header: {
            Text("表示設定")
        } footer: {
            Text("距離換算やユーモアメッセージの表示を切り替えできます。")
        }
    }
    
    // MARK: - データ管理セクション
    @ViewBuilder
    private func DataManagementSection() -> some View {
        Section {
            Button(action: {
                scrollDataManager.saveCurrentData()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("データを保存")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            
            Button(action: {
                // データエクスポート機能（実装予定）
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("データをエクスポート")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            
            Button(action: {
                // データリセット確認アラート表示（実装予定）
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("データをリセット")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        } header: {
            Text("データ管理")
        } footer: {
            Text("スクロールデータはすべて端末内に保存され、外部に送信されることはありません。")
        }
    }
    
    // MARK: - アプリ情報セクション
    @ViewBuilder
    private func AppInfoSection() -> some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("バージョン")
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com")!) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("GitHub")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "mailto:support@scrollcounter.app")!) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("お問い合わせ")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("アプリ情報")
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

// MARK: - 除外アプリ管理画面
struct ExcludedAppsView: View {
    @State private var excludedApps: Set<String> = []
    @State private var availableApps = [
        "Safari", "Chrome", "Twitter", "Instagram", "TikTok", "YouTube", 
        "LINE", "Discord", "Slack", "Notion", "Reddit", "Pinterest"
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(availableApps, id: \.self) { app in
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                        
                        Text(app)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { !excludedApps.contains(app) },
                            set: { isIncluded in
                                if isIncluded {
                                    excludedApps.remove(app)
                                } else {
                                    excludedApps.insert(app)
                                }
                            }
                        ))
                    }
                }
            } header: {
                Text("アプリ一覧")
            } footer: {
                Text("オフにしたアプリはスクロール距離の計測対象から除外されます。")
            }
        }
        .navigationTitle("計測対象アプリ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ScrollDataManager())
            .environmentObject(NotificationManager())
    }
}
