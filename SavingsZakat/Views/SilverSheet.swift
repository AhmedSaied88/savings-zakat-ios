import SwiftUI

struct SilverSheet: View {
    var onSave: (Holding) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var grams = ""
    @State private var purpose = HoldingPurpose.investment
    @State private var acquired = Date()
    @State private var hawlStart = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight (grams)", text: $grams)
                    .keyboardType(.decimalPad)
                Picker("Purpose", selection: $purpose) {
                    Text("Investment").tag(HoldingPurpose.investment)
                    Text("Personal use").tag(HoldingPurpose.personalUse)
                }
                DatePicker("Purchase date", selection: $acquired, displayedComponents: .date)
                DatePicker("Hawl start", selection: $hawlStart, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add silver")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(grams), value > 0, value.isFinite else { return }
                        let holding = Holding(
                            id: UUID(),
                            kind: .silver,
                            amount: value,
                            currency: nil,
                            grams: value,
                            carat: nil,
                            acquiredDate: acquired,
                            hawlStartDate: hawlStart,
                            purpose: purpose
                        )
                        onSave(holding)
                        dismiss()
                    }
                    .disabled(!(Double(grams).map { $0 > 0 && $0.isFinite } ?? false))
                }
            }
        }
    }
}
