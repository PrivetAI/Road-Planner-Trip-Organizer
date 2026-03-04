import SwiftUI

struct PlannerSplashView: View {
    var body: some View {
        ZStack {
            Theme.gold.ignoresSafeArea()
            VStack(spacing: 20) {
                SuitcaseIcon()
                    .fill(Theme.white)
                    .frame(width: 80, height: 80)
                Text("Road Planner")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.white)
                Text("Trip Organizer")
                    .font(.title3)
                    .foregroundColor(Theme.white.opacity(0.8))
                SwiftUI.ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .preferredColorScheme(.light)
    }
}
