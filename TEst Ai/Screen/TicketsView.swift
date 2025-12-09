import SwiftUI

struct TicketsView: View {
    let memberID: String?
    let memberName: String?

    @StateObject private var viewModel: TicketsViewModel

    init(memberID: String? = nil, memberName: String? = nil) {
        self.memberID = memberID
        self.memberName = memberName
        _viewModel = StateObject(wrappedValue: TicketsViewModel(memberID: memberID, memberName: memberName))
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.records) { rec in
                    TicketRow(
                        record: rec,
                        onUse: { viewModel.useOneRide(rec.type) },
                        onTap: { viewModel.tapRow(rec) }
                    )
                }
            } header: {
                Text(viewModel.headerTitle)
            } footer: {
                Text("Нажмите «Использовать» или просто тапните по типу, чтобы показать QR и списать одну поездку.")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showAdd = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showAdd) {
            AddTicketSheet { type, quantity in
                viewModel.addRides(type: type, quantity: quantity)
            }
        }
        .sheet(item: $viewModel.showingQRItem) { item in
            TicketQRView(title: item.title, details: item.details, payload: item.payload)
        }
        .onAppear {
            viewModel.load()
        }
        .navigationTitle("Мои билеты")
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
                .foregroundStyle(.blue)
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
