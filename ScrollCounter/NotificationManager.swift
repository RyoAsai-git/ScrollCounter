import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    @Published var hasPermission = false
    @Published var notificationTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @Published var isNotificationEnabled = true
    @Published var detoxNotificationsEnabled = true
    
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
        
        if !detoxNotificationsEnabled {
            return "今日は\(formatDistance(todayDistance))スクロールしました。"
        }
        
        // デジタルデトックス促進メッセージ
        if todayDistance >= 42195 {
            return "🚨 今日は\(formatDistance(todayDistance))もスクロール！フルマラソン分です...今すぐデバイスから離れて休憩を"
        } else if todayDistance >= 21098 {
            return "⚠️ \(formatDistance(todayDistance))のスクロール...ハーフマラソン分の負担が指と目にかかっています"
        } else if todayDistance >= 10000 {
            return "😰 \(formatDistance(todayDistance))スクロール...陸上競技場25周分です。長時間の休憩をお勧めします"
        } else if todayDistance >= 7000 {
            return "💭 \(formatDistance(todayDistance))スクロール...東京駅〜渋谷駅分も画面を見続けました。目を休めましょう"
        } else if todayDistance >= 5000 {
            return "⏰ \(formatDistance(todayDistance))スクロール...5km分です。30分の休憩はいかがですか？"
        } else if todayDistance >= 3000 {
            return "🚶‍♀️ \(formatDistance(todayDistance))スクロール...リアル散歩(3km)より画面を見ています"
        } else if todayDistance >= 1609 {
            return "🏃‍♂️ \(formatDistance(todayDistance))スクロール...1マイル分です。実際に歩いてみませんか？"
        } else if todayDistance >= 1000 {
            return "📱 \(formatDistance(todayDistance))スクロール...1km分です。適度な休憩を心がけましょう"
        } else if todayDistance >= 634 {
            return "🏢 \(formatDistance(todayDistance))スクロール...スカイツリー分の縦移動です。首と目を休めて"
        } else if todayDistance >= 400 {
            return "🏃‍♂️ \(formatDistance(todayDistance))スクロール...競技場1周分です。立ち上がってストレッチを"
        } else if todayDistance >= 333 {
            return "🗼 \(formatDistance(todayDistance))スクロール...東京タワー分です。遠くを見て目を休めましょう"
        } else if todayDistance >= 200 {
            return "👀 \(formatDistance(todayDistance))スクロール...瞬きを忘れずに、20-20-20ルールを試してみて"
        } else if todayDistance >= 100 {
            return "😊 \(formatDistance(todayDistance))スクロール...まだ健康的な範囲です。この調子をキープ"
        } else {
            return "✨ \(formatDistance(todayDistance))スクロール...控えめで素晴らしいです！バランスの取れたデジタルライフを"
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
    
    func toggleDetoxNotifications(_ enabled: Bool) {
        detoxNotificationsEnabled = enabled
        saveSettings()
        
        Task {
            await scheduleNotifications()
        }
    }
    
    // MARK: - 設定の保存/読み込み
    private func saveSettings() {
        UserDefaults.standard.set(isNotificationEnabled, forKey: "isNotificationEnabled")
        UserDefaults.standard.set(detoxNotificationsEnabled, forKey: "detoxNotificationsEnabled")
        UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
    }
    
    private func loadSettings() {
        isNotificationEnabled = UserDefaults.standard.object(forKey: "isNotificationEnabled") as? Bool ?? true
        detoxNotificationsEnabled = UserDefaults.standard.object(forKey: "detoxNotificationsEnabled") as? Bool ?? true
        
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
