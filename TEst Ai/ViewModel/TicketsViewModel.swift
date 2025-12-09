import Foundation
import Combine
// пример вынес код из TicketsView
final class TicketsViewModel: ObservableObject {
    struct QRItem: Identifiable {
        let id = UUID()
        let title: String
        let details: String
        let payload: String
    }

    private let memberID: String?
    private let memberName: String?

    @Published var records: [TicketRecord] = []
    @Published var showAdd: Bool = false
    @Published var showingQRItem: QRItem?

    init(memberID: String? = nil, memberName: String? = nil) {
        self.memberID = memberID
        self.memberName = memberName
    }

    var headerTitle: String {
        if let name = memberName, !name.isEmpty {
            return "Билеты: \(name)"
        } else {
            return "Билеты"
        }
    }

    func load() {
        if let memberID, !memberID.isEmpty {
            records = TicketWalletStore.load(memberID: memberID)
        } else {
            records = TicketWalletStore.load()
        }
    }

    func addRides(type: TicketType, quantity: Int) {
        // Ensure we have all ticket types represented
        var dict = Dictionary(uniqueKeysWithValues: records.map { ($0.type, $0) })
        for t in TicketType.allCases where dict[t] == nil {
            dict[t] = TicketRecord(type: t, remainingRides: 0)
        }

        if var rec = dict[type] {
            rec.remainingRides += quantity
            rec.lastUpdated = Date()
            dict[type] = rec
        }

        records = Array(dict.values).sorted { $0.type.title < $1.type.title }
        save()
    }

    func useOneRide(_ type: TicketType) {
        var changed = false
        records = records.map { rec in
            guard rec.type == type else { return rec }
            var copy = rec
            if copy.remainingRides > 0 {
                copy.remainingRides -= 1
                copy.lastUpdated = Date()
                changed = true
            }
            return copy
        }
        if changed {
            save()
        }
        // After using a ride, also show the QR for convenience
        if let rec = records.first(where: { $0.type == type }) {
            presentQR(for: rec)
        }
    }

    func tapRow(_ record: TicketRecord) {
        presentQR(for: record)
    }

    private func presentQR(for record: TicketRecord) {
        let holder = (memberName?.isEmpty == false ? memberName! : "Пассажир")
        let remaining = record.remainingRides
        let title = "\(record.type.title)"
        let details = "Владелец: \(holder)\nОстаток: \(remaining) поездок"

        // Build a simple payload. You can adapt the format to your backend needs.
        let owner = (memberID?.isEmpty == false ? memberID! : "anon")
        let ts = Int(Date().timeIntervalSince1970)
        let payload = "TICKET:\(owner):\(record.type.rawValue):\(ts)"

        showingQRItem = QRItem(title: title, details: details, payload: payload)
    }

    private func save() {
        if let memberID, !memberID.isEmpty {
            TicketWalletStore.save(records, memberID: memberID)
        } else {
            TicketWalletStore.save(records)
        }
    }
}
