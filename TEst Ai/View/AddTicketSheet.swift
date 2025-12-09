import SwiftUI

struct AddTicketSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: TicketType = .metro
    @State private var quantity: Int = 1

    var onPurchase: (TicketType, Int) -> Void

    private let quantities = [1, 5, 10, 20]

    var body: some View {
        NavigationStack {
            Form {
                Section("Тип билета") {
                    Picker("Тип", selection: $selectedType) {
                        ForEach(TicketType.allCases) { type in
                            Label(type.title, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                }

                Section("Количество поездок") {
                    Picker("Поездок", selection: $quantity) {
                        ForEach(quantities, id: \.self) { q in
                            Text("\(q)").tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        onPurchase(selectedType, quantity)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Купить")
                                .bold()
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Добавить билет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
