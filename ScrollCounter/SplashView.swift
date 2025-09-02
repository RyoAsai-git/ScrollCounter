import SwiftUI

// MARK: - スプラッシュ画面
struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var canSkip = false
    @Binding var isActive: Bool
    
    var body: some View {
        if showMainApp {
            ContentView()
                .transition(.opacity)
        } else {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.98, blue: 0.97), // 非常に薄いミントグリーン
                        Color(red: 0.92, green: 0.96, blue: 0.94)  // 薄いグリーン
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // アプリアイコン
                    AppIconView(size: 120, showBackground: true)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: isAnimating)
                    
                    // アプリ名
                    VStack(spacing: 8) {
                        Text("ScrollCounter")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)
                        
                        Text("デジタルデトックスをサポート")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: isAnimating)
                    }
                    
                    Spacer()
                    
                    // ローディングインジケーター
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.8, blue: 0.6)))
                            .scaleEffect(0.8)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.6), value: isAnimating)
                        
                        Text("アプリを準備中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.7), value: isAnimating)
                    }
                    .padding(.bottom, 50)
                }
            }
            .onTapGesture {
                // タップでスキップ（0.8秒後から可能）
                if canSkip {
                    skipSplash()
                }
            }
            .onAppear {
                // アニメーション開始
                isAnimating = true
                
                // 0.8秒後からタップでスキップ可能
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    canSkip = true
                }
                
                // 1.5秒後にメインアプリに自動遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    skipSplash()
                }
            }
        }
    }
    
    // MARK: - スキップ機能
    private func skipSplash() {
        withAnimation(.easeInOut(duration: 0.4)) {
            showMainApp = true
        }
    }
}

// MARK: - プレビュー
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(isActive: .constant(true))
    }
}
