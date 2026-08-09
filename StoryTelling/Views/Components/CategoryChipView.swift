import SwiftUI
import Combine

struct CategoryChipView: View {
    let category: StoryCategory
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 56, height: 56)
                    Text(category.emoji).font(.title2)
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .shadow(color: isSelected ? category.gradient.first!.opacity(0.5) : .clear, radius: 8)
                Text(category.rawValue).font(.caption2.weight(.semibold)).foregroundColor(.white.opacity(isSelected ? 1 : 0.7))
            }
            .padding(6)
            .background(isSelected ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1))
        }
        .accessibilityLabel(category.rawValue)
    }
}

struct CategoryChipsRow: View {
    var selected: StoryCategory?
    var onSelect: (StoryCategory?) -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // All
                Button(action: { onSelect(nil) }) {
                    VStack(spacing: 6) {
                        ZStack { Circle().fill(Color.white.opacity(0.12)).frame(width: 56, height: 56); Text("✨").font(.title2) }
                        Text("All").font(.caption2.weight(.semibold)).foregroundColor(.white)
                    }.padding(6).background(selected==nil ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
                }
                ForEach(StoryCategory.allCases) { cat in
                    CategoryChipView(category: cat, isSelected: selected == cat) { onSelect(cat) }
                }
            }
            .padding(.horizontal)
        }
    }
}
