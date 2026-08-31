import Foundation
import Observation

/// Role: Felt. Owns the in-memory felt. Views call methods; they never touch UserDefaults or FileManager.
@MainActor
@Observable
final class FeltStore {
    private(set) var felt: Felt
    private(set) var warning: FeltWarning?
    private(set) var lastWriteError: String?
    private(set) var lastOutcome: LandOutcome?

    private let vault: any FeltPersisting
    private let calendar: Calendar

    init(vault: any FeltPersisting, calendar: Calendar = .current) {
        self.vault = vault
        self.calendar = calendar
        self.felt = .empty
    }

    func load() async {
        let loaded = await vault.load()
        felt = loaded.felt
        warning = loaded.warning
        lastWriteError = nil
    }

    func install(_ felt: Felt, warning: FeltWarning? = nil, writeError: String? = nil) {
        self.felt = felt
        self.warning = warning
        lastWriteError = writeError
        lastOutcome = nil
    }

    func keepPack(_ pack: BoothPack) throws {
        felt = try FeltAct.keep(pack, on: felt)
        persistSoon()
    }

    func join(_ name: String) throws {
        felt = try FeltAct.join(name, onto: felt)
        persistSoon()
    }

    func drop(_ id: UUID) throws {
        felt = try FeltAct.drop(id, from: felt)
        persistSoon()
    }

    func loadPack(_ pack: BoothPack) throws {
        felt = try FeltAct.load(pack, onto: felt)
        persistSoon()
    }

    func land(
        pick: (Int) -> Int = { Int.random(in: 0 ..< $0) },
        extraTurns: Int = Int.random(in: SpinPlan.extraTurnBounds),
        now: Date = Date()
    ) throws -> LandOutcome {
        let outcome = try FeltAct.land(
            on: felt,
            pick: pick,
            extraTurns: extraTurns,
            now: now,
            calendar: calendar
        )
        felt = outcome.felt
        lastOutcome = outcome
        persistSoon()
        return outcome
    }

    func markOnboardingComplete() {
        felt.onboardingComplete = true
        persistSoon()
    }

    func reopenOnboarding() {
        felt.onboardingComplete = false
        persistSoon()
    }

    func setHaptics(_ on: Bool) {
        felt.hapticsOn = on
        persistSoon()
    }

    func flush() async {
        do {
            try await vault.save(felt)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func resetAllData() async {
        do {
            try await vault.resetAllData()
        } catch {
            lastWriteError = String(describing: error)
        }
        felt = .empty
        warning = nil
        lastOutcome = nil
    }

    func seedDemoIfNeeded() async {
        #if targetEnvironment(simulator)
        if await vault.hasDemoSeed() { return }
        felt = FeltSeed.felt()
        do {
            try await vault.save(felt)
            await vault.markDemoSeed()
        } catch {
            lastWriteError = String(describing: error)
        }
        #endif
    }

    private func persistSoon() {
        let snapshot = felt
        Task { await vault.note(snapshot) }
    }
}
