import Combine
import Foundation

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var musicEnabled: Bool { didSet { persist() } }
    @Published var soundEnabled: Bool { didSet { persist() } }
    @Published var effectsEnabled: Bool { didSet { persist() } }
    @Published var musicVolume: Double { didSet { persist() } }
    @Published var soundVolume: Double { didSet { persist() } }

    private let defaults = UserDefaults.standard

    private init() {
        musicEnabled = defaults.object(forKey: "shiguang.musicEnabled") as? Bool ?? true
        soundEnabled = defaults.object(forKey: "shiguang.soundEnabled") as? Bool ?? true
        effectsEnabled = defaults.object(forKey: "shiguang.effectsEnabled") as? Bool ?? true
        musicVolume = defaults.object(forKey: "shiguang.musicVolume") as? Double ?? 0.28
        soundVolume = defaults.object(forKey: "shiguang.soundVolume") as? Double ?? 0.7
    }

    private func persist() {
        defaults.set(musicEnabled, forKey: "shiguang.musicEnabled")
        defaults.set(soundEnabled, forKey: "shiguang.soundEnabled")
        defaults.set(effectsEnabled, forKey: "shiguang.effectsEnabled")
        defaults.set(musicVolume, forKey: "shiguang.musicVolume")
        defaults.set(soundVolume, forKey: "shiguang.soundVolume")
    }
}
