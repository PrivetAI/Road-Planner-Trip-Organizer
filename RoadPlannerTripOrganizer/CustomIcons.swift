import SwiftUI
import UIKit

/// Convert any Shape into a UIImage, then into a SwiftUI Image suitable for .tabItem
func shapeImage<S: Shape>(_ shape: S, size: CGFloat = 24, color: UIColor = .label) -> Image {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    let uiImage = renderer.image { ctx in
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let path = shape.path(in: rect).cgPath
        ctx.cgContext.addPath(path)
        ctx.cgContext.setFillColor(color.cgColor)
        ctx.cgContext.fillPath(using: .evenOdd)
    }
    return Image(uiImage: uiImage.withRenderingMode(.alwaysTemplate))
}

/// Gold header bar with white bold title — replaces the default NavigationView title
struct GoldHeaderView<Trailing: View>: View {
    let title: String
    let trailing: Trailing

    init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                trailing
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 10)
            .background(Theme.gold)
        }
        .background(Theme.gold.ignoresSafeArea(edges: .top))
    }
}

extension GoldHeaderView where Trailing == EmptyView {
    init(title: String) {
        self.title = title
        self.trailing = EmptyView()
    }
}

struct SuitcaseIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Handle
        p.addRoundedRect(in: CGRect(x: w*0.35, y: 0, width: w*0.3, height: h*0.18), cornerSize: CGSize(width: w*0.05, height: h*0.05))
        // Body
        p.addRoundedRect(in: CGRect(x: w*0.05, y: h*0.18, width: w*0.9, height: h*0.72), cornerSize: CGSize(width: w*0.08, height: h*0.08))
        // Center strap
        p.addRect(CGRect(x: w*0.46, y: h*0.18, width: w*0.08, height: h*0.72))
        // Feet
        p.addRoundedRect(in: CGRect(x: w*0.15, y: h*0.9, width: w*0.12, height: h*0.1), cornerSize: CGSize(width: w*0.03, height: h*0.03))
        p.addRoundedRect(in: CGRect(x: w*0.73, y: h*0.9, width: w*0.12, height: h*0.1), cornerSize: CGSize(width: w*0.03, height: h*0.03))
        return p
    }
}

struct ChecklistBoxIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Box
        p.addRoundedRect(in: CGRect(x: 0, y: 0, width: w, height: h), cornerSize: CGSize(width: w*0.1, height: h*0.1))
        // Checkmark
        p.move(to: CGPoint(x: w*0.2, y: h*0.5))
        p.addLine(to: CGPoint(x: w*0.4, y: h*0.7))
        p.addLine(to: CGPoint(x: w*0.8, y: h*0.25))
        return p
    }
}

struct MapPinIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = w * 0.5
        // Pin body (teardrop)
        p.move(to: CGPoint(x: cx, y: h))
        p.addCurve(to: CGPoint(x: w * 0.1, y: h * 0.38),
                    control1: CGPoint(x: cx - w*0.05, y: h*0.75),
                    control2: CGPoint(x: w*0.1, y: h*0.6))
        p.addArc(center: CGPoint(x: cx, y: h*0.38), radius: w*0.4, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: cx, y: h),
                    control1: CGPoint(x: w*0.9, y: h*0.6),
                    control2: CGPoint(x: cx + w*0.05, y: h*0.75))
        // Inner circle
        p.addEllipse(in: CGRect(x: cx - w*0.15, y: h*0.24, width: w*0.3, height: w*0.3))
        return p
    }
}

struct WalletIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Main body
        p.addRoundedRect(in: CGRect(x: 0, y: h*0.15, width: w, height: h*0.75), cornerSize: CGSize(width: w*0.1, height: h*0.1))
        // Flap
        p.addRoundedRect(in: CGRect(x: 0, y: 0, width: w*0.85, height: h*0.35), cornerSize: CGSize(width: w*0.1, height: h*0.1))
        // Clasp
        p.addEllipse(in: CGRect(x: w*0.7, y: h*0.35, width: w*0.2, height: h*0.2))
        return p
    }
}

struct FlagIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Pole
        p.addRect(CGRect(x: w*0.1, y: 0, width: w*0.08, height: h))
        // Flag
        p.move(to: CGPoint(x: w*0.18, y: h*0.05))
        p.addLine(to: CGPoint(x: w*0.9, y: h*0.15))
        p.addLine(to: CGPoint(x: w*0.9, y: h*0.45))
        p.addLine(to: CGPoint(x: w*0.18, y: h*0.55))
        p.closeSubpath()
        return p
    }
}

struct PlusIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let t = min(w, h) * 0.2
        p.addRect(CGRect(x: (w - t)/2, y: h*0.1, width: t, height: h*0.8))
        p.addRect(CGRect(x: w*0.1, y: (h - t)/2, width: w*0.8, height: t))
        return p
    }
}
