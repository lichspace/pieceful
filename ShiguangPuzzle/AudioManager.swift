import AVFoundation
import Combine
import Foundation

enum AudioEvent: String {
    case pickup
    case drop
    case snap
    case hint
    case complete
}

final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published private(set) var isMusicPlaying = false

    private var musicPlayer: AVAudioPlayer?
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private let settings = SettingsStore.shared

    private init() {}

    func startMusic() {
        guard settings.musicEnabled else { return }
        if musicPlayer == nil {
            musicPlayer = makePlayer(named: "ambient", fileExtension: "mp3")
            musicPlayer?.numberOfLoops = -1
        }
        musicPlayer?.volume = Float(settings.musicVolume)
        musicPlayer?.play()
        isMusicPlaying = musicPlayer?.isPlaying == true
    }

    func pauseMusic() {
        musicPlayer?.pause()
        isMusicPlaying = false
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        isMusicPlaying = false
    }

    func refreshSettings() {
        musicPlayer?.volume = Float(settings.musicVolume)
        for (name, player) in soundPlayers {
            player.volume = Float(settings.soundVolume) * gain(for: name)
        }
        if settings.musicEnabled {
            if !isMusicPlaying { startMusic() }
        } else {
            pauseMusic()
        }
    }

    func play(_ event: AudioEvent) {
        guard settings.soundEnabled else { return }
        let samples = event == .snap ? ["snap-click", "snap"] : [event.rawValue]
        for name in samples {
            if soundPlayers[name] == nil {
                soundPlayers[name] = makePlayer(named: name)
            }
            guard let player = soundPlayers[name] else { continue }
            player.volume = Float(settings.soundVolume) * gain(for: name)
            player.currentTime = 0
            player.play()
        }
    }

    func pauseAll() {
        musicPlayer?.pause()
        soundPlayers.values.forEach { $0.pause() }
        isMusicPlaying = false
    }

    private func makePlayer(named: String, fileExtension: String = "wav") -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: named, withExtension: fileExtension) else { return nil }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }

    private func gain(for sample: String) -> Float {
        switch sample {
        case "pickup": 0.48
        case "drop": 0.42
        case "snap-click": 0.62
        case "snap": 0.62
        case "hint": 0.46
        case "complete": 0.76
        default: 0.7
        }
    }
}
