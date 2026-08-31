import Foundation

/// Role: Felt. Demo FeltStore for no-argument screen inits. Not a persistence path.
enum FeltFixture {
    @MainActor
    static func populated() -> FeltStore {
        let store = FeltStore(vault: FeltMemory())
        store.install(nightedSeed())
        return store
    }

    @MainActor
    static func vacant() -> FeltStore {
        let store = FeltStore(vault: FeltMemory())
        store.install(.empty)
        return store
    }

    @MainActor
    static func nightedSeed() -> Felt {
        var felt = FeltSeed.felt()
        felt.nailedMask = PieMask.bit(0)
        let first = felt.slices[0]
        felt.nights = [
            Night(
                key: NightKey(rawValue: 20260502),
                lands: [Land(sliceID: first.id, name: first.name, bit: first.bit)]
            )
        ]
        return felt
    }
}

/// Role: Felt. Production store factory. Views never construct a vault themselves.
enum FeltBooth {
    @MainActor
    static func live() -> FeltStore {
        let directory: URL
        if let url = try? FeltVault.applicationSupportDirectory() {
            directory = url
        } else {
            directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("Nailbally", isDirectory: true)
        }
        return FeltStore(vault: FeltVault(directory: directory))
    }
}

enum MidwayPane: String, Identifiable, Hashable {
    case night
    case booth

    var id: String { rawValue }
}
