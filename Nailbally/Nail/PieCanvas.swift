import SwiftUI

/// Role: Nail. SwiftUI host for the replicator pie. Chrome stays in SwiftUI; the wheel never becomes a Shape.
struct PieCanvas: UIViewRepresentable {
    var face: PieFace
    var plan: SpinPlan?
    var planID: UUID?
    var hapticsOn: Bool
    var reduceMotion: Bool
    var onSeat: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PieCanvasView {
        PieCanvasView()
    }

    func updateUIView(_ view: PieCanvasView, context: Context) {
        view.apply(face)
        if let plan, let planID, context.coordinator.played != planID {
            context.coordinator.played = planID
            view.coast(plan, haptics: hapticsOn, reduceMotion: reduceMotion, onSeat: onSeat)
        }
    }

    static func dismantleUIView(_ view: PieCanvasView, coordinator: Coordinator) {
        view.cancel()
    }

    final class Coordinator {
        var played: UUID?
    }
}
