import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    @Query private var trainingMaxes: [TrainingMax]

    @State private var showingPlateEditor = false
    @State private var showingTMEditor = false

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
                    HStack {
                        Text("Main Sets")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.mainSetRestSeconds },
                            set: { settings.mainSetRestSeconds = $0 }
                        )) {
                            Text("2 min").tag(120)
                            Text("2.5 min").tag(150)
                            Text("3 min").tag(180)
                            Text("4 min").tag(240)
                            Text("5 min").tag(300)
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("BBB Sets")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.bbbSetRestSeconds },
                            set: { settings.bbbSetRestSeconds = $0 }
                        )) {
                            Text("60 sec").tag(60)
                            Text("90 sec").tag(90)
                            Text("2 min").tag(120)
                            Text("2.5 min").tag(150)
                        }
                        .pickerStyle(.menu)
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
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }

                    Text("Data automatically syncs with iCloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // About Section
                Section("About") {
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
        // Trigger save to force CloudKit sync
        try? modelContext.save()
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
