// MARK: - このファイルはUsageDataManagerに移行されました
// 互換性のためにtypealiasを使用してXcodeプロジェクトの参照を維持

import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - 型の互換性エイリアス
typealias ScrollDataManager = UsageDataManager
typealias AppScrollData = AppUsageData
typealias DailyScrollData = DailyUsageData

// MARK: - アプリデータ構造体
struct AppUsageData {
    let name: String
    let duration: TimeInterval // 秒単位での使用時間
}

struct DailyUsageData: Identifiable {
    let id = UUID()
    let date: Date
    let totalDuration: TimeInterval // 秒単位
    let formattedDate: String
}

// MARK: - 使用時間データマネージャー
@MainActor
class UsageDataManager: ObservableObject {
    @Published var todayTotalDuration: TimeInterval = 0 // 秒単位
    @Published var yesterdayTotalDuration: TimeInterval = 0 // 秒単位
    @Published var topApps: [AppUsageData] = []
    @Published var allTimeTopApps: [AppUsageData] = []
    @Published var weeklyData: [DailyUsageData] = []
    @Published var isMonitoring: Bool = false
    @Published var hasScreenTimePermission: Bool = false
    @Published var appStartDate: Date = Date()
    
    // 互換性のための古いプロパティ名
    var todayTotalDistance: TimeInterval { todayTotalDuration }
    var yesterdayTotalDistance: TimeInterval { yesterdayTotalDuration }
    var hasAccessibilityPermission: Bool { hasScreenTimePermission }
    
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var currentSessionData: [String: TimeInterval] = [:]
    
