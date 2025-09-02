import SwiftUI
import Charts

struct ChartView: View {
    @EnvironmentObject var usageDataManager: UsageDataManager
    @State private var selectedDataPoint: DailyUsageData?
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 時間範囲選択
                    TimeRangeSelector()
                    
                    // メインチャート
                    MainChartCard()
                    
                    // 統計情報
                    StatisticsCard()
                    
                    // トレンド分析
                    TrendAnalysisCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("使用時間履歴")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // 使用時間更新：プルリフレッシュ時に使用時間を記録
                await simulateUsageUpdate(appName: "履歴", duration: 80.0)
                await usageDataManager.refreshData()
            }
        }
        .environmentObject(usageDataManager)
        .onAppear {
            // 画面表示時に使用時間更新
            Task {
                await simulateUsageUpdate(appName: "履歴", duration: 60.0)
            }
        }
    }
    
    // MARK: - 使用時間更新シミュレーション
    private func simulateUsageUpdate(appName: String, duration: TimeInterval) async {
        print("📊 [ChartView] 使用時間更新: \(appName) - \(Int(duration))秒")
        NotificationCenter.default.post(
            name: NSNotification.Name("UsageUpdated"),
            object: nil,
            userInfo: [
                "duration": duration,
                "appName": appName
            ]
        )
        print("📤 [ChartView] 通知送信完了")
    }
    
    // MARK: - 時間範囲選択
    @ViewBuilder
    private func TimeRangeSelector() -> some View {
        Picker("期間", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 20)
    }
    
    // MARK: - メインチャート
    @ViewBuilder
    private func MainChartCard() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("使用時間の推移")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if usageDataManager.weeklyData.isEmpty {
                EmptyChartView()
            } else {
                UsageTimeChart()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - 空のチャート表示
    @ViewBuilder
    private func EmptyChartView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("データがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("アプリを使い始めるとグラフが表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
    
    // MARK: - 使用時間チャート
    @ViewBuilder
    private func UsageTimeChart() -> some View {
        Chart(usageDataManager.weeklyData) { data in
            BarMark(
                x: .value("日付", data.date, unit: .day),
                y: .value("使用時間", data.totalDuration)
            )
            .foregroundStyle(LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.6)]),
                startPoint: .bottom,
                endPoint: .top
            ))
            .cornerRadius(4)
            
            // 選択されたデータポイントのハイライト
            if let selectedDataPoint = selectedDataPoint,
               data.date == selectedDataPoint.date {
                RuleMark(x: .value("日付", data.date, unit: .day))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(usageDataManager.formatDuration(doubleValue))
                    }
                }
            }
        }
        .onTapGesture {
            // チャートタップ時の処理（簡略化）
            if let firstData = usageDataManager.weeklyData.first {
                selectedDataPoint = firstData
            }
        }
        
        // 選択されたデータの詳細表示
        if let selectedDataPoint = selectedDataPoint {
            SelectedDataView(data: selectedDataPoint)
        }
    }
    
    // MARK: - 選択されたデータの表示
    @ViewBuilder
    private func SelectedDataView(data: DailyUsageData) -> some View {
        VStack(spacing: 8) {
            Text(formatDate(data.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(usageDataManager.formatDuration(data.totalDuration))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
        .onTapGesture {
            selectedDataPoint = nil
        }
    }
    
    // MARK: - 統計情報カード
    @ViewBuilder
    private func StatisticsCard() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("統計情報")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatisticItem(
                    title: "平均",
                    value: usageDataManager.formatDuration(weeklyAverage),
                    color: .blue
                )
                
                StatisticItem(
                    title: "最高",
                    value: usageDataManager.formatDuration(weeklyMax),
                    color: .green
                )
                
                StatisticItem(
                    title: "合計",
                    value: usageDataManager.formatDuration(weeklyTotal),
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - トレンド分析カード
    @ViewBuilder
    private func TrendAnalysisCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("トレンド分析")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(trendMessage)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(trendAdvice)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
    
    // MARK: - 統計項目
    @ViewBuilder
    private func StatisticItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    

    
    // MARK: - 計算プロパティ
    private var weeklyAverage: TimeInterval {
        guard !usageDataManager.weeklyData.isEmpty else { return 0 }
        let total = usageDataManager.weeklyData.reduce(0) { $0 + $1.totalDuration }
        return total / Double(usageDataManager.weeklyData.count)
    }
    
    private var weeklyMax: TimeInterval {
        usageDataManager.weeklyData.map(\.totalDuration).max() ?? 0
    }
    
    private var weeklyTotal: TimeInterval {
        usageDataManager.weeklyData.reduce(0) { $0 + $1.totalDuration }
    }
    
    private var trendMessage: String {
        guard usageDataManager.weeklyData.count >= 2 else {
            return "データが不足しています。もう少し使い続けてトレンドを確認しましょう。"
        }
        
        let recent = Array(usageDataManager.weeklyData.suffix(3))
        let recentAverage = recent.reduce(0) { $0 + $1.totalDuration } / Double(recent.count)
        
        let earlier = Array(usageDataManager.weeklyData.prefix(3))
        let earlierAverage = earlier.reduce(0) { $0 + $1.totalDuration } / Double(earlier.count)
        
        if recentAverage > earlierAverage * 1.2 {
            return "📈 使用時間が増加傾向にあります"
        } else if recentAverage < earlierAverage * 0.8 {
            return "📉 使用時間が減少傾向にあります"
        } else {
            return "📊 使用時間は安定しています"
        }
    }
    
    private var trendAdvice: String {
        let average = weeklyAverage
        
        if average > 14400 { // 4時間以上
            return "使用時間が多めです。適度な休憩を取ることをお勧めします。"
        } else if average > 7200 { // 2時間以上
            return "標準的な使用時間です。このペースを維持しましょう。"
        } else {
            return "使用時間は控えめです。デジタルデトックスが上手くいっています！"
        }
    }
    
    // MARK: - ヘルパー関数（互換性のため残存）
    private func formatDistance(_ distance: Double) -> String {
        return usageDataManager.formatDuration(distance)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
            .environmentObject(UsageDataManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
