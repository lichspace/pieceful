import SwiftUI

/// Completion feedback and the final result share one sheet for its entire lifetime.
struct ResultView: View {
    let definition: PuzzleDefinition
    let session: PuzzleSession
    let dismiss: () -> Void

    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrating = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HomeBackdrop()
                ScrollView {
                    VStack(spacing: 18) {
                        completionHeading

                        Image(definition.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: AppPalette.shadow.opacity(0.12), radius: 12, y: 6)
                            .accessibilityLabel("已完成的拼图：\(definition.title)")

                        VStack(spacing: 5) {
                            Text(definition.title)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppPalette.text)
                            Text("\(session.difficulty.rawValue) 片美好，已完整收藏")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.secondary)
                        }

                        HStack(spacing: 10) {
                            ResultMetric(title: "用时", value: formattedTime(session.elapsedMilliseconds))
                            ResultMetric(title: "移动", value: "\(session.moveCount) 次")
                            ResultMetric(title: "提示", value: "\(session.hintCount) 次")
                        }

                        Button(action: dismiss) {
                            HStack(spacing: 9) {
                                Text("继续探索")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(AppPalette.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("result-continue")
                    }
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .frame(maxWidth: 480)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }

                if settings.effectsEnabled && !reduceMotion {
                    ResultConfetti(burst: celebrating)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("puzzle-result")
        .onAppear { celebrating = true }
        #if os(macOS)
        .frame(width: 480, height: 680)
        #else
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #endif
    }

    private var completionHeading: some View {
        VStack(spacing: 10) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppPalette.accent)
                .frame(width: 70, height: 70)
                .background(
                    LinearGradient(colors: [AppPalette.sunshine, AppPalette.peach], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
                .rotationEffect(.degrees(celebrating || reduceMotion || !settings.effectsEnabled ? 0 : -18))
                .animation(reduceMotion || !settings.effectsEnabled ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: celebrating)
                .accessibilityHidden(true)

            Text("太棒了，拼好了！")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.text)
                .accessibilityAddTraits(.isHeader)
            Text("最后一片归位，留住这一刻的小美好。")
                .font(.subheadline)
                .foregroundStyle(AppPalette.secondary)
        }
    }

    private func formattedTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ResultMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppPalette.text)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppPalette.border, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(value)")
    }
}

private struct ResultConfetti: View {
    let burst: Bool
    private let palette: [Color] = [AppPalette.accent, Color(red: 0.91, green: 0.64, blue: 0.23),
                                    Color(red: 0.87, green: 0.48, blue: 0.40), Color(red: 0.53, green: 0.64, blue: 0.40)]

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<48, id: \.self) { index in
                let angle = Double(index) * 2.399963 + 0.4
                let distance = min(proxy.size.width, proxy.size.height) * (0.3 + CGFloat(index % 8) * 0.055)
                let x = CGFloat(cos(angle)) * distance
                let y = CGFloat(sin(angle)) * distance
                RoundedRectangle(cornerRadius: 2)
                    .fill(palette[index % palette.count])
                    .frame(width: CGFloat(5 + index % 4), height: CGFloat(9 + index % 5))
                    .rotationEffect(.degrees(burst ? Double(index * 113) : Double(index * 17)))
                    .offset(x: burst ? x : x * 0.1, y: burst ? y : y * 0.1)
                    .opacity(burst ? 0 : 0.95)
                    .animation(.easeOut(duration: 1.6 + Double(index % 5) * 0.08).delay(Double(index % 9) * 0.022), value: burst)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.3)
            }
        }
    }
}
