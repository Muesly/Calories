import SwiftUI
import CaloriesFoundation

struct ReasonTextField: View {
    let person: Person
    let initialReason: String
    let onReasonChanged: (String) -> Void
    @State private var reasonText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Reason...", text: $reasonText, axis: .vertical)
            .font(.caption2)
            .submitLabel(.done)
            .lineLimit(2)
            .foregroundColor(Colours.foregroundPrimary)
            .padding(4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
            .focused($isFocused)
            .onAppear {
                reasonText = initialReason
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .onChange(of: reasonText) { oldValue, newValue in
                guard !newValue.contains("\n") else {
                    isFocused = false
                    reasonText = newValue.replacing("\n", with: "")
                    onReasonChanged(reasonText)
                    return
                }
                onReasonChanged(newValue)
            }
            .onSubmit {
                isFocused = false
            }
    }
}
