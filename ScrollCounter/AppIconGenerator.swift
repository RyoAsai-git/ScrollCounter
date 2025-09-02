import SwiftUI

// MARK: - アプリアイコン生成用ビュー
// このビューをシミュレーターで実行し、スクリーンショットを撮って
// 各サイズ（1024x1024、180x180など）にリサイズしてアイコンファイルを作成してください

struct AppIconGenerator: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("ScrollCounter App Icons")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // 各サイズのアイコンを表示
                VStack(spacing: 30) {
                    // 1024x1024 (App Store)
                    VStack(spacing: 10) {
                        Text("1024x1024 (App Store)")
                            .font(.headline)
                        AppIconView(size: 200, showBackground: true)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // 180x180 (iPhone 3x)
                    VStack(spacing: 10) {
                        Text("180x180 (iPhone 3x)")
                            .font(.headline)
                        AppIconView(size: 120, showBackground: true)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // 120x120 (iPhone 2x)
                    VStack(spacing: 10) {
                        Text("120x120 (iPhone 2x)")
                            .font(.headline)
                        AppIconView(size: 80, showBackground: true)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // 87x87 (iPhone 3x Settings)
                    VStack(spacing: 10) {
                        Text("87x87 (iPhone 3x Settings)")
                            .font(.headline)
                        AppIconView(size: 60, showBackground: true)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // 58x58 (iPhone 2x Settings)
                    VStack(spacing: 10) {
                        Text("58x58 (iPhone 2x Settings)")
                            .font(.headline)
                        AppIconView(size: 40, showBackground: true)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                }
                
                Spacer(minLength: 50)
                
                // 使用説明
                VStack(alignment: .leading, spacing: 10) {
                    Text("アイコン作成手順:")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("1. シミュレーターでこの画面を表示")
                    Text("2. 各サイズのアイコンをスクリーンショット")
                    Text("3. 画像編集ソフトで正確なサイズにリサイズ")
                    Text("4. Assets.xcassets/AppIcon.appiconsetに追加")
                    Text("5. Contents.jsonで各ファイル名を指定")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - プレビュー
struct AppIconGenerator_Previews: PreviewProvider {
    static var previews: some View {
        AppIconGenerator()
    }
}
