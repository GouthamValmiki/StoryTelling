import SwiftUI
import Combine

struct AnimatedBackgroundView: View {
    var category: StoryCategory? = nil
    var body: some View {
        ZStack {
            AppColors.gradientNight.ignoresSafeArea()
            // floating particles
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<20 {
                        let progress = (t * 0.1 + Double(i) * 0.3).truncatingRemainder(dividingBy: 1)
                        let x = CGFloat((sin(Double(i)*1.3 + t*0.2)+1)/2) * size.width
                        let y = size.height * (1 - CGFloat(progress)) 
                        let alpha = 1 - progress
                        ctx.opacity = alpha * 0.5
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)), with: .color(.white))
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

struct GlowCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(radius: 10)
    }
}
