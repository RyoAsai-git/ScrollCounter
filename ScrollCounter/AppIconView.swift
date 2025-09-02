import SwiftUI

// MARK: - アプリアイコンビュー
struct AppIconView: View {
    let size: CGFloat
    let showBackground: Bool
    
    init(size: CGFloat = 120, showBackground: Bool = true) {
        self.size = size
        self.showBackground = showBackground
    }
    
    var body: some View {
        ZStack {
            if showBackground {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.8, blue: 0.6), // ミントグリーン
                        Color(red: 0.1, green: 0.7, blue: 0.4)  // 深いグリーン
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            }
            
            // メインアイコン要素
            VStack(spacing: size * 0.05) {
                // 上部：デジタルデトックスを表現する葉っぱ
                Image(systemName: "leaf.fill")
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // 下部：時間/使用量を表現するシンプルなバー
                HStack(spacing: size * 0.03) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: size * 0.015)
                            .fill(Color.white.opacity(0.9))
                            .frame(
                                width: size * 0.08,
                                height: size * (0.15 - Double(index) * 0.03)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - プレビュー
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 通常サイズ
            AppIconView(size: 120)
            
            // 小さいサイズ
            AppIconView(size: 60)
            
            // 背景なし
            AppIconView(size: 120, showBackground: false)
                .background(Color.gray.opacity(0.2))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
