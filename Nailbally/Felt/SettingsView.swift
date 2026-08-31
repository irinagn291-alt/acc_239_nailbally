import SwiftUI

/// Role: Felt. Booth sheet. Packs, haptics, contact, reset, re-run onboarding. Views call the store.
@MainActor
struct SettingsView: View {
    let store: FeltStore
    var onRerunOnboarding: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @FocusState private var titleFocused: Bool
    @State private var packTitle = "Room pack"
    @State private var confirmReset = false
    @State private var resetBusy = false
    @State private var packBusy = false
    @State private var note: String?

    init(store: FeltStore, onRerunOnboarding: @escaping () -> Void = {}) {
        self.store = store
        self.onRerunOnboarding = onRerunOnboarding
    }

    init() {
        self.init(store: FeltFixture.populated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TentInk.space(2)) {
            sheetChrome
            if let error = store.lastWriteError {
                errorState(error)
            } else if store.felt.packs.isEmpty && store.felt.slices.isEmpty {
                emptyState
            } else {
                ScrollView {
                    populated
                }
                .scrollDismissesKeyboard(.interactively)
                .contentMargins(.bottom, TentInk.space(2), for: .scrollContent)
            }
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TentInk.Palette.background.ignoresSafeArea())
        .confirmationDialog("Erase the felt, packs, and every night?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: TentInk.space(2)) {
            Text("Packs stay on this device. A nailed name leaves the draw, not the pie.")
                .tentText(.caption)
            if let note {
                Text(note)
                    .tentText(.caption)
            }
            Text("Haptics")
                .tentText(.caption)
            Button {
                store.setHaptics(!store.felt.hapticsOn)
            } label: {
                HStack {
                    Text(store.felt.hapticsOn ? "Landing climax on" : "Landing climax off")
                        .tentText(.body)
                    Spacer()
                    Text(store.felt.hapticsOn ? "On" : "Off")
                        .tentText(.figure)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                .padding(.horizontal, TentInk.space(1))
                .tentPanel()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Haptics")
            Text("Packs")
                .tentText(.caption)
            if store.felt.packs.isEmpty {
                Text("No packs yet. Save the names on the felt.")
                    .tentText(.body)
            } else {
                ForEach(store.felt.packs) { pack in
                    Button {
                        load(pack)
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(pack.title)
                                .tentText(.body)
                                .lineLimit(1)
                            Text("\(TentFigures.count(pack.names.count)) names")
                                .tentText(.caption)
                        }
                        .frame(maxWidth: .infinity, minHeight: TentInk.tap, alignment: .leading)
                        .padding(.horizontal, TentInk.space(1))
                        .tentPanel()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(packBusy)
                }
            }
            TextField("Pack title", text: $packTitle)
                .tentText(.body)
                .focused($titleFocused)
                .padding(.horizontal, TentInk.space(1))
                .frame(minHeight: TentInk.tap)
                .tentPanel()
            Button {
                keepRoom()
            } label: {
                Text("Save room as a pack")
                    .tentText(.body)
                    .foregroundStyle(canKeep ? TentInk.Palette.background : TentInk.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .background(canKeep ? TentInk.Palette.accent : TentInk.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canKeep || packBusy)
            contactRow
            Button(action: onRerunOnboarding) {
                Text("Re-run onboarding")
                    .tentText(.body)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap, alignment: .leading)
                    .padding(.horizontal, TentInk.space(1))
                    .tentPanel()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .tentText(.body)
                    .foregroundStyle(TentInk.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap, alignment: .leading)
                    .padding(.horizontal, TentInk.space(1))
                    .tentPanel()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(resetBusy)
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
            }
            Text("No packs yet")
                .tentText(.title)
            Text("Seat names on the felt, then save them as a pack.")
                .tentText(.body)
                .multilineTextAlignment(.center)
            contactRow
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
            Text("Booth could not save.")
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
    }

    private var contactRow: some View {
        Button {
            openURL(MidwayHop.contactURL)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("Contact")
                    .tentText(.body)
                Text(MidwayHop.contactURL.absoluteString)
                    .tentText(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: TentInk.tap, alignment: .leading)
            .padding(.horizontal, TentInk.space(1))
            .tentPanel()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Contact")
    }

    private var sheetChrome: some View {
        HStack(spacing: TentInk.space(1)) {
            Text("Booth")
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
            .accessibilityLabel("Close booth")
        }
    }

    private var canKeep: Bool {
        let title = packTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && !store.felt.slices.isEmpty
    }

    private func keepRoom() {
        let title = packTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        packBusy = true
        do {
            try store.keepPack(BoothPack(title: title, names: store.felt.slices.map(\.name)))
            note = "Pack saved."
            titleFocused = false
        } catch {
            note = "That pack could not sit."
        }
        packBusy = false
    }

    private func load(_ pack: BoothPack) {
        packBusy = true
        do {
            try store.loadPack(pack)
            note = "Pack seated on the felt."
        } catch let fault as FeltFault {
            note = fault == .fullFelt ? "The pie is full." : "That pack could not load."
        } catch {
            note = "That pack could not load."
        }
        packBusy = false
    }

    private func resetAll() async {
        resetBusy = true
        await store.resetAllData()
        resetBusy = false
        dismiss()
    }
}
