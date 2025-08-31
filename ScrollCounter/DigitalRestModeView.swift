import SwiftUI
import UIKit

// MARK: - デジタル休憩モード画面
struct DigitalRestModeView: View {
    @State private var timeRemaining: Int
    @State private var isActive = true
    @State private var timer: Timer?
    @State private var originalBrightness: CGFloat = 0.5
    @Binding var isPresented: Bool
    
    let restDuration: Int // 分単位
    
    init(restDuration: Int, isPresented: Binding<Bool>) {
        self.restDuration = restDuration
        self._timeRemaining = State(initialValue: restDuration * 60) // 秒に変換
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // 暗い背景（画面を暗くする効果）
            Color.black
                .ignoresSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                // デトックスアイコン
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 10)
                
                // タイトル
                Text("デジタル休憩中")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // 残り時間表示
                Text(formatTime(timeRemaining))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 5)
                
                // 休憩メッセージ
                VStack(spacing: 15) {
                    Text("目を休めて、深呼吸をしましょう")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("👀 遠くを見つめる\n🧘‍♀️ 軽いストレッチ\n💧 水分補給")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 早期終了ボタン
                VStack(spacing: 15) {
                    Button("休憩を終了") {
                        endRestMode()
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    
                    Text("推奨休憩時間: \(restDuration)分")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startRestMode()
        }
        .onDisappear {
            restoreBrightness()
            timer?.invalidate()
        }
        .preferredColorScheme(.dark) // ダークモード強制
    }
    
    // MARK: - 休憩モード開始
    private func startRestMode() {
        // 現在の明度を保存
        originalBrightness = UIScreen.main.brightness
        
        // 画面を暗くする
        UIScreen.main.brightness = 0.1
        
        // タイマー開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // 時間終了
                endRestMode()
            }
        }
        
        // 画面をアクティブに保つ（スリープ防止）
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // MARK: - 休憩モード終了
    private func endRestMode() {
        timer?.invalidate()
        restoreBrightness()
        UIApplication.shared.isIdleTimerDisabled = false
        
        // デトックス完了メッセージ
        if timeRemaining <= 0 {
            // 完了通知を表示（実装可能）
            showCompletionMessage()
        }
        
        isPresented = false
    }
    
    // MARK: - 明度復元
    private func restoreBrightness() {
        // 元の明度に戻す（少し遅延を入れて自然に）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIScreen.main.brightness = originalBrightness
        }
    }
    
    // MARK: - 時間フォーマット
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - 完了メッセージ
    private func showCompletionMessage() {
        let alert = UIAlertController(
            title: "休憩完了！🎉",
            message: "お疲れさまでした。\n引き続き健康的なデジタルライフを心がけましょう。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - プレビュー
struct DigitalRestModeView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalRestModeView(restDuration: 5, isPresented: .constant(true))
    }
}
