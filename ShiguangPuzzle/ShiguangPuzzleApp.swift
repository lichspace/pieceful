import SwiftUI

@main
struct ShiguangPuzzleApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(AppPalette.accent)
                .preferredColorScheme(.light)
                .environmentObject(settings)
                .onChange(of: scenePhase) { phase in
                    if phase == .background || phase == .inactive {
                        AudioManager.shared.pauseAll()
                        NotificationCenter.default.post(name: .puzzleAppDidBackground, object: nil)
                    } else if phase == .active {
                        NotificationCenter.default.post(name: .puzzleAppDidBecomeActive, object: nil)
                    }
                }
        }
        #if os(macOS)
        .commands {
            CommandMenu("拼图") {
                Button("暂停 / 继续") {
                    NotificationCenter.default.post(name: .puzzleTogglePause, object: nil)
                }
                .keyboardShortcut(" ", modifiers: [])

                Button("显示提示") {
                    NotificationCenter.default.post(name: .puzzleHint, object: nil)
                }
                .keyboardShortcut("h", modifiers: [])

                Button("重新开始") {
                    NotificationCenter.default.post(name: .puzzleRestart, object: nil)
                }
                .keyboardShortcut("r", modifiers: [])

                Button("重新开始当前关卡") {
                    NotificationCenter.default.post(name: .puzzleRestart, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
        #endif
    }
}

extension Notification.Name {
    static let puzzleTogglePause = Notification.Name("shiguang.puzzle.togglePause")
    static let puzzleHint = Notification.Name("shiguang.puzzle.hint")
    static let puzzleRestart = Notification.Name("shiguang.puzzle.restart")
    static let puzzleAppDidBackground = Notification.Name("shiguang.puzzle.appDidBackground")
    static let puzzleAppDidBecomeActive = Notification.Name("shiguang.puzzle.appDidBecomeActive")
}