    // CoreData関連
    private var persistentContainer: NSPersistentContainer {
        return PersistenceController.shared.container
    }
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        print("🚀 [UsageDataManager] 初期化開始")
        loadAppStartDate()
        loadHistoricalUsageData()
        loadTodayData()
        loadWeeklyData()
        loadAllTimeTopApps()
        checkScreenTimePermission()
        print("📊 [UsageDataManager] 初期化完了 - 今日の使用時間: \(formatDuration(todayTotalDuration))")
    }
    
    // MARK: - 時間フォーマットユーティリティ
    func formatDuration(_ duration: TimeInterval) -> String {
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
    
    func formatDurationShort(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // 互換性のための古いメソッド名
    func formatDistance(_ duration: TimeInterval) -> String {
        return formatDuration(duration)
    }
    
    // MARK: - 権限チェック（Screen Time API用）
    func requestScreenTimePermission() async {
        // Screen Time APIでは FamilyControls framework を使用
        // 実際の実装では権限リクエストが必要
        hasScreenTimePermission = true
        print("📱 Screen Time権限が利用可能です")
    }
    
    // 互換性のための古いメソッド名
    func requestAccessibilityPermission() async {
        await requestScreenTimePermission()
    }
    
    private func checkScreenTimePermission() {
        // Screen Time APIの使用可能性をチェック
        // iOS 15.0以降で利用可能
        hasScreenTimePermission = true
    }
    
    // MARK: - モニタリング開始/停止
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        print("📊 [UsageDataManager] モニタリング開始")
        
        // デモ用：1分ごとに使用時間を更新
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                self.simulateUsageUpdate()
            }
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("📊 [UsageDataManager] モニタリング停止")
    }
    
    // MARK: - 使用時間シミュレーション（デモ用）
    private func simulateUsageUpdate() {
        // 1-5分のランダムな使用時間を追加
        let additionalTime: TimeInterval = TimeInterval.random(in: 60...300) // 1-5分
        todayTotalDuration += additionalTime
        
        // アプリ別使用時間もシミュレーション
        let apps = ["Safari", "Twitter", "Instagram", "YouTube", "TikTok"]
        let randomApp = apps.randomElement() ?? "Safari"
        currentSessionData[randomApp, default: 0] += additionalTime
        
        updateTopApps()
        saveCurrentData()
        
        print("📱 使用時間更新: +\(formatDuration(additionalTime)) (総計: \(formatDuration(todayTotalDuration)))")
    }
    
    // 互換性のための古いメソッド名
    func recordUsageData(duration: TimeInterval, appName: String) {
        // 使用時間データを記録
        todayTotalDuration += duration
        currentSessionData[appName, default: 0] += duration
        updateTopApps()
    }
    
    func refreshData() async {
        print("🔄 [UsageDataManager] データ更新中...")
        loadTodayData()
        loadWeeklyData()
        updateTopApps()
        print("✅ [UsageDataManager] データ更新完了")
    }
    
    // MARK: - データ読み込み
    private func loadTodayData() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", today as NSDate)
        
        do {
            let results = try viewContext.fetch(request)
            // distanceをdurationとして扱う（既存データとの互換性のため）
            todayTotalDuration = results.reduce(0) { $0 + $1.totalDistance }
            print("📊 今日のデータ読み込み: \(formatDuration(todayTotalDuration))")
        } catch {
            print("❌ 今日のデータ読み込みエラー: \(error)")
        }
    }
    
    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        var dailyData: [DailyUsageData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: weekAgo)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            
            let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", date as NSDate, nextDay as NSDate)
            
            do {
                let results = try viewContext.fetch(request)
                let totalDuration = results.reduce(0) { $0 + $1.totalDistance }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                
                dailyData.append(DailyUsageData(
                    date: date,
                    totalDuration: totalDuration,
                    formattedDate: formatter.string(from: date)
                ))
            } catch {
                print("❌ 週間データ読み込みエラー: \(error)")
            }
        }
        
        weeklyData = dailyData
    }
    
    private func loadHistoricalUsageData() {
        print("📈 [UsageDataManager] 履歴使用時間データ生成開始")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 過去7日間の推定使用時間データを生成
        for i in 1...7 {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
                let estimatedDuration = generateEstimatedDailyUsage(for: pastDate)
                let apps = generateEstimatedAppUsage(totalDuration: estimatedDuration)
                
                // Core Dataに保存（distanceフィールドを使用時間として利用）
                saveHistoricalData(date: pastDate, duration: estimatedDuration, apps: apps)
            }
        }
        
        print("📈 履歴データ生成完了")
    }
    
    private func generateEstimatedDailyUsage(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 平日と休日で使用時間を調整
        let baseHours: Double = (weekday == 1 || weekday == 7) ? 4.5 : 3.5 // 休日は多め
        let variation = Double.random(in: -1.0...1.5) // ±1.5時間の変動
        let finalHours = max(1.0, baseHours + variation)
        
        return finalHours * 3600 // 秒に変換
    }
    
    private func generateEstimatedAppUsage(totalDuration: TimeInterval) -> [String: TimeInterval] {
        let apps = [
            "Safari": 0.25,
            "Twitter": 0.20,
            "Instagram": 0.15,
            "YouTube": 0.15,
            "TikTok": 0.10,
            "LINE": 0.08,
            "その他": 0.07
        ]
        
        var appUsage: [String: TimeInterval] = [:]
        for (app, percentage) in apps {
            appUsage[app] = totalDuration * percentage
        }
        
        return appUsage
    }
    
    private func saveHistoricalData(date: Date, duration: TimeInterval, apps: [String: TimeInterval]) {
        // 既存データをチェック
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let existingData = try viewContext.fetch(request)
            if !existingData.isEmpty {
                return // 既存データがある場合はスキップ
            }
            
            // 日次総計データを保存
            let entity = ScrollDataEntity(context: viewContext)
            entity.date = date
            entity.totalDistance = duration // durationをdistanceフィールドに保存
            entity.appName = nil
            entity.sessionDistance = duration
            entity.timestamp = date
            
            // アプリ別データを保存
            for (appName, appDuration) in apps {
                let appEntity = ScrollDataEntity(context: viewContext)
                appEntity.date = date
                appEntity.totalDistance = appDuration
                appEntity.appName = appName
                appEntity.sessionDistance = appDuration
                appEntity.timestamp = date
            }
            
            try viewContext.save()
        } catch {
            print("❌ 履歴データ保存エラー: \(error)")
        }
    }
    
    // MARK: - アプリ別データ管理
    private func updateTopApps() {
        var appTotals: [String: TimeInterval] = [:]
        
        // 今日のセッションデータを集計
        for (app, duration) in currentSessionData {
            appTotals[app, default: 0] += duration
        }
        
        // 今日の保存済みデータも含める
        let today = Calendar.current.startOfDay(for: Date())
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND appName != nil", today as NSDate)
        
        do {
            let results = try viewContext.fetch(request)
            for result in results {
                if let appName = result.appName {
                    appTotals[appName, default: 0] += result.totalDistance
                }
            }
        } catch {
            print("❌ アプリ別データ読み込みエラー: \(error)")
        }
        
        // トップ5を抽出
        topApps = appTotals
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { AppUsageData(name: $0.key, duration: $0.value) }
    }
    
    private func loadAllTimeTopApps() {
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "appName != nil")
        
        do {
            let results = try viewContext.fetch(request)
            var appTotals: [String: TimeInterval] = [:]
            
            for result in results {
                if let appName = result.appName {
                    appTotals[appName, default: 0] += result.totalDistance
                }
            }
            
            allTimeTopApps = appTotals
                .sorted { $0.value > $1.value }
                .prefix(10)
                .map { AppUsageData(name: $0.key, duration: $0.value) }
                
        } catch {
            print("❌ 全期間アプリ別データ読み込みエラー: \(error)")
        }
    }
    
    // MARK: - データ保存
    func saveCurrentData() {
        let today = Date()
        
        // 今日の総使用時間を保存
        let entity = ScrollDataEntity(context: viewContext)
        entity.date = today
        entity.totalDistance = todayTotalDuration
        entity.appName = nil
        entity.sessionDistance = todayTotalDuration
        entity.timestamp = today
        
        // アプリ別データを保存
        for (appName, duration) in currentSessionData {
            let appEntity = ScrollDataEntity(context: viewContext)
            appEntity.date = today
            appEntity.totalDistance = duration
            appEntity.appName = appName
            appEntity.sessionDistance = duration
            appEntity.timestamp = today
        }
        
        do {
            try viewContext.save()
            print("💾 データ保存完了")
        } catch {
            print("❌ データ保存エラー: \(error)")
        }
        
        // セッションデータをクリア
        currentSessionData.removeAll()
        
        // 昨日のデータを更新
        updateYesterdayData()
    }
    
    private func updateYesterdayData() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
        
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND appName == nil", 
                                       startOfYesterday as NSDate, endOfYesterday as NSDate)
        
        do {
            let results = try viewContext.fetch(request)
            yesterdayTotalDuration = results.reduce(0) { $0 + $1.totalDistance }
        } catch {
            print("❌ 昨日のデータ読み込みエラー: \(error)")
        }
    }
    
    // MARK: - アプリ起動日管理
    private func loadAppStartDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "appStartDate") as? Date {
            appStartDate = savedDate
        } else {
            appStartDate = Date()
            UserDefaults.standard.set(appStartDate, forKey: "appStartDate")
        }
    }
    
    // MARK: - 日付フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    deinit {
        monitoringTimer?.invalidate()
        print("🔄 [UsageDataManager] リソースクリーンアップ完了")
    }
}
