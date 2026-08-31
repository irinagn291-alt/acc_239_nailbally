import SwiftUI

/// Role: Felt. One-shot cover. Skip writes defaults. Re-runnable from the booth.
@MainActor
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(onFinish: @escaping () -> Void = {}) {
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: TentInk.space(2)) {
            Group {
                switch page {
                case 0:
                    pageBody(
                        title: "Seat the room",
                        line: "Type names or load a pack onto the felt. The wheel is the room, not a list."
                    )
                case 1:
                    pageBody(
                        title: "Flick, then nail",
                        line: "The wheel coasts clockwise and lands on an open slice. That name takes a nail."
                    )
                case 2:
                    pageBody(
                        title: "Fair-share nail",
                        line: "A nailed name stays on the pie but leaves the draw until every other live name has landed."
                    )
                default:
                    pageBody(
                        title: "Read the night",
                        line: "Lands keep order under a YYYYMMDD key. When the last open is awarded, the nails lift together."
                    )
                }
            }
            .frame(maxHeight: .infinity)
            .animation(reduceMotion ? nil : TentInk.motion, value: page)
            VStack(spacing: TentInk.space(1)) {
                Button {
                    advance()
                } label: {
                    Text(page < 3 ? "Continue" : "Start")
                        .tentText(.body)
                        .foregroundStyle(TentInk.Palette.background)
                        .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                        .background(TentInk.Palette.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    onFinish()
                } label: {
                    Text("Skip")
                        .tentText(.body)
                        .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                        .tentPanel()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TentInk.Palette.background.ignoresSafeArea())
    }

    private func advance() {
        if page < 3 {
            page += 1
            return
        }
        onFinish()
    }

    private func pageBody(title: String, line: String) -> some View {
        VStack(spacing: TentInk.space(2)) {
            onboardingArt
                .frame(width: 200, height: 240)
                .accessibilityHidden(true)
            Text(title)
                .tentText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .tentText(.body)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var onboardingArt: some View {
        let name: String = {
            switch page {
            case 0: return "nbl_Onboarding1"
            case 1: return "nbl_Onboarding2"
            case 2: return "nbl_Onboarding3"
            default: return TentStage.twist
            }
        }()
        if let art = TentArt.image(name) {
            art.resizable().scaledToFit()
        } else {
            WheelMark()
                .stroke(TentInk.Palette.ink, lineWidth: 2)
        }
    }
}

private struct WheelMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        path.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
        path.addEllipse(in: CGRect(x: center.x - outer * 0.42, y: center.y - outer * 0.42, width: outer * 0.84, height: outer * 0.84))
        return path
    }
}
