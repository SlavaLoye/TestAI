import SwiftUI

struct TicketQRView: View {
    let title: String
    let details: String
    let payload: String

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title3.bold())
            Text(details)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            QRCodeView(payload: payload, size: 240)
                .padding(.top, 8)

            Text("Покажите этот QR-код при входе в транспорт")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
