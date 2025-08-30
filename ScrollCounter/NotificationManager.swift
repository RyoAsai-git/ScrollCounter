import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    @Published var hasPermission = false
    @Published var notificationTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @Published var isNotificationEnabled = true
    @Published var humorNotificationsEnabled = true
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        checkPermissionStatus()
        loadSettings()
    }
    
    // MARK: - 通知権限要求
    func requestNotificationPermission() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            hasPermission = granted
            
            if granted {
                await scheduleNotifications()
            }
        } catch {
            print("通知権限の要求に失敗: \(error)")
        }
    }
    
    private func checkPermissionStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            hasPermission = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - 通知のスケジューリング
    func scheduleNotifications() async {
        guard hasPermission && isNotificationEnabled else { return }
        
        // 既存の通知をクリア
        notificationCenter.removeAllPendingNotificationRequests()
        
        // 毎日の通知をスケジュール
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)
        
        let content = UNMutableNotificationContent()
        content.title = "今日のスクロール記録"
        content.body = await generateNotificationMessage()
        content.sound = .default
        content.badge = 1
        
        // 毎日指定時刻に通知
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyScrollNotification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("通知がスケジュールされました: \(hour):\(minute)")
        } catch {
            print("通知のスケジューリングに失敗: \(error)")
        }
    }
    
    // MARK: - 通知メッセージ生成
    private func generateNotificationMessage() async -> String {
        // 今日のスクロール距離を取得（実際のアプリではScrollDataManagerから取得）
        let todayDistance = await getCurrentScrollDistance()
        
        if !humorNotificationsEnabled {
            return "今日は\(formatDistance(todayDistance))スクロールしました。"
        }
        
        // ユーモアメッセージ
        if todayDistance >= 10000 {
            return "🚄 今日は\(formatDistance(todayDistance))スクロール！新幹線級の移動距離です"
        } else if todayDistance >= 5000 {
            return "🏃‍♂️ 今日は\(formatDistance(todayDistance))スクロール！マラソン級の運動量です"
        } else if todayDistance >= 1000 {
            return "👑 今日は\(formatDistance(todayDistance))スクロール！スクロール王の称号獲得です"
        } else if todayDistance >= 500 {
            return "💪 今日は\(formatDistance(todayDistance))スクロール！指の筋トレ効果抜群です"
        } else {
            return "📱 今日は\(formatDistance(todayDistance))スクロール！明日も頑張りましょう"
        }
    }
    
    private func getCurrentScrollDistance() async -> Double {
        // 実際のアプリではScrollDataManagerから現在の距離を取得
        // ここではデモ用のランダム値を返す
        return Double.random(in: 0...8000)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }
    
    // MARK: - 設定管理
    func updateNotificationTime(_ newTime: Date) {
        notificationTime = newTime
        saveSettings()
        
        Task {
            await scheduleNotifications()
        }
    }
    
    func toggleNotifications(_ enabled: Bool) {
        isNotificationEnabled = enabled
        saveSettings()
        
        if enabled {
            Task {
                await scheduleNotifications()
            }
        } else {
            notificationCenter.removeAllPendingNotificationRequests()
        }
    }
    
    func toggleHumorNotifications(_ enabled: Bool) {
        humorNotificationsEnabled = enabled
        saveSettings()
        
        Task {
            await scheduleNotifications()
        }
    }
    
    // MARK: - 設定の保存/読み込み
    private func saveSettings() {
        UserDefaults.standard.set(isNotificationEnabled, forKey: "isNotificationEnabled")
        UserDefaults.standard.set(humorNotificationsEnabled, forKey: "humorNotificationsEnabled")
        UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
    }
    
    private func loadSettings() {
        isNotificationEnabled = UserDefaults.standard.object(forKey: "isNotificationEnabled") as? Bool ?? true
        humorNotificationsEnabled = UserDefaults.standard.object(forKey: "humorNotificationsEnabled") as? Bool ?? true
        
        if let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            notificationTime = savedTime
        }
    }
    
    // MARK: - 即座に通知を送信（テスト用）
    func sendTestNotification() async {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = await generateNotificationMessage()
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("テスト通知が送信されました")
        } catch {
            print("テスト通知の送信に失敗: \(error)")
        }
    }
}
