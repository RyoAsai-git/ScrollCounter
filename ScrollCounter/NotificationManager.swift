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
        content.title = "今日の使用時間記録"
        content.body = await generateNotificationMessage()
        content.sound = .default
        content.badge = 1
        
        // 毎日指定時刻に通知
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyUsageNotification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("通知がスケジュールされました: \(hour):\(minute)")
        } catch {
            print("通知のスケジューリングに失敗: \(error)")
        }
    }
    
    // MARK: - 通知メッセージ生成
    private func generateNotificationMessage() async -> String {
        // 今日の使用時間を取得（実際のアプリではUsageDataManagerから取得）
        let todayDuration = await getCurrentUsageDuration()
        
        if !detoxNotificationsEnabled {
            return "今日は\(formatDuration(todayDuration))使用しました。"
        }
        
        // デジタルデトックス促進メッセージ
        if todayDuration >= 28800 { // 8時間
            return "🚨 今日は\(formatDuration(todayDuration))も使用！深刻なデジタル疲労の危険性...今すぐデバイスから離れて休憩を"
        } else if todayDuration >= 21600 { // 6時間
            return "⚠️ \(formatDuration(todayDuration))の使用時間...目と首の健康が心配です"
        } else if todayDuration >= 18000 { // 5時間
            return "😰 \(formatDuration(todayDuration))使用...デジタルデトックスが必要かもしれません"
        } else if todayDuration >= 14400 { // 4時間
            return "💭 \(formatDuration(todayDuration))使用...外の景色を見て目を休めましょう"
        } else if todayDuration >= 10800 { // 3時間
            return "⏰ \(formatDuration(todayDuration))使用...散歩で気分転換はいかがですか？"
        } else if todayDuration >= 7200 { // 2時間
            return "🚶‍♀️ \(formatDuration(todayDuration))使用...リアルな活動も大切です"
        } else if todayDuration >= 3600 { // 1時間
            return "🏃‍♂️ \(formatDuration(todayDuration))使用...適度な休憩を取りましょう"
        } else if todayDuration >= 1800 { // 30分
            return "📱 \(formatDuration(todayDuration))使用...良いペースを保っています"
        } else if todayDuration >= 900 { // 15分
            return "🏢 \(formatDuration(todayDuration))使用...首のストレッチを忘れずに"
        } else if todayDuration >= 600 { // 10分
            return "🏃‍♂️ \(formatDuration(todayDuration))使用...立ち上がって体を動かしましょう"
        } else if todayDuration >= 300 { // 5分
            return "🗼 \(formatDuration(todayDuration))使用...瞬きを意識してください"
        } else if todayDuration >= 180 { // 3分
            return "👀 \(formatDuration(todayDuration))使用...健康的な利用です"
        } else if todayDuration >= 60 { // 1分
            return "😊 \(formatDuration(todayDuration))使用...まだ適度な範囲です"
        } else {
            return "✨ \(formatDuration(todayDuration))使用...控えめで素晴らしいです！バランスの取れたデジタルライフを"
        }
    }
    
    private func getCurrentUsageDuration() async -> TimeInterval {
        // 実際のアプリではUsageDataManagerから現在の使用時間を取得
        // ここではデモ用のランダム値を返す（秒単位）
        return TimeInterval.random(in: 0...14400) // 0-4時間
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else if minutes > 0 {
            return "\(minutes)分"
        } else {
            return "1分未満"
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
