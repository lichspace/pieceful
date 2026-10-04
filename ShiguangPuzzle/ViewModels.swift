import Combine
import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
final class PuzzleGameViewModel: ObservableObject {
    let definition: PuzzleDefinition
    let difficulty: Difficulty

    @Published private(set) var session: PuzzleSession
    @Published var isPaused = false
    @Published private(set) var isComplete = false
    @Published private(set) var hintedPieceID: String?
    @Published private(set) var trayPage = 0
    @Published private(set) var trayPageCount = 1
    @Published private(set) var usesScrollableTray = false

    private var engine: PuzzleEngine
    private var timer: AnyCancellable?
    private var startedAt = Date()
    private var elapsedAtStart = 0
    private weak var scene: PuzzleBoardScene?
    private let saveStore = SaveStore.shared
    private let audio = AudioManager.shared
    private let settings = SettingsStore.shared

    init(definition: PuzzleDefinition, difficulty: Difficulty) {
        self.definition = definition
        self.difficulty = difficulty
        let stored = SaveStore.shared.loadSession(puzzleID: definition.id, difficulty: difficulty)
        if stored?.isComplete == true {
            SaveStore.shared.deleteSession(puzzleID: definition.id, difficulty: difficulty)
        }
        let restored = stored?.isComplete == true ? nil : stored
        let initial = restored ?? PuzzleLayoutGenerator.makeSession(puzzleID: definition.id, difficulty: difficulty)
        session = initial
        engine = PuzzleEngine(session: initial)
        elapsedAtStart = initial.elapsedMilliseconds
        startedAt = Date()
    }

    var elapsedText: String {
        let totalSeconds = session.elapsedMilliseconds / 1000
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var loosePieceCount: Int { session.looseBoardPieces.count }

    func recoverLoosePieces() {
        guard !isPaused, !isComplete else { return }
        guard !engine.recoverLoosePieces().isEmpty else { return }
        session = engine.session
        trayPage = 0
        scene?.resetTrayScroll()
        renderScene()
        audio.play(.drop)
        save()
    }

    func attach(scene: PuzzleBoardScene) {
        self.scene = scene
        scene.onDrop = { [weak self] pieceID, current, target in
            Task { @MainActor in
                self?.drop(pieceID: pieceID, at: current, target: target)
            }
        }
        scene.onPickup = { [weak self] in
            self?.audio.play(.pickup)
            #if os(iOS)
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.prepare()
            feedback.impactOccurred()
            #endif
        }
        scene.onTrayPageChanged = { [weak self] page, count, scrollable in
            self?.trayPage = page
            self?.trayPageCount = count
            self?.usesScrollableTray = scrollable
        }
        if isComplete || session.isComplete {
            // Navigation can reuse the prior view model after finishing a game.
            // Treat entering that completed board as a fresh start.
            restart()
            return
        }
        scene.setInputEnabled(!isPaused)
        renderScene()
        startTimer()
    }

    func resizeScene(to size: CGSize) {
        scene?.resize(to: size)
    }

    func changeTrayPage(by offset: Int) {
        guard !usesScrollableTray, trayPageCount > 1 else { return }
        let next = min(trayPageCount - 1, max(0, trayPage + offset))
        guard next != trayPage else { return }
        trayPage = next
        renderScene()
    }

    func zoom(by factor: CGFloat) { scene?.zoom(by: factor) }
    func resetZoom() { scene?.resetZoom() }

    func togglePause() {
        guard !isComplete else { return }
        isPaused.toggle()
        scene?.setInputEnabled(!isPaused)
        if isPaused {
            updateElapsed()
            elapsedAtStart = session.elapsedMilliseconds
            startedAt = Date()
            audio.pauseMusic()
            save()
        } else {
            elapsedAtStart = session.elapsedMilliseconds
            startedAt = Date()
            audio.refreshSettings()
        }
    }

    func drop(pieceID: String, at position: CGPoint, target: CGPoint) {
        guard !isPaused, !isComplete else { return }
        guard let result = engine.movePiece(id: pieceID, to: position, target: target) else { return }
        session = engine.session
        renderScene()
        audio.play(result.didSnap ? .snap : .drop)
        scene?.dropFeedback(for: pieceID, snapped: result.didSnap)
        #if os(iOS)
        let feedback = UIImpactFeedbackGenerator(style: result.didSnap ? .medium : .soft)
        feedback.prepare()
        feedback.impactOccurred()
        #endif
        if result.didSnap {
            if result.didComplete {
                finish()
            }
        }
        save()
    }

    func hint() {
        guard !isPaused, !isComplete else { return }
        engine.registerHint()
        session = engine.session
        hintedPieceID = session.pieces.first(where: { $0.isInTray })?.id
            ?? session.pieces.first(where: { !$0.isPlaced })?.id
        if let hintedPieceID {
            audio.play(.hint)
            scene?.showPieceInTray(hintedPieceID)
            scene?.pulseHint(for: hintedPieceID)
        }
        save()
    }

    func restart() {
        timer?.cancel()
        saveStore.deleteSession(puzzleID: definition.id, difficulty: difficulty)
        let fresh = PuzzleLayoutGenerator.makeSession(puzzleID: definition.id, difficulty: difficulty)
        engine = PuzzleEngine(session: fresh)
        session = fresh
        isPaused = false
        isComplete = false
        scene?.setInputEnabled(true)
        scene?.resetTrayScroll()
        hintedPieceID = nil
        trayPage = 0
        elapsedAtStart = 0
        startedAt = Date()
        renderScene()
        startTimer()
        audio.refreshSettings()
    }

    func save() {
        updateElapsed()
        saveStore.save(session: session)
    }

    func stop() {
        save()
        timer?.cancel()
        timer = nil
        scene?.setInputEnabled(false)
        audio.pauseMusic()
    }

    func appDidEnterBackground() {
        scene?.setInputEnabled(false)
        updateElapsed()
        elapsedAtStart = session.elapsedMilliseconds
        startedAt = Date()
        save()
        timer?.cancel()
        audio.pauseAll()
    }

    func appDidBecomeActive() {
        guard !isPaused, !isComplete else { return }
        scene?.setInputEnabled(true)
        startTimer()
    }

    private func startTimer() {
        timer?.cancel()
        startedAt = Date()
        timer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.isPaused, !self.isComplete else { return }
                self.updateElapsed()
            }
        audio.startMusic()
    }

    private func renderScene() {
        scene?.render(
            session: session,
            definition: definition,
            effectsEnabled: settings.effectsEnabled,
            trayPage: trayPage
        )
    }

    private func updateElapsed() {
        guard !isPaused, !isComplete else { return }
        let current = elapsedAtStart + Int(Date().timeIntervalSince(startedAt) * 1000)
        engine.updateElapsed(milliseconds: current)
        session = engine.session
    }

    private func finish() {
        updateElapsed()
        isComplete = true
        scene?.setInputEnabled(false)
        timer?.cancel()
        audio.play(.complete)
        scene?.celebrate()
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif

        var progress = saveStore.loadProgress()
        progress.markCompleted(
            puzzleID: definition.id,
            difficulty: difficulty,
            elapsedMilliseconds: session.elapsedMilliseconds
        )
        saveStore.saveProgress(progress)
        save()
    }
}
