# ユーザーインターフェース仕様書

## UI/UX設計思想

スクロールチェッカーは「デジタルウェルビーイング」を促進するアプリとして、健康的で直感的なインターフェースを提供します。過度な刺激を避け、落ち着いた配色と明確な情報階層でユーザーの安心感を重視します。

## デザインシステム

### 🎨 カラーパレット

#### プライマリカラー
```swift
primary: .blue           // メイン操作要素
secondary: .green        // ヘルス・ウェルビーイング
accent: .orange          // 注意・警告
background: .systemBackground  // 背景
```

#### セマンティックカラー
```swift
// 健康レベル表示
healthy: .green          // 適度な使用（<1km）
moderate: .orange        // 注意が必要（1-5km）
warning: .red            // 警告レベル（5km+）
critical: .purple        // 緊急レベル（10km+）
```

#### ダークモード対応
```swift
// 自動切り替え対応
primary: .primary        // システム設定に追従
background: .systemBackground
text: .primary
secondaryText: .secondary
```

### 📏 レイアウトシステム

#### グリッドシステム
```swift
// 標準余白
margin: 16pt             // 画面端からの余白
padding: 12pt            // カード内余白
spacing: 8pt             // 要素間隔
cardRadius: 12pt         // カード角丸
```

#### タイポグラフィ
```swift
// 見出し階層
largeTitle: .largeTitle  // 32pt, Bold
title: .title            // 28pt, Bold  
headline: .headline      // 17pt, Semibold
body: .body              // 17pt, Regular
caption: .caption        // 12pt, Regular
```

## 画面構成設計

### 📱 タブ構成

```
TabView {
    DashboardView()      // 📊 ダッシュボード（メイン）
    ChartView()          // 📈 履歴・グラフ
    SettingsView()       // ⚙️ 設定
}
```

### 🏠 DashboardView（メイン画面）

#### 画面構成
```
┌─────────────────────────────┐
│   📊 スクロール距離          │  ← NavigationTitle
├─────────────────────────────┤
│  💙 今日の総距離             │  ← TotalDistanceCard
│     1,234m                  │
│  📈 昨日より +123m          │
├─────────────────────────────┤
│  💚 健康アドバイス           │  ← MotivationCard
│  適度なスクロール量を        │
│  キープしています           │
├─────────────────────────────┤
│  🏆 アプリ別ランキング       │  ← AppRankingCard
│  [今日] [歴代]              │
│  1. Safari      456m       │
│  2. Twitter     234m       │
│  3. Instagram   123m       │
├─────────────────────────────┤
│  ⚠️ デジタル使用状況         │  ← DigitalDetoxCard
│  📱🤔 1km分のスクロール...  │
│  ちょっと多くないですか？    │
│              [デトックス開始] │
└─────────────────────────────┘
```

#### カードコンポーネント設計

##### TotalDistanceCard
```swift
struct TotalDistanceCard: View {
    // 表示要素
    - 今日の総距離（大きく表示）
    - 昨日との比較（差分表示）
    - 視覚的プログレスバー
    - アニメーション効果
}
```

##### MotivationCard
```swift
struct MotivationCard: View {
    // 表示要素
    - 健康アドバイスメッセージ
    - 使用量に応じた動的メッセージ
    - ヘルスケアアイコン
    - 励ましトーン
}
```

##### AppRankingCard
```swift
struct AppRankingCard: View {
    // 表示要素
    - 今日/歴代 切り替えタブ
    - アプリ別ランキング（TOP5）
    - アプリアイコン + 距離
    - スクロール可能リスト
}
```

##### DigitalDetoxCard
```swift
struct DigitalDetoxCard: View {
    // 表示要素
    - 現在の使用状況分析
    - 健康リスク警告
    - デトックス開始ボタン
    - 段階的警告色
}
```

### 📈 ChartView（履歴画面）

#### 画面構成
```
┌─────────────────────────────┐
│   📈 スクロール履歴          │  ← NavigationTitle
├─────────────────────────────┤
│      週間スクロール推移      │  ← チャートタイトル
│                             │
│   │     ██                 │  ← 棒グラフ
│   │   ████                 │
│   │ ██████                 │
│   │████████               │
│   └─────────────────────   │
│    月 火 水 木 金 土 日     │
├─────────────────────────────┤
│  📊 統計情報                │  ← 統計カード
│  平均: 1,234m              │
│  最高: 2,345m              │
│  合計: 8,642m              │
├─────────────────────────────┤
│  💡 アドバイス              │  ← 傾向分析
│  今週は平日の使用量が       │
│  多めです。休憩を心がけ      │
│  ましょう。                │
└─────────────────────────────┘
```

#### チャート仕様
```swift
// Swift Charts使用
Chart(weeklyData, id: \.date) { item in
    BarMark(
        x: .value("日", item.formattedDate),
        y: .value("距離", item.totalDistance)
    )
    .foregroundStyle(barColor(for: item.totalDistance))
}
.chartYAxis {
    AxisMarks(position: .leading)
}
.chartXAxis {
    AxisMarks(position: .bottom)
}
```

### ⚙️ SettingsView（設定画面）

