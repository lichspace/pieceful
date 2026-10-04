import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("声音") {
                    Toggle("配乐", isOn: $settings.musicEnabled)
                        .onChange(of: settings.musicEnabled) { _ in AudioManager.shared.refreshSettings() }
                    Slider(value: $settings.musicVolume, in: 0...1) {
                        Text("配乐音量")
                    }
                    .onChange(of: settings.musicVolume) { _ in AudioManager.shared.refreshSettings() }
                    .disabled(!settings.musicEnabled)

                    Toggle("音效", isOn: $settings.soundEnabled)
                    Slider(value: $settings.soundVolume, in: 0...1) {
                        Text("音效音量")
                    }
                    .onChange(of: settings.soundVolume) { _ in AudioManager.shared.refreshSettings() }
                    .disabled(!settings.soundEnabled)
                }
                .listRowBackground(AppPalette.surface)

                Section("视觉") {
                    Toggle("拼图特效", isOn: $settings.effectsEnabled)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    Text("调一个喜欢的音量，享受属于你的拼图时光。")
                        .font(.footnote)
                        .foregroundStyle(AppPalette.secondary)
                }
                .listRowBackground(AppPalette.surface)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .foregroundStyle(AppPalette.text)
            .background { HomeBackdrop() }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .tint(AppPalette.accent)
        .preferredColorScheme(.light)
        .frame(minWidth: 320, minHeight: 360)
    }
}
