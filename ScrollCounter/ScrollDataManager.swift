// MARK: - このファイルはRealUsageDataManagerに移行されました
// 互換性のためにtypealiasを使用してXcodeプロジェクトの参照を維持

import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - 型の互換性エイリアス
typealias ScrollDataManager = RealUsageDataManager
typealias UsageDataManager = RealUsageDataManager
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

// MARK: - 古いUsageDataManagerクラスは削除され、RealUsageDataManagerに置き換えられました
// 実際の実装は RealUsageDataManager.swift を参照してください