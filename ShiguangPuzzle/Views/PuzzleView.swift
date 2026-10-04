import SpriteKit
import SwiftUI

struct PuzzleView: View {
    let definition: PuzzleDefinition
    let difficulty: Difficulty

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var viewModel: PuzzleGameViewModel
    @State private var scene: PuzzleBoardScene
    @State private var showingResult = false
    @State private var showingReference = false

    init(definition: PuzzleDefinition, difficulty: Difficulty) {
        self.definition = definition
        self.difficulty = difficulty
        _viewModel = StateObject(wrappedValue: PuzzleGameViewModel(definition: definition, difficulty: difficulty))
        _scene = State(initialValue: PuzzleBoardScene(size: CGSize(width: 900, height: 640)))
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 680
            let wide = proxy.size.width >= 1100
            ZStack {
                HomeBackdrop()
                VStack(spacing: compact ? 7 : 9) {
                    header(compact: compact, wide: wide)
                    GeometryReader { canvasProxy in
                        SpriteView(scene: scene, options: [.allowsTransparency])
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: compact ? 20 : 28, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: compact ? 20 : 28, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: 1)
                                    .allowsHitTesting(false)
                            }
                            .shadow(color: AppPalette.shadow.opacity(0.12), radius: 24, y: 12)
                            .overlay {
                                if viewModel.isPaused {
                                    PauseOverlay(resume: viewModel.togglePause)
                                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                }
                            }
                            .onAppear { viewModel.attach(scene: scene); viewModel.resizeScene(to: canvasProxy.size) }
                            .onChange(of: canvasProxy.size) { newSize in viewModel.resizeScene(to: newSize) }
                    }

                }
                .padding(.horizontal, compact ? 12 : 26)
                .padding(.top, compact ? 6 : 10)
                .padding(.bottom, compact ? 6 : 10)

                if showingReference {
                    ReferenceArtworkOverlay(definition: definition) { showingReference = false }
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showingReference)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onChange(of: viewModel.isComplete) { complete in
            guard complete else { return }
            showingReference = false
            showingResult = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .puzzleTogglePause)) { _ in viewModel.togglePause() }
        .onReceive(NotificationCenter.default.publisher(for: .puzzleHint)) { _ in viewModel.hint() }
        .onReceive(NotificationCenter.default.publisher(for: .puzzleRestart)) { _ in
            guard !showingResult else { return }
            viewModel.restart()
        }
        .onReceive(NotificationCenter.default.publisher(for: .puzzleAppDidBackground)) { _ in viewModel.appDidEnterBackground() }
        .onReceive(NotificationCenter.default.publisher(for: .puzzleAppDidBecomeActive)) { _ in viewModel.appDidBecomeActive() }
        #if os(macOS)
        .onExitCommand {
            if showingReference { showingReference = false }
            else if viewModel.isPaused { viewModel.togglePause() }
            else { dismiss() }
        }
        #endif
        .sheet(isPresented: $showingResult, onDismiss: { dismiss() }) {
            ResultView(definition: definition, session: viewModel.session) { showingResult = false }
        }
        .onDisappear { viewModel.stop() }
        .environmentObject(settings)
    }

    private func header(compact: Bool, wide: Bool) -> some View {
        Group {
            if wide {
                HStack(spacing: 8) {
                    backButton
                    titleBlock(compact: compact)
                    stats
                    Spacer(minLength: 2)
                    trayAndGameControls(compact: true)
                    referenceButton
                    pauseButton
                }
            } else {
                VStack(spacing: 5) {
                    HStack(spacing: 8) {
                        backButton
                        titleBlock(compact: compact)
                        Spacer(minLength: 2)
                        if !compact { stats }
                        referenceButton
                        pauseButton
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if compact { stats }
                            trayAndGameControls(compact: true)
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 7 : 8)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(AppPalette.border, lineWidth: 1))
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppPalette.text)
                .frame(width: 36, height: 36)
                .background(AppPalette.surfaceSoft, in: Circle())
                .overlay(Circle().stroke(AppPalette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("返回")
    }

    private func titleBlock(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(definition.title)
                .font(.system(size: compact ? 15 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.text)
                .lineLimit(1)
            if !compact {
                Text("\(definition.category.title)  ·  \(difficulty.rawValue)片")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.secondary)
            }
        }
        .frame(minWidth: compact ? 0 : 120, alignment: .leading)
    }

    private var referenceButton: some View {
        GameToolButton(title: "原图", symbol: "photo", compact: true) { showingReference = true }
    }

    private var pauseButton: some View {
        GameToolButton(title: viewModel.isPaused ? "继续" : "暂停", symbol: viewModel.isPaused ? "play.fill" : "pause.fill", compact: true) {
            viewModel.togglePause()
        }
        .keyboardShortcut(.space, modifiers: [])
    }

    private func trayAndGameControls(compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 8) {
            trayStatus(compact: compact)
            trayPagingControls
            recoverPiecesButton(compact: compact)
            Rectangle().fill(AppPalette.border).frame(width: 1, height: 24)
            GameToolButton(title: "提示", symbol: "sparkle", compact: compact) { viewModel.hint() }
                .keyboardShortcut("h", modifiers: [])
            GameToolButton(title: "重新开始", symbol: "arrow.counterclockwise", compact: compact) { viewModel.restart() }
                .keyboardShortcut("r", modifiers: [])
                .keyboardShortcut("r", modifiers: [.command])
            Rectangle().fill(AppPalette.border).frame(width: 1, height: 24)
            GameToolButton(title: "缩小", symbol: "minus.magnifyingglass", compact: true) { viewModel.zoom(by: 0.82) }
            GameToolButton(title: "适应", symbol: "arrow.up.left.and.arrow.down.right", compact: true) { viewModel.resetZoom() }
            GameToolButton(title: "放大", symbol: "plus.magnifyingglass", compact: true) { viewModel.zoom(by: 1.22) }
        }
    }

    private var stats: some View {
        HStack(spacing: 9) {
            Label(viewModel.elapsedText, systemImage: "clock")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
            Text("\(viewModel.session.placedCount)/\(difficulty.rawValue)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppPalette.accent)
        }
        .foregroundStyle(AppPalette.text)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(AppPalette.surfaceSoft, in: Capsule())
    }

    private func trayStatus(compact: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "square.grid.2x2.fill")
            if compact {
                Text(viewModel.usesScrollableTray ? "托盘" : "\(viewModel.trayPage + 1)/\(viewModel.trayPageCount)")
            } else {
                Text("碎片托盘")
                Text(viewModel.usesScrollableTray ? trayScrollInstruction : "\(viewModel.trayPage + 1)/\(viewModel.trayPageCount)")
                    .foregroundStyle(AppPalette.accent)
            }
        }
        .font(.system(size: compact ? 12 : 14, weight: .semibold, design: .rounded))
        .foregroundStyle(AppPalette.text)
    }

    @ViewBuilder
    private var trayPagingControls: some View {
        if !viewModel.usesScrollableTray {
            GameToolButton(title: "上一组", symbol: "chevron.left", compact: true) { viewModel.changeTrayPage(by: -1) }
                .disabled(viewModel.trayPage == 0)
            GameToolButton(title: "下一组", symbol: "chevron.right", compact: true) { viewModel.changeTrayPage(by: 1) }
                .disabled(viewModel.trayPage >= viewModel.trayPageCount - 1)
        }
    }

    private func recoverPiecesButton(compact: Bool) -> some View {
        let count = viewModel.loosePieceCount
        let disabled = count == 0 || viewModel.isPaused || viewModel.isComplete
        return GameToolButton(title: count > 0 ? "收回散片 \(count)" : "收回散片", symbol: "tray.and.arrow.down", compact: compact) {
            viewModel.recoverLoosePieces()
        }
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
        .accessibilityLabel("收回散片")
        .accessibilityValue("\(count) 片")
        .accessibilityHint("将未归位的碎片收回托盘，保留已经拼好的部分")
        .help("将未归位的碎片收回托盘，保留已经拼好的部分")
    }

    private var trayScrollInstruction: String {
        #if os(macOS)
        "滚轮/双指/箭头选片"
        #else
        "滑动/双指/箭头选片 · 长按拖动"
        #endif
    }
}

