import SwiftUI

/// Role: Night. Night order as a sheet (iPhone) or detail column (iPad). Keyed YYYYMMDD, not isolated winners.
@MainActor
struct HistoryView: View {
    let store: FeltStore
    @Environment(\.dismiss) private var dismiss

    init(store: FeltStore) {
        self.store = store
    }

    init() {
        self.init(store: FeltFixture.populated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TentInk.space(2)) {
            sheetChrome
            if let error = store.lastWriteError {
                errorState(error)
            } else if store.felt.nights.isEmpty {
                emptyState
            } else {
                populated
            }
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TentInk.Palette.background.ignoresSafeArea())
    }

    private var populated: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: TentInk.space(2)) {
                ForEach(store.felt.nights.reversed(), id: \.key) { night in
                    VStack(alignment: .leading, spacing: TentInk.space(1)) {
                        HStack(spacing: TentInk.space(1)) {
                            Text(TentFigures.nightTitle(night.key))
                                .tentText(.title)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer(minLength: TentInk.space(1))
                            Text(TentFigures.nightKey(night.key))
                                .tentText(.figure)
                                .layoutPriority(1)
                        }
                        ForEach(Array(night.lands.enumerated()), id: \.element.id) { index, land in
                            HStack(spacing: TentInk.space(1)) {
                                Text(TentFigures.count(index + 1))
                                    .tentText(.figure)
                                    .layoutPriority(1)
                                    .frame(minWidth: TentInk.space(4), alignment: .leading)
                                Text(land.name)
                                    .tentText(.body)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(minHeight: TentInk.tap, alignment: .leading)
                        }
                    }
                    .padding(TentInk.space(2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { TentCardBackdrop() }
                    .overlay(
                        RoundedRectangle(cornerRadius: TentInk.radius)
                            .stroke(TentInk.Palette.ink.opacity(0.22), lineWidth: 1)
                    )
                }
            }
            .contentMargins(.bottom, TentInk.space(2), for: .scrollContent)
        }
    }

    private var emptyState: some View {
        VStack(spacing: TentInk.space(2)) {
            if let art = TentArt.image(TentStage.emptyList) {
                art
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .accessibilityHidden(true)
            } else {
                WheelMark()
                    .stroke(TentInk.Palette.ink, lineWidth: 2)
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)
            }
            Text("No lands tonight")
                .tentText(.title)
            Text("Flick the wheel. This sheet is the order of the night, not a bag of winners.")
                .tentText(.body)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Text("Back to the felt")
                    .tentText(.body)
                    .foregroundStyle(TentInk.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .background(TentInk.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: TentInk.space(2)) {
            Text("Night order could not save.")
                .tentText(.title)
            Text(error)
                .tentText(.body)
            Button {
                Task { await store.flush() }
            } label: {
                Text("Retry")
                    .tentText(.body)
                    .foregroundStyle(TentInk.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .tentPanel()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sheetChrome: some View {
        HStack(spacing: TentInk.space(1)) {
            Text("Night")
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
            .accessibilityLabel("Close night order")
        }
    }
}

private struct WheelMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        path.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
        return path
    }
}
