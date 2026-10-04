import SwiftUI

struct HomeView: View {
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let columns = proxy.size.width >= 700
                    ? [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]
                    : [GridItem(.flexible())]
                ZStack {
                    HomeBackdrop()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 9) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkle")
                                        Text("一段安静的游戏时光")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(1.2)
                                    .foregroundStyle(AppPalette.accent)
                                    Text("拾光拼图")
                                        .font(.system(size: proxy.size.width < 500 ? 37 : 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppPalette.text)
                                    Text("挑一幅喜欢的风景，慢慢把它拼完整。")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppPalette.secondary)
                                }
                                Spacer(minLength: 0)
                                Button { showingSettings = true } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppPalette.accent)
                                        .frame(width: 44, height: 44)
                                        .background(AppPalette.surface, in: Circle())
                                        .overlay(Circle().stroke(AppPalette.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("设置")
                            }
                            .padding(.top, proxy.size.width < 500 ? 22 : 36)

                            HStack(spacing: 10) {
                                Text("选择一个主题")
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.text)
                                Spacer()
                                Text("\(PuzzleCategory.allCases.count) 个主题 · \(PuzzleCatalog.all.count) 幅拼图")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppPalette.secondary)
                            }

                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(PuzzleCategory.allCases) { category in
                                    NavigationLink {
                                        CategoryListView(category: category)
                                    } label: {
                                        CategoryCard(category: category)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(category.title)
                                    .accessibilityHint("打开\(category.title)主题")
                                }
                            }
                            .padding(.bottom, 30)
                        }
                        .frame(maxWidth: 1040)
                        .padding(.horizontal, proxy.size.width < 500 ? 16 : 34)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
        .preferredColorScheme(.light)
    }
}

struct CategoryCard: View {
    let category: PuzzleCategory

    private var featuredPuzzle: PuzzleDefinition? { PuzzleCatalog.definitions(for: category).first }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                GeometryReader { proxy in
                    if let featuredPuzzle {
                        Image(featuredPuzzle.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    } else {
                        LinearGradient(colors: [category.tint.opacity(0.3), AppPalette.peach], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                Label(category.subtitle, systemImage: category.symbolName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.text)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(AppPalette.surface.opacity(0.95), in: Capsule())
                    .padding(14)
            }
            .frame(height: 172)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(category.title)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.text)
                    Text("\(featuredPuzzle?.title ?? category.subtitle) · \(PuzzleCatalog.definitions(for: category).count) 幅拼图")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(AppPalette.surfaceSoft, in: Circle())
            }
            .padding(16)
        }
        .background(AppPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppPalette.border.opacity(0.75), lineWidth: 1)
        }
        .shadow(color: AppPalette.shadow.opacity(0.09), radius: 16, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct HomeBackdrop: View {
    var body: some View {
        ZStack {
            AppPalette.background
            RadialGradient(colors: [AppPalette.sunshine.opacity(0.65), .clear], center: .topTrailing, startRadius: 10, endRadius: 850)
            LinearGradient(colors: [.clear, AppPalette.peach.opacity(0.24)], startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

extension PuzzleCategory {
    var tint: Color {
        switch self {
        case .animals: return Color(red: 0.79, green: 0.39, blue: 0.23)
        case .architecture: return Color(red: 0.24, green: 0.50, blue: 0.60)
        case .vehicles: return Color(red: 0.29, green: 0.45, blue: 0.72)
        case .nature: return Color(red: 0.31, green: 0.56, blue: 0.36)
        case .space: return Color(red: 0.42, green: 0.35, blue: 0.73)
        case .mecha: return Color(red: 0.64, green: 0.39, blue: 0.24)
        case .ocean: return Color(red: 0.12, green: 0.51, blue: 0.66)
        }
    }
}
