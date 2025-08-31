import SwiftUI
import Combine

// MARK: - 自動スクロール検出器
class AutoScrollDetector: ObservableObject {
    @Published var totalDetectedDistance: Double = 0
    private var timer: Timer?
    private var isDetecting = false
    
    init() {
        startAutoDetection()
    }
    
    // MARK: - 自動検出開始
    func startAutoDetection() {
        guard !isDetecting else { return }
        isDetecting = true
        
        print("🎯 [AutoScrollDetector] 自動スクロール検出開始")
        
        // 3秒ごとにランダムなスクロールを検出してシミュレート
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.simulateRandomScroll()
        }
    }
    
    // MARK: - 自動検出停止
    func stopAutoDetection() {
        isDetecting = false
        timer?.invalidate()
        timer = nil
        print("⏹️ [AutoScrollDetector] 自動スクロール検出停止")
    }
    
    // MARK: - ランダムスクロールシミュレーション
    private func simulateRandomScroll() {
        let appNames = ["Safari", "Twitter", "Instagram", "TikTok", "YouTube", "LINE", "Discord", "Reddit"]
        let randomApp = appNames.randomElement() ?? "Safari"
        let randomDistance = Double.random(in: 5...30) // 5-30m のランダム距離
        
        // 通知を送信
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollDetected"),
            object: nil,
            userInfo: [
                "distance": randomDistance,
                "appName": randomApp
            ]
        )
        
        totalDetectedDistance += randomDistance
        print("🎲 [AutoScrollDetector] 自動検出: \(randomApp) - \(randomDistance)m (累計: \(totalDetectedDistance)m)")
    }
    
    // MARK: - 手動スクロール検出
    func detectScroll(appName: String, distance: Double) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollDetected"),
            object: nil,
            userInfo: [
                "distance": distance,
                "appName": appName
            ]
        )
        print("👆 [AutoScrollDetector] 手動検出: \(appName) - \(distance)m")
    }
    
    deinit {
        stopAutoDetection()
    }
}

// MARK: - スクロール検出View拡張
struct AutoScrollDetectorModifier: ViewModifier {
    @StateObject private var detector = AutoScrollDetector()
    
    func body(content: Content) -> some View {
        content
            .environmentObject(detector)
            .onAppear {
                detector.startAutoDetection()
            }
            .onDisappear {
                detector.stopAutoDetection()
            }
    }
}

extension View {
    func withAutoScrollDetection() -> some View {
        self.modifier(AutoScrollDetectorModifier())
    }
}
