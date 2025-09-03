import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - シンプルな使用時間データマネージャー
// Screen Time APIを使用せず、アプリ内で独自に使用時間を追跡
@MainActor
class SimpleUsageDataManager: ObservableObject {
    @Published var todayTotalDuration: TimeInterval = 0
    @Published var yesterdayTotalDuration: TimeInterval = 0
    @Published var topApps: [AppUsageData] = []
    @Published var allTimeTopApps: [AppUsageData] = []
    @Published var weeklyData: [DailyUsageData] = []
    @Published var isMonitoring: Bool = false
    @Published var hasScreenTimePermission: Bool = true // 常にtrueに設定
    @Published var appStartDate: Date = Date()
    
    // 互換性のための古いプロパティ名
    var todayTotalDistance: TimeInterval { todayTotalDuration }
    var yesterdayTotalDistance: TimeInterval { yesterdayTotalDuration }
    var hasAccessibilityPermission: Bool { hasScreenTimePermission }
    
    private var cancellables = Set<AnyCancellable>()
    private var sessionStartTime: Date?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var dailyUsageTimer: Timer?
    
    // CoreData関連
    private var persistentContainer: NSPersistentContainer {
        return PersistenceController.shared.container
    }
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        print("🚀 [SimpleUsageDataManager] 初期化開始")
        loadAppStartDate()
        loadHistoricalUsageData()
        loadTodayData()
        loadWeeklyData()
        loadAllTimeTopApps()
        setupAppLifecycleObservers()
        print("📊 [SimpleUsageDataManager] 初期化完了 - 今日の使用時間: \(formatDuration(todayTotalDuration))")
    }
    
    // MARK: - アプリライフサイクル監視
    private func setupAppLifecycleObservers() {
        // アプリがフォアグラウンドに来た時
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.startSession()
            }
            .store(in: &cancellables)
        
        // アプリがバックグラウンドに行く時
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.endSession()
            }
            .store(in: &cancellables)
        
        // アプリが終了する時
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.endSession()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - セッション管理
    private func startSession() {
        guard isMonitoring else { return }
        
        sessionStartTime = Date()
        print("📱 [SimpleUsageDataManager] セッション開始: \(Date())")
        
        // バックグラウンドタスクを開始
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        
        // 短すぎるセッション（5秒未満）は無視
        guard sessionDuration >= 5 else {
            sessionStartTime = nil
            return
        }
        
        // 異常に長いセッション（12時間以上）は制限
        let cappedDuration = min(sessionDuration, 43200) // 最大12時間
        
        recordUsageSession(duration: cappedDuration)
        sessionStartTime = nil
        
        print("📱 [SimpleUsageDataManager] セッション終了: \(formatDuration(cappedDuration))")
        
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // MARK: - 使用時間記録
    private func recordUsageSession(duration: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 今日の使用時間を更新
        todayTotalDuration += duration
        
        // CoreDataに保存
        let entity = ScrollDataEntity(context: viewContext)
        entity.date = Date()
        entity.appName = "ScrollCounter"
        entity.distance = duration
        entity.sessionDistance = duration
        entity.totalDistance = todayTotalDuration
        entity.timestamp = Date()
        
        saveCurrentData()
        
        // トップアプリを更新（簡略化）
        updateTopAppsWithSession(duration: duration)
    }
    
    private func updateTopAppsWithSession(duration: TimeInterval) {
        let appName = "ScrollCounter"
        
        if let index = topApps.firstIndex(where: { $0.name == appName }) {
            let existingDuration = topApps[index].duration
            topApps[index] = AppUsageData(name: appName, duration: existingDuration + duration)
        } else {
            topApps.append(AppUsageData(name: appName, duration: duration))
        }
        
        // 使用時間順でソート
        topApps = topApps.sorted { $0.duration > $1.duration }
    }
    
    // MARK: - 権限管理（簡略化）
    func requestScreenTimePermission() async {
        // Screen Time APIを使用しないため、常に成功
        hasScreenTimePermission = true
        print("📱 [SimpleUsageDataManager] 権限設定完了（内部追跡モード）")
    }
    
    func requestAccessibilityPermission() async {
        await requestScreenTimePermission()
    }
    
    // MARK: - モニタリング制御
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // 現在アプリがアクティブならセッションを開始
        if UIApplication.shared.applicationState == .active {
            startSession()
        }
        
        // 日次データ更新タイマーを開始
        startDailyTimer()
        
        print("📊 [SimpleUsageDataManager] モニタリング開始")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        // 現在のセッションを終了
        endSession()
        
        // タイマーを停止
        dailyUsageTimer?.invalidate()
        dailyUsageTimer = nil
        
        print("📊 [SimpleUsageDataManager] モニタリング停止")
    }
    
    private func startDailyTimer() {
        // 1時間ごとにデータを更新
        dailyUsageTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
    }
    
    // MARK: - データ更新
    func refreshData() async {
        print("🔄 [SimpleUsageDataManager] データ更新中...")
        loadTodayData()
        loadWeeklyData()
        loadAllTimeTopApps()
        print("✅ [SimpleUsageDataManager] データ更新完了")
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
    
    static func formatDuration(_ duration: TimeInterval) -> String {
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
    
    static func formatDurationShort(_ duration: TimeInterval) -> String {
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
    
    // MARK: - データ読み込み（CoreDataベース）
    private func loadAppStartDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "appStartDate") as? Date {
            appStartDate = savedDate
        } else {
            appStartDate = Date()
            UserDefaults.standard.set(appStartDate, forKey: "appStartDate")
        }
    }
    
    private func loadHistoricalUsageData() {
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        
        do {
            let entities = try viewContext.fetch(request)
            
            // 昨日のデータを計算
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            
            let yesterdayEntities = entities.filter { entity in
                guard let entityDate = entity.date else { return false }
                return calendar.isDate(entityDate, inSameDayAs: yesterday)
            }
            
            yesterdayTotalDuration = yesterdayEntities.reduce(0) { $0 + $1.distance }
            
            print("📚 [SimpleUsageDataManager] 履歴データ読み込み: 昨日=\(formatDuration(yesterdayTotalDuration))")
        } catch {
            print("❌ [SimpleUsageDataManager] 履歴データ読み込みエラー: \(error)")
        }
    }
    
    private func loadTodayData() {
        let today = Calendar.current.startOfDay(for: Date())
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", today as NSDate)
        
        do {
            let entities = try viewContext.fetch(request)
            let totalDuration = entities.reduce(0) { $0 + $1.distance }
            
            // 現在のセッション時間も含める
            var currentSessionDuration: TimeInterval = 0
            if let startTime = sessionStartTime {
                currentSessionDuration = Date().timeIntervalSince(startTime)
            }
            
            todayTotalDuration = totalDuration + currentSessionDuration
            
            print("📱 [SimpleUsageDataManager] 今日のデータ: \(formatDuration(todayTotalDuration))")
        } catch {
            print("❌ [SimpleUsageDataManager] 今日のデータ読み込みエラー: \(error)")
        }
    }
    
    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        var weeklyUsageData: [DailyUsageData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            
            do {
                let entities = try viewContext.fetch(request)
                let totalDuration = entities.reduce(0) { $0 + $1.distance }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                formatter.locale = Locale(identifier: "ja_JP")
                
                let dailyData = DailyUsageData(
                    date: date,
                    totalDuration: totalDuration,
                    formattedDate: formatter.string(from: date)
                )
                
                weeklyUsageData.append(dailyData)
            } catch {
                print("❌ [SimpleUsageDataManager] 日別データ読み込みエラー: \(error)")
            }
        }
        
        weeklyData = weeklyUsageData.reversed()
    }
    
    private func loadAllTimeTopApps() {
        let request: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        
        do {
            let entities = try viewContext.fetch(request)
            var appDurations: [String: TimeInterval] = [:]
            
            for entity in entities {
                let appName = entity.appName ?? "ScrollCounter"
                appDurations[appName, default: 0] += entity.distance
            }
            
            allTimeTopApps = appDurations.map { AppUsageData(name: $0.key, duration: $0.value) }
                .sorted { $0.duration > $1.duration }
                .prefix(10)
                .map { $0 }
            
            print("🏆 [SimpleUsageDataManager] 全期間トップアプリ: \(allTimeTopApps.count)個")
        } catch {
            print("❌ [SimpleUsageDataManager] 全期間データ読み込みエラー: \(error)")
        }
    }
    
    func saveCurrentData() {
        do {
            try viewContext.save()
            print("💾 [SimpleUsageDataManager] データ保存完了")
        } catch {
            print("❌ [SimpleUsageDataManager] データ保存エラー: \(error)")
        }
    }
}
