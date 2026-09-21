import SwiftUI

/// Role: Felt. Felt-locked chrome. The wheel never leaves; nights and booth occupy a sheet or the detail column.
@MainActor
struct ContentView: View {
    @State private var store: FeltStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var pane: MidwayPane = .night

    init(store: FeltStore) {
        _store = State(initialValue: store)
    }

    init() {
        _store = State(initialValue: FeltBooth.live())
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    ArenaView(
                        store: store,
                        handlesLaunch: true,
                        onNight: { pane = .night },
                        onBooth: { pane = .booth }
                    )
                } detail: {
                    switch pane {
                    case .night:
                        HistoryView(store: store)
                    case .booth:
                        SettingsView(store: store, onRerunOnboarding: {
                            store.reopenOnboarding()
                        })
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                ArenaView(store: store, handlesLaunch: true)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView(store: FeltFixture.populated())
}
