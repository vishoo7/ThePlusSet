import SwiftUI

struct PRBadgeView: View {
    let isNewPR: Bool

    var body: some View {
        if isNewPR {
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                Text("NEW PR!")
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.yellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    VStack {
        PRBadgeView(isNewPR: true)
        PRBadgeView(isNewPR: false)
    }
    .padding()
}
