import SwiftUI

struct AboutView: View {
    let btcAddress = "bc1ql99gmvxv8ceza3wdy8z6m4hzt8scj4jadu900z"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Plus One")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Wendler 5/3/1 Tracker")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)

                // Philosophy Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("The Philosophy", systemImage: "brain.head.profile")
                        .font(.headline)

                    Text("""
                    Jim Wendler's 5/3/1 is built on four principles:

                    1. **Start Light** — Use a Training Max (TM) that's 85-90% of your true 1RM. This builds momentum and prevents early burnout.

                    2. **Progress Slow** — Small, consistent gains beat aggressive jumps. The program adds 5 lbs to upper body and 10 lbs to lower body lifts per cycle.

                    3. **Hit PRs** — Every workout has an AMRAP set. Beat your previous reps at that weight and you've set a personal record.

                    4. **Balance Volume** — Main lifts build strength; assistance work (like BBB) builds muscle and addresses weaknesses.

                    The magic is in the simplicity: four lifts, four weeks, repeat. No paralysis by analysis — just show up and do the work.
                    """)
                    .font(.body)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Why BBB Only
                VStack(alignment: .leading, spacing: 12) {
                    Label("Why Just BBB?", systemImage: "clock")
                        .font(.headline)

                    Text("""
                    This app is designed for the time-constrained lifter. Boring But Big (5×10 at 50%) is the most popular and effective assistance template — it builds size while reinforcing technique.

                    Future versions may include more accessory options, but for now: get in, do the work, get out. That's the Wendler way.
                    """)
                    .font(.body)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Contribute Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Contribute", systemImage: "hands.clap")
                        .font(.headline)

                    Text("Plus One is open source. Found a bug? Have a feature idea? Contributions are welcome!")
                        .font(.body)

                    Link(destination: URL(string: "https://github.com/vishoo7/PlusOne")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("github.com/vishoo7/PlusOne")
                        }
                        .font(.body)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Donation Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Support Development", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Donations big or small are appreciated and help provide more resources for maintaining and improving the app.")
                        .font(.body)

                    // QR Code
                    VStack(spacing: 8) {
                        Image("BTCQRCode")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("Bitcoin")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)

                    // BTC Address
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BTC Address:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(btcAddress)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    Button {
                        UIPasteboard.general.string = btcAddress
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Address")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
