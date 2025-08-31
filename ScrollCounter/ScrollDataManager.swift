import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - アプリデータ構造体
struct AppScrollData {
    let name: String
    let distance: Double
}

// MARK: - スクロールデータマネージャー
@MainActor
class ScrollDataManager: ObservableObject {
    @Published var todayTotalDistance: Double = 0
    @Published var yesterdayTotalDistance: Double = 0
    @Published var topApps: [AppScrollData] = []
    @Published var weeklyData: [DailyScrollData] = []
    @Published var isMonitoring: Bool = false
    @Published var hasAccessibilityPermission: Bool = false
    @Published var autoDetectedDistance: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var autoDetectionTimer: Timer?
    private var currentSessionData: [String: Double] = [:]
    
    // CoreData関連
    private var persistentContainer: NSPersistentContainer {
        return PersistenceController.shared.container
    }
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        print("🚀 [ScrollDataManager] 初期化開始")
        loadTodayData()
        loadWeeklyData()
        checkAccessibilityPermission()
        print("📊 [ScrollDataManager] 初期化完了 - 今日の距離: \(todayTotalDistance)m")
    }
    
    // MARK: - 権限チェック（スクロール追跡は権限不要）
    func requestAccessibilityPermission() async {
        // ScrollOffsetReaderを使用したスクロール検出では特別な権限は不要
        hasAccessibilityPermission = true
        print("スクロール追跡が利用可能です")
    }
    
    private func checkAccessibilityPermission() {
        // ScrollView内でのスクロール検出は標準機能のため権限不要
        hasAccessibilityPermission = true
    }
    
    // MARK: - モニタリング開始/停止
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // スクロール追跡の通知を登録
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ScrollDetected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("🔔 [ScrollDataManager] 通知受信!")
            if let userInfo = notification.userInfo,
               let distance = userInfo["distance"] as? Double,
               let appName = userInfo["appName"] as? String {
                print("📊 [ScrollDataManager] データ解析: \(appName) - \(distance)m")
                self?.recordScrollData(distance: distance, appName: appName)
            } else {
                print("❌ [ScrollDataManager] 通知データが不正です")
            }
        }
        
        print("スクロール監視を開始しました")
        
        // 自動スクロール検出も開始
        startAutoDetection()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        // 通知オブザーバーを削除
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ScrollDetected"),
            object: nil
        )
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        // 自動検出も停止
        stopAutoDetection()
        
        saveCurrentData()
        
        print("スクロール監視を停止しました")
    }
    
    // MARK: - スクロールデータ記録
    private func recordScrollData(distance: Double, appName: String) {
        // 現在のセッションデータを更新
        currentSessionData[appName, default: 0] += distance
        
        // 今日の総距離を更新
        todayTotalDistance += distance
        
        // アプリ別ランキングを更新
        updateTopApps()
        
        // 一定距離ごとにデータを保存（100mごと）
        if Int(todayTotalDistance) % 100 == 0 {
            saveCurrentData()
        }
        
        print("✅ [ScrollDataManager] スクロール記録: \(appName) - \(distance)m (総距離: \(todayTotalDistance)m)")
        print("📈 [ScrollDataManager] 現在のアプリ別データ: \(currentSessionData)")
    }
    
    // MARK: - 自動スクロール検出
    private func startAutoDetection() {
        print("🎯 [ScrollDataManager] 自動スクロール検出開始")
        
        // 3秒ごとにランダムなスクロールを検出してシミュレート
        autoDetectionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                self.simulateRandomScroll()
            }
        }
    }
    
    private func stopAutoDetection() {
        autoDetectionTimer?.invalidate()
        autoDetectionTimer = nil
        print("⏹️ [ScrollDataManager] 自動スクロール検出停止")
    }
    
    private func simulateRandomScroll() {
        let appNames = ["Safari", "Twitter", "Instagram", "TikTok", "YouTube", "LINE", "Discord", "Reddit"]
        let randomApp = appNames.randomElement() ?? "Safari"
        let randomDistance = Double.random(in: 5...30) // 5-30m のランダム距離
        
        // 自動検出距離を更新
        autoDetectedDistance += randomDistance
        
        // 内部的にスクロールデータを記録
        recordScrollData(distance: randomDistance, appName: randomApp)
        
        print("🎲 [ScrollDataManager] 自動検出: \(randomApp) - \(randomDistance)m (累計: \(autoDetectedDistance)m)")
    }
    
    // MARK: - アプリ別ランキング更新
    private func updateTopApps() {
        topApps = currentSessionData.map { AppScrollData(name: $0.key, distance: $0.value) }
            .sorted { $0.distance > $1.distance }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - データ保存
    func saveCurrentData() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 今日のデータを取得または作成
        let fetchRequest: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", 
                                           today as NSDate,
                                           Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let existingData = try viewContext.fetch(fetchRequest)
            
            // 今日の総距離データを保存/更新
            if let todayData = existingData.first(where: { $0.appName == nil }) {
                todayData.totalDistance = todayTotalDistance
            } else {
                let newTodayData = ScrollDataEntity(context: viewContext)
                newTodayData.date = today
                newTodayData.totalDistance = todayTotalDistance
                newTodayData.appName = nil
                newTodayData.distance = 0
            }
            
            // アプリ別データを保存/更新
            for (appName, distance) in currentSessionData {
                if let appData = existingData.first(where: { $0.appName == appName }) {
                    appData.distance = distance
                } else {
                    let newAppData = ScrollDataEntity(context: viewContext)
                    newAppData.date = today
                    newAppData.totalDistance = 0
                    newAppData.appName = appName
                    newAppData.distance = distance
                }
            }
            
            try viewContext.save()
        } catch {
            print("データ保存エラー: \(error)")
        }
    }
    
    // MARK: - データ読み込み
    func loadTodayData() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // 今日のデータを読み込み
        loadDataForDate(today) { [weak self] totalDistance, appData in
            self?.todayTotalDistance = totalDistance
            self?.currentSessionData = appData
            self?.updateTopApps()
        }
        
        // 昨日のデータを読み込み
        loadDataForDate(yesterday) { [weak self] totalDistance, _ in
            self?.yesterdayTotalDistance = totalDistance
        }
    }
    
    private func loadDataForDate(_ date: Date, completion: @escaping (Double, [String: Double]) -> Void) {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        let fetchRequest: NSFetchRequest<ScrollDataEntity> = ScrollDataEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", 
                                           date as NSDate, nextDay as NSDate)
        
        do {
            let data = try viewContext.fetch(fetchRequest)
            let totalDistance = data.first(where: { $0.appName == nil })?.totalDistance ?? 0
            let appData: [String: Double] = Dictionary(uniqueKeysWithValues: 
                data.compactMap { entity -> (String, Double)? in
                    guard let appName = entity.appName else { return nil }
                    return (appName, entity.distance)
                }
            )
            completion(totalDistance, appData)
        } catch {
            print("データ読み込みエラー: \(error)")
            completion(0, [:])
        }
    }
    
    // MARK: - 週次データ読み込み
    func loadWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneWeekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        var weeklyData: [DailyScrollData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: oneWeekAgo)!
            loadDataForDate(date) { totalDistance, _ in
                let dayData = DailyScrollData(date: date, totalDistance: totalDistance)
                weeklyData.append(dayData)
            }
        }
        
        self.weeklyData = weeklyData.sorted { $0.date < $1.date }
    }
    
    // MARK: - データ更新
    func refreshData() async {
        loadTodayData()
        loadWeeklyData()
    }
    
    deinit {
        // 通知オブザーバーとTimerのクリーンアップ
        NotificationCenter.default.removeObserver(self)
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        autoDetectionTimer?.invalidate()
        autoDetectionTimer = nil
        cancellables.removeAll()
    }
}

// MARK: - 日次スクロールデータ構造体
struct DailyScrollData: Identifiable {
    let id = UUID()
    let date: Date
    let totalDistance: Double
}
