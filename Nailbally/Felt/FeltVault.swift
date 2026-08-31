import Foundation

/// Role: Felt. Versioned UserDefaults key plus the atomic file projection. Views never touch this.
enum FeltKey {
    static let document = "nbl.document.v1"
    static let backup = "nbl.document.v1.backup"
    static let demo = "nbl.demo.v1"
}

enum FeltWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

protocol FeltPersisting: Sendable {
    func load() async -> (felt: Felt, warning: FeltWarning?)
    func note(_ felt: Felt) async
    func save(_ felt: Felt) async throws
    func flush() async throws
    func resetAllData() async throws
    func hasDemoSeed() async -> Bool
    func markDemoSeed() async
}

/// Role: Felt. One seam. Memory on the felt is source of truth; disk and UserDefaults are a projection.
actor FeltVault: FeltPersisting {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: Felt?
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Nailbally", isDirectory: true)
    }

    func load() async -> (felt: Felt, warning: FeltWarning?) {
        prepareDirectory()
        if let felt = decode(defaults().data(forKey: FeltKey.document)) {
            latest = felt
            return (felt, nil)
        }
        if let felt = decodeFile(fileURL()) {
            latest = felt
            return (felt, nil)
        }
        if let felt = decode(defaults().data(forKey: FeltKey.backup)) {
            latest = felt
            return (felt, .recoveredFromBackup)
        }
        if let felt = decodeFile(backupURL()) {
            latest = felt
            return (felt, .recoveredFromBackup)
        }
        if hasAnyPayload() {
            latest = .empty
            return (.empty, .startedEmpty)
        }
        latest = .empty
        return (.empty, nil)
    }

    func note(_ felt: Felt) async {
        latest = felt
        scheduleFlush()
    }

    func save(_ felt: Felt) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = felt
        try persist(felt)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if let latest {
            try persist(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        lastWriteError = nil
        let defaults = defaults()
        defaults.removeObject(forKey: FeltKey.document)
        defaults.removeObject(forKey: FeltKey.backup)
        defaults.synchronize()
        if fileManager.fileExists(atPath: fileURL().path) {
            try fileManager.removeItem(at: fileURL())
        }
        if fileManager.fileExists(atPath: backupURL().path) {
            try fileManager.removeItem(at: backupURL())
        }
    }

    func hasDemoSeed() async -> Bool {
        defaults().object(forKey: FeltKey.demo) != nil
    }

    func markDemoSeed() async {
        defaults().set(true, forKey: FeltKey.demo)
        defaults().synchronize()
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persist(_ felt: Felt) throws {
        prepareDirectory()
        let data = try FeltCodec.encode(felt)
        let defaults = defaults()
        if let previous = defaults.data(forKey: FeltKey.document) {
            defaults.set(previous, forKey: FeltKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL().path) {
            try? fileManager.removeItem(at: backupURL())
            try? fileManager.copyItem(at: fileURL(), to: backupURL())
        }
        try data.write(to: fileURL(), options: .atomic)
        defaults.set(data, forKey: FeltKey.document)
        defaults.synchronize()
        lastWriteError = nil
    }

    private func decode(_ data: Data?) -> Felt? {
        guard let data else { return nil }
        return try? FeltCodec.decode(data)
    }

    private func decodeFile(_ url: URL) -> Felt? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? FeltCodec.decode(data)
    }

    private func hasAnyPayload() -> Bool {
        defaults().data(forKey: FeltKey.document) != nil
            || defaults().data(forKey: FeltKey.backup) != nil
            || fileManager.fileExists(atPath: fileURL().path)
            || fileManager.fileExists(atPath: backupURL().path)
    }

    private func fileURL() -> URL {
        directory.appendingPathComponent("felt.json")
    }

    private func backupURL() -> URL {
        directory.appendingPathComponent("felt.json.backup")
    }

    private func defaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
