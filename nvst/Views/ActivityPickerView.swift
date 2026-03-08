import SwiftUI
import FamilyControls

struct ActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    var onSave: () -> Void

    private var selectedCount: Int {
        selection.applicationTokens.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            // The picker embedded inline
            FamilyActivityPicker(
                headerText: "Select your struggle apps",
                selection: $selection
            )
            .frame(maxWidth: 500)
            .environment(\.colorScheme, .dark)
            .background(Color.black)

            // Custom bottom overlay covering the picker's native buttons
            VStack(spacing: 0) {
                // Gradient fade over bottom of picker
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0), .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)

                // Custom controls on solid background
                VStack(spacing: 12) {
                    Text("\(selectedCount) APPS SELECTED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    Button {
                        onSave()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Capsule().fill(.green))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 30)
                .background(Color.black)
            }
        }
        .preferredColorScheme(.dark)
    }
}
