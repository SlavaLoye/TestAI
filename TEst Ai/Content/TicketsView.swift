import SwiftUI

struct TicketsView: View {
    let memberID: String
    let memberName: String

    @State private var records: [TicketRecord] = []
    @State private var showAdd: Bool = false
    @State private var showingQRItem: QRItem?

    var body: some View {
        List {
            Section {
                ForEach(records) { rec in
                    TicketRow(
                        record: rec,
                        onUse: { useOneRide(rec.type) },
                        onTap: {
                            guard rec.remainingRides > 0 else { return }
                            let payload = makeQRPayload(for: rec.type)
                            showingQRItem = QRItem(title: rec.type.title, details: "Разовая поездка", payload: payload)
                        }
                    )
                }
            } header: {
                Text("Билеты: \(memberName)")
            } footer: {
                Text("Нажмите «Использовать» или просто тапните по типу, чтобы показать QR и списать одну поездку.")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTicketSheet { type, quantity in
                addRides(type: type, quantity: quantity)
            }
        }
        .sheet(item: $showingQRItem) { item in
            TicketQRView(title: item.title, details: item.details, payload: item.payload)
        }
        .onChange(of: records) { _, newValue in
            TicketWalletStore.save(newValue, memberID: memberID)
        }
        .onAppear {
            records = TicketWalletStore.load(memberID: memberID)
        }
        .navigationTitle("Билеты")
    }

    private func addRides(type: TicketType, quantity: Int) {
        if let idx = records.firstIndex(where: { $0.type == type }) {
            records[idx].remainingRides += quantity
            records[idx].lastUpdated = Date()
        } else {
            records.append(TicketRecord(type: type, remainingRides: quantity))
        }
        records.sort { $0.type.title < $1.type.title }
    }

    private func useOneRide(_ type: TicketType) {
        guard let idx = records.firstIndex(where: { $0.type == type }) else { return }
        guard records[idx].remainingRides > 0 else { return }
        records[idx].remainingRides -= 1
        records[idx].lastUpdated = Date()
        let payload = makeQRPayload(for: type)
        showingQRItem = QRItem(title: type.title, details: "Разовая поездка", payload: payload)
    }

    private func makeQRPayload(for type: TicketType) -> String {
        "TICKET:\(type.rawValue.uppercased()):\(UUID().uuidString)"
    }
}

private struct TicketRow: View {
    let record: TicketRecord
    let onUse: () -> Void
    let onTap: () -> Void

    var body: some View {
        let type = record.type
        let remaining = record.remainingRides
        HStack(spacing: 12) {
            Image(systemName: type.systemImage)
                .foregroundStyle(.brown)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.headline)
                Text("Остаток: \(remaining) поездок")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onUse) {
                Text("Использовать")
            }
            .buttonStyle(.bordered)
            .disabled(remaining <= 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct QRItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let details: String
    let payload: String
}
