import SwiftUI

/// Role: Nail. Twist screen for the fair-share nail. Eligible bits are open AND NOT nailed.
@MainActor
struct FairShareView: View {
    let store: FeltStore
    @Environment(\.dismiss) private var dismiss

    init(store: FeltStore) {
        self.store = store
    }

    init() {
        self.init(store: FeltFixture.populated())
    }

    var body: some View {
        let face = PieFace.project(store.felt)
        VStack(alignment: .leading, spacing: TentInk.space(2)) {
            HStack {
                Text("Fair-share nail")
                    .tentText(.title)
                    .lineLimit(1)
                Spacer(minLength: TentInk.space(1))
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .tentText(.body)
                        .foregroundStyle(TentInk.Palette.accent)
                        .padding(.horizontal, TentInk.space(1))
                        .tentHit()
                        .tentPanel()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close fair-share")
            }
            if let art = TentArt.image(TentStage.twist) {
                art
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .accessibilityHidden(true)
            }
            Text("A landed slice cannot land again until every other live name has.")
                .tentText(.body)
            HStack(spacing: TentInk.space(2)) {
                figure("Open", value: TentFigures.count(face.eligibleCount))
                figure("On the pie", value: TentFigures.count(face.liveCount))
                figure("Nailed", value: TentFigures.count(face.wedges.filter(\.nailed).count))
            }
            .padding(TentInk.space(2))
            .background { TentCardBackdrop() }
            .overlay(
                RoundedRectangle(cornerRadius: TentInk.radius)
                    .stroke(TentInk.Palette.ink.opacity(0.22), lineWidth: 1)
            )
            Text("The solver counts set bits in open AND NOT nailed, draws an ordinal, and walks to that bit. A nailed centre is never a valid land.")
                .tentText(.caption)
            Spacer(minLength: 0)
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TentInk.Palette.background.ignoresSafeArea())
    }

    private func figure(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .tentText(.display)
            Text(title)
                .tentText(.caption)
        }
        .frame(maxWidth: .infinity, minHeight: TentInk.tap, alignment: .leading)
    }
}
