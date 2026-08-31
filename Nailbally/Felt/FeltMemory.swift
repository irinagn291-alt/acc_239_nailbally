import Foundation

/// Role: Felt. In-process vault for fixtures and previews. Views never persist through this.
actor FeltMemory: FeltPersisting {
    private var felt: Felt
    private var demo = true

    init(felt: Felt = .empty) {
        self.felt = felt
    }

    func load() async -> (felt: Felt, warning: FeltWarning?) {
        (felt, nil)
    }

    func note(_ felt: Felt) async {
        self.felt = felt
    }

    func save(_ felt: Felt) async throws {
        self.felt = felt
    }

    func flush() async throws {}

    func resetAllData() async throws {
        felt = .empty
    }

    func hasDemoSeed() async -> Bool {
        demo
    }

    func markDemoSeed() async {
        demo = true
    }
}
