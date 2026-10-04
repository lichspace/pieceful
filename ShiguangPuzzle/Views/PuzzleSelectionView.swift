import SwiftUI

/// A compact, artwork-led sheet. Choosing a tile starts the puzzle immediately.
struct PuzzleSelectionView: View {
    let definition: PuzzleDefinition
    let onSelect: (Difficulty) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isStarting = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    artwork

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("你想拼多少片？")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(AppPalette.text)
                                .accessibilityAddTraits(.isHeader)
                            Text("选一个舒服的节奏，慢慢来。")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.secondary)
                        }

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(definition.availableDifficulties) { difficulty in
                                DifficultyButton(difficulty: difficulty) {
                                    guard !isStarting else { return }
                                    isStarting = true
                                    onSelect(difficulty)
                                }
                                .disabled(isStarting)
                            }
                        }
                    }

                    HStack(spacing: 7) {
                        Image(systemName: "hand.tap")
                        Text("点击片数，即可开始拼图")
                    }
                    .font(.footnote)
                    .foregroundStyle(AppPalette.secondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 26)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .background {
            LinearGradient(
                colors: [AppPalette.surface, AppPalette.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
        #if os(macOS)
        .frame(width: 480, height: 620)
        #else
        .presentationDetents([.height(690), .large])
        .presentationDragIndicator(.visible)
        #endif
    }

    private var columns: [GridItem] {
        [GridItem(dynamicTypeSize.isAccessibilitySize ? .flexible() : .adaptive(minimum: 144), spacing: 12)]
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.extension")
                .foregroundStyle(AppPalette.accent)
            Text("选择拼图难度")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppPalette.text)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppPalette.secondary)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.surfaceSoft, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("关闭难度选择")
        }
        .padding(.leading, 24)
        .padding(.trailing, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var artwork: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { proxy in
                Image(definition.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    .clipped()
            }
            .accessibilityHidden(true)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.25),
                    .init(color: .black.opacity(0.12), location: 0.45),
                    .init(color: AppPalette.text.opacity(0.78), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                Label(definition.category.title, systemImage: definition.category.symbolName)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(definition.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 230 : 184)
        .background(AppPalette.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppPalette.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DifficultyButton: View {
    let difficulty: Difficulty
    let action: () -> Void

    private var isGentle: Bool { difficulty == .pieces12 }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .center, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(difficulty.rawValue)")
                            .font(.system(.largeTitle, design: .rounded, weight: .medium))
                            .monospacedDigit()
                        Text("片")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(AppPalette.secondary)
                    }
                    Spacer(minLength: 0)
                    DifficultyGrid(difficulty: difficulty)
                        .foregroundStyle(AppPalette.accent.opacity(isGentle ? 0.9 : 0.5))
                        .frame(width: 42, height: 32)
                        .accessibilityHidden(true)
                }

                HStack(spacing: 6) {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppPalette.accent)
                }
            }
            .foregroundStyle(isGentle ? AppPalette.accent : AppPalette.text)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(DifficultyTileStyle(isGentle: isGentle))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(difficulty.title)
        .accessibilityHint("\(subtitle)，立即开始拼图")
        .accessibilityIdentifier("difficulty-\(difficulty.rawValue)")
    }

    private var subtitle: String {
        switch difficulty {
        case .pieces12: return "轻松入门"
        case .pieces24: return "悠闲时光"
        case .pieces48: return "专注挑战"
        case .pieces96: return "深度沉浸"
        }
    }
}

private struct DifficultyTileStyle: ButtonStyle {
    let isGentle: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        let isHighlighted = isHovering || configuration.isPressed
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isGentle || isHighlighted
                          ? AppPalette.accent.opacity(isHighlighted ? 0.17 : 0.09)
                          : AppPalette.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isGentle || isHighlighted
                            ? AppPalette.accent.opacity(isHighlighted ? 0.75 : 0.38)
                            : AppPalette.border,
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHighlighted)
            .onHover { isHovering = $0 }
    }
}

/// The density of the miniature grid reflects the actual number of pieces.
private struct DifficultyGrid: View {
    let difficulty: Difficulty

    var body: some View {
        Canvas { context, size in
            let grid = difficulty.grid
            let gap: CGFloat = 2
            let cellWidth = (size.width - gap * CGFloat(grid.columns - 1)) / CGFloat(grid.columns)
            let cellHeight = (size.height - gap * CGFloat(grid.rows - 1)) / CGFloat(grid.rows)

            for row in 0..<grid.rows {
                for column in 0..<grid.columns {
                    let rect = CGRect(
                        x: CGFloat(column) * (cellWidth + gap),
                        y: CGFloat(row) * (cellHeight + gap),
                        width: cellWidth,
                        height: cellHeight
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 0.8), with: .foreground)
                }
            }
        }
    }
}