#### 画面構成
```
┌─────────────────────────────┐
│   ⚙️ 設定                   │  ← NavigationTitle
├─────────────────────────────┤
│  🔔 通知設定                │  ← セクション1
│  通知を有効にする    [ON]   │
│  通知時刻          21:00   │
│  デトックス通知    [ON]   │
├─────────────────────────────┤
│  📱 アクセシビリティ        │  ← セクション2
│  権限ステータス    ✅許可済み │
│  [設定アプリで確認]         │
├─────────────────────────────┤
│  📊 データ管理              │  ← セクション3
│  [データをエクスポート]      │
│  [データをリセット]         │
├─────────────────────────────┤
│  ℹ️ アプリ情報              │  ← セクション4
│  バージョン 1.0.0          │
│  [プライバシーポリシー]      │
│  [サポート]                │
└─────────────────────────────┘
```

#### 設定項目詳細
```swift
// 通知設定
@State private var isNotificationEnabled: Bool
@State private var notificationTime: Date  
@State private var detoxNotificationsEnabled: Bool

// データ管理
func exportData() { /* CSV/JSON出力 */ }
func resetData() { /* 確認ダイアログ + 削除 */ }
```

## インタラクション設計

### 🔄 アニメーション仕様

#### カード表示アニメーション
```swift
.transition(.slide.combined(with: .opacity))
.animation(.easeInOut(duration: 0.3), value: isVisible)
```

#### 数値カウントアップ
```swift
// 距離表示のカウントアップアニメーション
Text("\(animatedDistance, specifier: "%.0f")m")
    .contentTransition(.numericText())
    .animation(.easeOut(duration: 1.0), value: totalDistance)
```

#### プルトゥリフレッシュ
```swift
ScrollView {
    LazyVStack { /* カード群 */ }
}
.refreshable {
    await scrollDataManager.refreshData()
}
```

### 🎯 ジェスチャー対応

#### スワイプジェスチャー
```swift
// アプリランキングカードのスワイプ切り替え
.swipeActions(edge: .trailing) {
    Button("詳細") { /* 詳細表示 */ }
}
```

#### ロングプレス
```swift
// カードの詳細表示
.onLongPressGesture {
    showDetailView = true
}
```

## アクセシビリティ設計

### ♿ VoiceOver対応

#### セマンティック設定
```swift
.accessibilityLabel("今日のスクロール距離")
.accessibilityValue("\(totalDistance)メートル")
.accessibilityHint("タップして詳細を表示")
.accessibilityAddTraits(.isButton)
```

#### フォーカス管理
```swift
@AccessibilityFocusState private var isFocused: Bool

Button("デトックス開始") { /* 処理 */ }
    .accessibilityFocused($isFocused)
```

### 🔤 Dynamic Type対応

#### スケーラブルフォント
```swift
Text("タイトル")
    .font(.headline)  // システムフォント使用
    .lineLimit(nil)   // 複数行対応
```

#### レイアウト調整
```swift
@Environment(\.sizeCategory) var sizeCategory

var isAccessibilitySize: Bool {
    sizeCategory >= .accessibilityMedium
}
```

## レスポンシブデザイン

### 📐 画面サイズ対応

#### デバイス別最適化
```swift
// iPhone SE対応
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var isCompact: Bool {
    horizontalSizeClass == .compact
}

// レイアウト調整
if isCompact {
    VStack { /* 縦並び */ }
} else {
    HStack { /* 横並び */ }
}
```

#### セーフエリア対応
```swift
VStack {
    // コンテンツ
}
.padding(.horizontal, 16)
.padding(.top, 8)
.ignoresSafeArea(.keyboard, edges: .bottom)
```

## エラー状態の設計

### ⚠️ エラーハンドリング

#### データ読み込みエラー
```swift
if scrollDataManager.isLoading {
    ProgressView("データを読み込み中...")
} else if scrollDataManager.hasError {
    ErrorView(error: scrollDataManager.error)
} else {
    // 正常表示
}
```

#### 権限エラー
```swift
if !accessibilityPermission {
    PermissionRequestView()
} else {
    // メインコンテンツ
}
```

### 🔄 ローディング状態

#### スケルトンローディング
```swift
struct SkeletonCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 120)
            .redacted(reason: .placeholder)
    }
}
```

## パフォーマンス最適化

### ⚡ レンダリング最適化

#### LazyLoading
```swift
LazyVStack(spacing: 12) {
    ForEach(items) { item in
        CardView(item: item)
    }
}
```

#### 条件付きレンダリング
```swift
if shouldShowChart {
    ChartView()
        .transition(.opacity)
}
```

### 🧠 メモリ効率

#### 画像キャッシュ
```swift
// システムアイコン使用でメモリ効率化
Image(systemName: "chart.bar.fill")
```

#### State最小化
```swift
// 必要最小限のState保持
@State private var showingDetail = false
// 不要: @State private var unnecessaryData = []
```

---

## 更新履歴

| バージョン | 日付 | 変更内容 |
|------------|------|----------|
| 1.0.0 | 2025-08-31 | 初版UI仕様策定 |
