# 📚 スクロールチェッカー ドキュメンテーション

## 概要

このディレクトリには、スクロールチェッカーアプリの包括的なドキュメントが含まれています。技術仕様、設計思想、開発ガイドラインなど、プロジェクトに関するあらゆる情報をここで管理しています。

## 📁 ディレクトリ構成

```
docs/
├── README.md                    # このファイル
├── specifications/              # 技術仕様書
│   ├── README.md               # 仕様書目次
│   ├── digital-detox-mode.md   # デジタル休憩モード仕様
│   ├── scroll-conversion-metrics.md  # スクロール換算実績仕様
│   ├── app-architecture.md     # アプリアーキテクチャ仕様
│   └── user-interface.md       # UI/UX仕様
├── api/ (予定)                 # API仕様書
├── testing/ (予定)             # テスト戦略・ガイド
└── design/ (予定)              # デザインガイドライン
```

## 🎯 ドキュメント分類

### 🔧 技術仕様書 ([specifications/](./specifications/))
開発者向けの詳細な技術仕様とシステム設計

#### 主要ドキュメント
- **[デジタル休憩モード仕様](./specifications/digital-detox-mode.md)**: iPhone擬似スリープ機能
- **[スクロール換算実績仕様](./specifications/scroll-conversion-metrics.md)**: 19段階距離換算システム  
- **[アプリアーキテクチャ仕様](./specifications/app-architecture.md)**: MVVM設計・データフロー
- **[ユーザーインターフェース仕様](./specifications/user-interface.md)**: UI/UXデザインシステム

### 📱 機能概要
スクロールチェッカーは、iOSユーザーのデジタルウェルビーイングを促進するアプリです。

#### 核心機能
1. **📊 スクロール計測**: アクセシビリティAPIによるリアルタイム監視
2. **🌿 デジタルデトックス**: インテリジェントな休憩提案・実行支援
3. **📈 使用分析**: 週間チャート・アプリ別統計
4. **🔔 健康通知**: 段階的警告・デトックス促進

#### 技術スタック
```
Frontend: SwiftUI + Swift Charts
Backend: Core Data + UserDefaults  
Architecture: MVVM + ObservableObject
Target: iOS 17.0+, iPhone全機種
```

## 🚀 開発者向けクイックスタート

### 1. 仕様理解
```bash
# まず全体像を把握
docs/specifications/README.md を読む

# 機能別詳細を確認
cd docs/specifications/
ls *.md | xargs -I {} echo "📄 {}"
```

### 2. アーキテクチャ把握
```bash
# システム設計の理解
docs/specifications/app-architecture.md を参照

# データフロー確認
MVVM + ObservableObject パターンを把握
```

### 3. UI/UX設計確認
```bash
# デザインシステム理解
docs/specifications/user-interface.md を確認

# コンポーネント設計把握
カード型UI・タブナビゲーション構成を理解
```

## 📋 開発ワークフロー

### 新機能開発時
1. **仕様確認**: 関連仕様書で要件・制約を確認
2. **設計検討**: アーキテクチャ仕様で影響範囲を評価
3. **UI設計**: インターフェース仕様でデザイン一貫性を確保
4. **実装**: 技術仕様に従った開発
5. **仕様更新**: 変更内容を該当仕様書に反映

### バグ修正時
1. **問題分析**: アーキテクチャ仕様でデータフローを確認
2. **影響調査**: 関連機能の仕様書を横断的にチェック
3. **修正実装**: 仕様に準拠した修正
4. **回帰テスト**: 仕様書記載のテスト項目を実行

## 🎨 デザイン原則

### ユーザーエクスペリエンス
- **健康第一**: デジタルウェルビーイングを最優先
- **直感的操作**: 複雑な設定なしで即座に使用開始
- **段階的フィードバック**: 使用量に応じた適切な警告レベル
- **非強制的**: ユーザーの自主性を尊重

### 技術設計
- **プライバシー重視**: 全データをローカル保存
- **パフォーマンス**: 軽量・高速なレスポンス
- **拡張性**: 将来機能追加に対応可能な設計
- **保守性**: 明確な責務分離・テスタブルな構造

## 📊 プロジェクト状況

### 現在のフェーズ
```
Phase 1: Core Features ✅ 完了
- スクロール計測機能
- デジタル休憩モード  
- 基本UI/UX
- 通知システム

Phase 2: Enhancement (予定)
- Apple Watch連携
- ウィジェット対応
- データエクスポート強化

Phase 3: Intelligence (将来)
- AI使用パターン学習
- パーソナライズ提案
- 健康指標連携
```

### 技術的負債・改善点
- [ ] Unit Test カバレッジ向上（現在: 基本実装のみ）
- [ ] UI Test 自動化（現在: 手動テストのみ）
- [ ] パフォーマンス最適化（大量データ処理）
- [ ] アクセシビリティ対応強化

## 🔗 外部リソース

### Apple公式ドキュメント
- [SwiftUI Framework](https://developer.apple.com/documentation/swiftui)
- [Core Data Framework](https://developer.apple.com/documentation/coredata)
- [Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### 参考実装・ライブラリ
- [Swift Charts](https://developer.apple.com/documentation/charts): グラフ表示
- [UserNotifications](https://developer.apple.com/documentation/usernotifications): 通知機能

## 📞 サポート・コントリビューション

### 質問・提案
- **機能要望**: Enhancement Issue として提案
- **バグ報告**: Bug Report テンプレートを使用
- **仕様質問**: Discussion で議論

### ドキュメント改善
- **誤字・脱字**: 軽微な修正は直接PR
- **内容追加**: Issue で議論後にPR作成
- **構造変更**: 事前にDiscussionで合意形成

---

## 📈 メトリクス

| 項目 | 現在値 | 目標値 |
|------|--------|--------|
| 仕様書カバレッジ | 95% | 100% |
| ドキュメント鮮度 | 7日以内 | 3日以内 |
| 開発者オンボーディング時間 | 2時間 | 1時間 |

---

**最終更新**: 2025年8月31日  
**ドキュメントメンテナ**: スクロールチェッカー開発チーム  
**レビューサイクル**: 毎リリース時 + 月次定期更新