private struct GameToolButton: View {
    let title: String
    let symbol: String
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                if !compact { Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)) }
            }
            .foregroundStyle(AppPalette.text)
            .frame(minWidth: compact ? 36 : nil, minHeight: 36)
            .padding(.horizontal, compact ? 5 : 12)
            .background(AppPalette.surfaceSoft, in: Capsule())
            .overlay(Capsule().stroke(AppPalette.border, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(GameToolButtonStyle())
        .help(title)
        .accessibilityLabel(title)
    }
}

private struct GameToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .brightness(configuration.isPressed ? 0.07 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.56), value: configuration.isPressed)
    }
}

private struct ReferenceArtworkOverlay: View {
    let definition: PuzzleDefinition
    let close: () -> Void

    var body: some View {
        ZStack {
            AppPalette.text.opacity(0.28).ignoresSafeArea().onTapGesture(perform: close)
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("原图参考").font(.headline.weight(.bold))
                        Text(definition.title).font(.subheadline).foregroundStyle(AppPalette.secondary)
                    }
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 34, height: 34)
                            .background(AppPalette.border, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("关闭原图")
                }
                Image(definition.imageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppPalette.border, lineWidth: 1))
            }
            .foregroundStyle(AppPalette.text)
            .padding(18)
            .frame(maxWidth: 1000, maxHeight: 800)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppPalette.border, lineWidth: 1))
            .shadow(color: AppPalette.shadow.opacity(0.18), radius: 30, y: 16)
            .padding(24)
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct PauseOverlay: View {
    let resume: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(AppPalette.accent)
            Text("歇一会儿")
                .font(.system(size: 23, weight: .bold, design: .rounded))
            Text("拼图已暂停，准备好后继续。")
                .font(.subheadline)
                .foregroundStyle(AppPalette.secondary)
            Button(action: resume) {
                Label("继续拼图", systemImage: "play.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(AppPalette.peach, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 3)
        }
        .foregroundStyle(AppPalette.text)
        .padding(.horizontal, 34)
        .padding(.vertical, 30)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(AppPalette.border, lineWidth: 1))
        .shadow(color: AppPalette.shadow.opacity(0.16), radius: 26, y: 12)
    }
}
