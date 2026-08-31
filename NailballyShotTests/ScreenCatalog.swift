import SwiftUI
@testable import Nailbally

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("arena", AnyView(ArenaView())),
            ("history", AnyView(HistoryView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
