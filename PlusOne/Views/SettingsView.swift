import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    @Query private var trainingMaxes: [TrainingMax]

    @State private var showingPlateEditor = false
    @State private var showingTMEditor = false
    @State private var isSyncing = false
    @State private var showSyncConfirmation = false

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    var body: some View {
        NavigationStack {
            List {
                // Training Maxes Section
                Section("Training Maxes") {
                    ForEach(LiftType.allCases) { liftType in
                        if let tm = trainingMaxes.first(where: { $0.liftType == liftType }) {
                            HStack {
                                Text(liftType.rawValue)
                                Spacer()
                                Text("\(PlateCalculator.formatWeight(tm.weight)) lbs")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button("Edit Training Maxes") {
                        showingTMEditor = true
                    }
                }

                // Bar & Plates Section
                Section("Equipment") {
                    HStack {
                        Text("Bar Weight")
                        Spacer()
                        TextField("Weight", value: Binding(
                            get: { settings.barWeight },
                            set: { settings.barWeight = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }

                    Button("Edit Available Plates") {
                        showingPlateEditor = true
                    }

                    if !settings.availablePlates.isEmpty {
                        Text("Current: \(settings.availablePlates.map { PlateCalculator.formatWeight($0) }.joined(separator: ", ")) lbs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Training Max Settings
                Section("Training Max") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TM Percentage")
                            Spacer()
                            Text("\(Int(settings.trainingMaxPercentage * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { settings.trainingMaxPercentage },
                                set: { settings.trainingMaxPercentage = $0 }
                            ),
                            in: 0.85...0.95,
                            step: 0.05
                        )
                        Text("Training Max = 1RM × \(Int(settings.trainingMaxPercentage * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // BBB Settings
                Section("Boring But Big") {
                    HStack {
                        Text("BBB Percentage")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.bbbPercentage },
                            set: { settings.bbbPercentage = $0 }
                        )) {
                            Text("40%").tag(0.40)
                            Text("45%").tag(0.45)
                            Text("50%").tag(0.50)
                            Text("55%").tag(0.55)
                            Text("60%").tag(0.60)
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Rest Timer Section
                Section("Rest Timer") {
                    NavigationLink {
                        TimerSettingsView(
                            title: "Warmup Rest",
                            seconds: Binding(
                                get: { settings.warmupRestSeconds },
                                set: { settings.warmupRestSeconds = $0 }
                            ),
                            presets: [30, 45, 60, 90]
                        )
                    } label: {
                        HStack {
                            Text("Warmup Sets")
                            Spacer()
                            Text(formatTime(settings.warmupRestSeconds))
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        TimerSettingsView(
                            title: "Working Sets Rest",
                            seconds: Binding(
                                get: { settings.mainSetRestSeconds },
                                set: { settings.mainSetRestSeconds = $0 }
                            ),
                            presets: [120, 150, 180, 240, 300]
                        )
                    } label: {
                        HStack {
                            Text("Working Sets")
                            Spacer()
                            Text(formatTime(settings.mainSetRestSeconds))
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        TimerSettingsView(
                            title: "BBB Sets Rest",
                            seconds: Binding(
                                get: { settings.bbbSetRestSeconds },
                                set: { settings.bbbSetRestSeconds = $0 }
                            ),
                            presets: [60, 90, 120, 150, 180]
                        )
                    } label: {
                        HStack {
                            Text("BBB Sets")
                            Spacer()
                            Text(formatTime(settings.bbbSetRestSeconds))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Sync Section
                Section("iCloud Sync") {
                    Button {
                        syncNow()
                    } label: {
                        HStack {
                            Text("Sync Now")
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            } else if showSyncConfirmation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(isSyncing)

                    Text("Data automatically syncs with iCloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // About Section
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About Plus One")
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPlateEditor) {
                PlateEditorSheet(settings: settings)
            }
            .sheet(isPresented: $showingTMEditor) {
                TMEditorSheet(trainingMaxes: trainingMaxes)
            }
        }
    }

    private func syncNow() {
        isSyncing = true
        showSyncConfirmation = false

        // Trigger save to force CloudKit sync
        try? modelContext.save()

        // Simulate sync delay for feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSyncing = false
            showSyncConfirmation = true

            // Hide confirmation after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSyncConfirmation = false
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return "\(mins):\(String(format: "%02d", secs))"
        }
    }
}

// MARK: - Plate Editor Sheet

struct PlateEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let settings: AppSettings

    @State private var plates: [Double] = []
    @State private var newPlateText: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Available Plates") {
                    ForEach(plates.sorted(by: >), id: \.self) { plate in
                        HStack {
                            Text("\(PlateCalculator.formatWeight(plate)) lbs")
                            Spacer()
                            Button {
                                plates.removeAll { $0 == plate }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section("Add Plate") {
                    HStack {
                        TextField("Weight", text: $newPlateText)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                        Button("Add") {
                            if let weight = Double(newPlateText), weight > 0 {
                                plates.append(weight)
                                newPlateText = ""
                            }
                        }
                        .disabled(Double(newPlateText) == nil)
                    }
                }

                Section {
                    Button("Reset to Default") {
                        plates = [45, 35, 25, 10, 5, 2.5]
                    }
                }
            }
            .navigationTitle("Edit Plates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        settings.availablePlates = plates.sorted(by: >)
                        dismiss()
                    }
                }
            }
            .onAppear {
                plates = settings.availablePlates
            }
        }
    }
}

// MARK: - Timer Settings View

struct TimerSettingsView: View {
    let title: String
    @Binding var seconds: Int
    let presets: [Int]

    @State private var minutes: Int = 0
    @State private var secs: Int = 0

    var body: some View {
        List {
            // Custom time picker
            Section("Custom Time") {
                HStack {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<11) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)

                    Picker("Seconds", selection: $secs) {
                        ForEach([0, 15, 30, 45], id: \.self) { sec in
                            Text("\(sec) sec").tag(sec)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                }
                .frame(height: 120)
                .onChange(of: minutes) { _, _ in updateSeconds() }
                .onChange(of: secs) { _, _ in updateSeconds() }
            }

            // Presets
            Section("Quick Presets") {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        seconds = preset
                        loadFromSeconds()
                    } label: {
                        HStack {
                            Text(formatPreset(preset))
                                .foregroundStyle(.primary)
                            Spacer()
                            if seconds == preset {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            // Current selection display
            Section {
                HStack {
                    Text("Current")
                    Spacer()
                    Text(formatPreset(seconds))
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFromSeconds()
        }
    }

    private func loadFromSeconds() {
        minutes = seconds / 60
        secs = (seconds % 60 / 15) * 15 // Round to nearest 15 seconds
    }

    private func updateSeconds() {
        let newValue = minutes * 60 + secs
        if newValue > 0 {
            seconds = newValue
        }
    }

    private func formatPreset(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else if mins == 0 {
            return "\(secs) sec"
        } else {
            return "\(mins):\(String(format: "%02d", secs))"
        }
    }
}

// MARK: - Training Max Editor Sheet

struct TMEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trainingMaxes: [TrainingMax]

    @State private var editedValues: [LiftType: Double] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(LiftType.allCases) { liftType in
                    HStack {
                        Text(liftType.rawValue)
                        Spacer()
                        TextField("Weight", value: Binding(
                            get: { editedValues[liftType] ?? 0 },
                            set: { editedValues[liftType] = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Training Maxes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        for (liftType, weight) in editedValues {
                            if let tm = trainingMaxes.first(where: { $0.liftType == liftType }) {
                                tm.weight = weight
                                tm.updatedAt = Date()
                            }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                for tm in trainingMaxes {
                    editedValues[tm.liftType] = tm.weight
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [AppSettings.self, TrainingMax.self])
}
