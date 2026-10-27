import Foundation
import ExponeaSDK

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
}

final class InAppLogStore: ObservableObject {

    static let shared = InAppLogStore()

    private static let cap = 500

    @Published private(set) var entries: [LogEntry] = []

    private init() {
        Exponea.logger = ExampleLogger(store: self)
    }

    func append(level: LogLevel, message: String) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.entries.count >= InAppLogStore.cap {
                self.entries.removeFirst()
            }
            self.entries.append(entry)
        }
    }

    func clear() {
        entries.removeAll()
    }

    func visibleEntries(filter: LogLevel?) -> [LogEntry] {
        guard let filter else { return entries }
        return entries.filter { $0.level == filter }
    }
}

// Subclasses the SDK's open Logger class (ExponeaSDKShared) to intercept log output.
private final class ExampleLogger: Logger {

    private weak var store: InAppLogStore?

    required init() {
        super.init()
    }

    init(store: InAppLogStore) {
        self.store = store
        super.init()
        self.logLevel = .verbose
    }

    override func log(
        _ level: LogLevel,
        message: String,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function
    ) -> Bool {
        guard logLevel.rawValue >= level.rawValue else { return false }
        store?.append(level: level, message: message)
        return super.log(level, message: message, fileName: fileName, line: line, funcName: funcName)
    }
}
