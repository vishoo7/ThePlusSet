import SwiftUI

struct PlateLoadingView: View {
    let plates: [Double]

    var body: some View {
        HStack(spacing: 4) {
            Text("Per side:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(PlateCalculator.formatPlates(plates))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlateLoadingView(plates: [45, 25, 10])
        PlateLoadingView(plates: [45, 45, 25])
        PlateLoadingView(plates: [])
    }
    .padding()
}
