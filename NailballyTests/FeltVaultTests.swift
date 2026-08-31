import XCTest
@testable import Nailbally

final class FeltVaultTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "nbl.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTripReloadPreservesNailedBitAndNightOrder() async throws {
        let vault = makeVault()
        var felt = FeltSeed.felt()
        felt = try FeltAct.land(
            on: felt,
            pick: { _ in 0 },
            extraTurns: 6,
            now: Date(timeIntervalSince1970: 1_777_680_000),
            calendar: calendar
        ).felt
        try await vault.save(felt)

        let loaded = await makeVault().load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.felt.slices.map(\.name), ["Marlo", "Vesper", "Nix", "Calico"])
        XCTAssertEqual(loaded.felt.nailedMask, PieMask.bit(0))
        XCTAssertEqual(loaded.felt.nights.first?.key.rawValue, 20260502)
        XCTAssertEqual(loaded.felt.nights.first?.lands.map(\.name), ["Marlo"])
        XCTAssertTrue(loaded.felt.onboardingComplete)
        XCTAssertNotNil(defaults.data(forKey: FeltKey.document))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("felt.json").path))
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let vault = makeVault()
        try await vault.save(FeltSeed.felt())
        if let good = defaults.data(forKey: FeltKey.document) {
            defaults.set(good, forKey: FeltKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: FeltKey.document)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("felt.json"))

        let loaded = await makeVault().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.felt.slices.map(\.name), ["Marlo", "Vesper", "Nix", "Calico"])
    }

    func test_corruptWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: FeltKey.document)
        let loaded = await makeVault().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.felt.slices.isEmpty)
    }

    func test_resetAllDataClearsDocument() async throws {
        let vault = makeVault()
        try await vault.save(FeltSeed.felt())
        try await vault.resetAllData()
        let loaded = await vault.load()
        XCTAssertTrue(loaded.felt.slices.isEmpty)
        XCTAssertNil(defaults.data(forKey: FeltKey.document))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("felt.json").path))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try FeltCodec.encode(FeltSeed.felt())
        let decoded = try FeltCodec.decode(data)
        XCTAssertEqual(decoded.slices.count, 4)
        XCTAssertThrowsError(try FeltCodec.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? FeltCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try FeltCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? FeltCodec.Failure, .corrupt)
        }
    }

    @MainActor
    func test_storeLandAndReloadThroughVault() async throws {
        let vault = makeVault()
        let store = FeltStore(vault: vault, calendar: calendar)
        try store.join("Marlo")
        try store.join("Vesper")
        _ = try store.land(pick: { _ in 0 }, extraTurns: 6, now: Date(timeIntervalSince1970: 1_777_680_000))
        await store.flush()

        let relaunched = FeltStore(vault: makeVault(), calendar: calendar)
        await relaunched.load()
        XCTAssertEqual(relaunched.felt.nailedMask, PieMask.bit(0))
        XCTAssertEqual(relaunched.felt.slices.map(\.name), ["Marlo", "Vesper"])
    }

    @MainActor
    func test_storeEmptyPopulatedInvalidLand() async {
        let store = FeltStore(vault: makeVault(), calendar: calendar)
        XCTAssertThrowsError(try store.land(pick: { _ in 0 }, extraTurns: 6)) { error in
            XCTAssertEqual(error as? FeltFault, .emptyFelt)
        }
        XCTAssertNoThrow(try store.join("Marlo"))
        XCTAssertNoThrow(try store.join("Vesper"))
        XCTAssertNoThrow(try store.join("Nix"))
        XCTAssertNoThrow(try store.land(pick: { _ in 0 }, extraTurns: 6))
        XCTAssertThrowsError(try store.land(pick: { _ in 4 }, extraTurns: 6)) { error in
            XCTAssertEqual(error as? FeltFault, .badDraw)
        }
    }

    private func makeVault() -> FeltVault {
        FeltVault(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }
}
