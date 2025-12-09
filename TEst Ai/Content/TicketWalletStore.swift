import Foundation

enum TicketType: String, Codable, CaseIterable, Identifiable {
    case metro
    case bus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .metro: return "Метро"
        case .bus: return "Автобус"
        }
    }

    var systemImage: String {
        switch self {
        case .metro: return "m.square"
        case .bus: return "bus"
        }
    }
}

struct TicketRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let type: TicketType
    var remainingRides: Int
    var lastUpdated: Date

    init(id: UUID = UUID(), type: TicketType, remainingRides: Int, lastUpdated: Date = Date()) {
        self.id = id
        self.type = type
        self.remainingRides = remainingRides
        self.lastUpdated = lastUpdated
    }
}

enum TicketWalletStore {
    private static let key = "wallet.ticket.records.v1"
    private static var defaults: UserDefaults { .standard }
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // Глобальный кошелёк (старый вариант, оставляем для совместимости)
    static func load() -> [TicketRecord] {
        guard let data = defaults.data(forKey: key),
              let items = try? decoder.decode([TicketRecord].self, from: data) else {
            return TicketType.allCases.map { TicketRecord(type: $0, remainingRides: 0) }
        }
        var dict = Dictionary(uniqueKeysWithValues: items.map { ($0.type, $0) })
        for t in TicketType.allCases where dict[t] == nil {
            dict[t] = TicketRecord(type: t, remainingRides: 0)
        }
        return Array(dict.values).sorted { $0.type.title < $1.type.title }
    }

    static func save(_ records: [TicketRecord]) {
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: key)
        }
    }

    static func reset() {
        defaults.removeObject(forKey: key)
    }

    // Персонифицированный кошелёк
    private static func key(for memberID: String) -> String {
        "wallet.ticket.records.v1.member.\(memberID)"
    }

    static func load(memberID: String) -> [TicketRecord] {
        let memberKey = key(for: memberID)
        guard let data = defaults.data(forKey: memberKey),
              let items = try? decoder.decode([TicketRecord].self, from: data) else {
            return TicketType.allCases.map { TicketRecord(type: $0, remainingRides: 0) }
        }
        var dict = Dictionary(uniqueKeysWithValues: items.map { ($0.type, $0) })
        for t in TicketType.allCases where dict[t] == nil {
            dict[t] = TicketRecord(type: t, remainingRides: 0)
        }
        return Array(dict.values).sorted { $0.type.title < $1.type.title }
    }

    static func save(_ records: [TicketRecord], memberID: String) {
        let memberKey = key(for: memberID)
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: memberKey)
        }
    }

    static func reset(memberID: String) {
        defaults.removeObject(forKey: key(for: memberID))
    }
}
