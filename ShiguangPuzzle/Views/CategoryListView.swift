import SwiftUI

struct CategoryListView: View {
    let category: PuzzleCategory

    @State private var selectedPuzzle: PuzzleDefinition?
    @State private var pendingLaunch: (definition: PuzzleDefinition, difficulty: Difficulty)?
    @State private var launchDefinition: PuzzleDefinition?
    @State private var launchDifficulty: Difficulty?

    private let columns = [GridItem(.adaptive(minimum: 270), spacing: 18)]

    var body: some View {
        ZStack {
            HomeBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category.subtitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppPalette.secondary)
                            Text(category.title)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.text)
                        }
                        Spacer()
                        Text("\(PuzzleCatalog.definitions(for: category).count) 幅")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppPalette.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppPalette.surfaceSoft, in: Capsule())
                    }

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(PuzzleCatalog.definitions(for: category)) { definition in
                            Button {
                                selectedPuzzle = definition
                            } label: {
                                PuzzlePreviewCard(definition: definition)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(definition.title)
                            .accessibilityHint("选择难度后直接开始拼图")
                        }
                    }
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: 1040)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(category.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $selectedPuzzle, onDismiss: launchSelectedPuzzle) { definition in
            PuzzleSelectionView(definition: definition) { difficulty in
                pendingLaunch = (definition, difficulty)
                selectedPuzzle = nil
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { launchDefinition != nil && launchDifficulty != nil },
            set: { isPresented in
                if !isPresented {
                    launchDefinition = nil
                    launchDifficulty = nil
                }
            }
        )) {
            if let launchDefinition, let launchDifficulty {
                PuzzleView(definition: launchDefinition, difficulty: launchDifficulty)
            }
        }
    }

    private func launchSelectedPuzzle() {
        guard let pendingLaunch else { return }
        self.pendingLaunch = nil
        // Wait for sheet dismissal so navigation and presentation do not compete.
        launchDefinition = pendingLaunch.definition
        launchDifficulty = pendingLaunch.difficulty
    }
}

struct PuzzlePreviewCard: View {
    let definition: PuzzleDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                Image(definition.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .frame(height: 158)

            VStack(alignment: .leading, spacing: 7) {
                Text(definition.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.text)
                HStack(spacing: 8) {
                    Text(definition.availableDifficulties.map { String($0.rawValue) }.joined(separator: " / ") + " 片")
                    Spacer(minLength: 0)
                    Text("选择难度")
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppPalette.accent)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.secondary)
            }
            .padding(16)
        }
        .background(AppPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AppPalette.border.opacity(0.75), lineWidth: 1))
        .shadow(color: AppPalette.shadow.opacity(0.09), radius: 16, y: 8)
    }
}
