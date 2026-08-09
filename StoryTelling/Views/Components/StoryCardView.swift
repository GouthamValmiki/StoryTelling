import SwiftUI
import Combine

struct StoryCardView: View {
    let story: Story
    var isFavorite: Bool = false
    var progress: Double = 0
    var onFavorite: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: story.coverGradient.compactMap { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 140)
                    .overlay(
                        Text(story.coverEmoji)
                            .font(.system(size: 56))
                            .shadow(radius: 8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Button(action: { onFavorite?() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(10)
                .accessibilityLabel(isFavorite ? "Remove favorite" : "Add favorite")
            }
            Text(story.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(story.category.emoji)
                Text(story.category.rawValue)
                    .font(.caption).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(story.readingTimeText)
                    .font(.caption2).foregroundColor(.white.opacity(0.6))
            }
            HStack(spacing: 6) {
                Text("Ages \(story.ageRange)").font(.caption2).foregroundColor(.white.opacity(0.6))
                Spacer()
                HStack(spacing: 2) { Image(systemName: "star.fill").font(.caption2).foregroundColor(.yellow); Text(String(format: "%.1f", story.rating)).font(.caption2).foregroundColor(.white.opacity(0.8)) }
            }
            if progress > 0 && progress < 1 {
                ProgressView(value: progress).tint(AppColors.accent)
            }
        }
        .padding(12)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

struct FeaturedCardView: View {
    let story: Story
    var action: () -> Void
    @State private var glow = false
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: story.coverGradient.compactMap { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
            // particles
            TimelineView(.animation) { _ in
                Canvas { ctx, size in
                    for i in 0..<12 {
                        let x = (Double(i)*47).truncatingRemainder(dividingBy: size.width)
                        let y = (sin(Date().timeIntervalSince1970 + Double(i)) * 10 + size.height*0.5)
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)), with: .color(.white.opacity(0.4)))
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("✨ Featured").font(.caption.weight(.bold)).foregroundColor(.white.opacity(0.9))
                Text(story.title).font(.title3.weight(.bold)).foregroundColor(.white)
                Text(story.description).font(.caption).foregroundColor(.white.opacity(0.85)).lineLimit(2)
                Button(action: action) {
                    Text("Start Adventure →").font(.callout.weight(.bold)).foregroundColor(AppColors.primary).padding(.horizontal, 16).padding(.vertical, 8).background(Color.white, in: Capsule())
                }
            }
            .padding(18)
            Text(story.coverEmoji).font(.system(size: 90)).opacity(0.25).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(16)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
        .scaleEffect(glow ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glow)
        .onAppear { glow = true }
    }
}
