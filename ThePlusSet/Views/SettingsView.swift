import SwiftUI
import SwiftData
import UIKit
import AudioToolbox

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    @Query private var trainingMaxes: [TrainingMax]
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var personalRecords: [PersonalRecord]
    @Query private var cycleProgressArray: [CycleProgress]

    @State private var showingPlateEditor = false
    @State private var showingTMEditor = false
    @State private var isSyncing = false
    @State private var showSyncConfirmation = false
    @State private var exportText: String = ""
    @State private var showingExportShare = false
    @State private var showingResetCycleConfirmation = false
    @FocusState private var isBarWeightFocused: Bool

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    var body: some View {
        NavigationStack {
            List {
                // App Header
                Section {
                    HStack(spacing: 12) {
                        if let iconImage = getAppIcon() {
                            Image(uiImage: iconImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 30))
                                .foregroundStyle(.blue)
                                .frame(width: 50, height: 50)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("The Plus Set")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Wendler 5/3/1 Tracker")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Cycle Progress Section
                Section("Cycle Progress") {
                    if let progress = cycleProgressArray.first {
                        HStack {
                            Text("Current Cycle")
                            Spacer()
                            Text("Cycle \(progress.cycleNumber)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Current Week")
                            Spacer()
                            Text(progress.weekDescription)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Workout")
                            Spacer()
                            Text("\(progress.currentDay + 1) of 4")
                                .foregroundStyle(.secondary)
                        }

                        Button(role: .destructive) {
                            showingResetCycleConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset Cycle")
                            }
                        }
                    }
                }

                // Exercise Order Section
                Section("Exercise Order") {
                    ForEach(settings.exerciseOrder) { lift in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                            Text(lift.rawValue)
                        }
                    }
                    .onMove { from, to in
                        var order = settings.exerciseOrder
                        order.move(fromOffsets: from, toOffset: to)
                        settings.exerciseOrder = order
                        try? modelContext.save()
                    }
                }
                .environment(\.editMode, .constant(.active))

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
                        .focused($isBarWeightFocused)
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

                    NavigationLink {
                        ChimeSoundPickerView(
                            selectedSoundID: Binding(
                                get: { settings.timerChimeSoundID },
                                set: {
                                    settings.timerChimeSoundID = $0
                                    NotificationManager.shared.chimeSoundID = SystemSoundID($0)
                                }
                            )
                        )
                    } label: {
                        HStack {
                            Text("Timer Chime")
                            Spacer()
                            Text(chimeSoundName(for: settings.timerChimeSoundID))
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

                // Export Section
                Section("Data") {
                    Button {
                        exportText = generateExportText()
                        showingExportShare = true
                    } label: {
                        HStack {
                            Text("Export Workout History")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }

                    Text("Export your workout data as a text file for AI analysis or backup")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // About Section
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About The Plus Set")
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
            .sheet(isPresented: $showingExportShare) {
                if #available(iOS 16.0, *) {
                    ShareSheet(text: exportText)
                }
            }
            .sheet(isPresented: $showingPlateEditor) {
                PlateEditorSheet(settings: settings)
            }
            .sheet(isPresented: $showingTMEditor) {
                TMEditorSheet(trainingMaxes: trainingMaxes)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isBarWeightFocused = false
                    }
                }
            }
            .alert("Reset Cycle?", isPresented: $showingResetCycleConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetCycle()
                }
            } message: {
                Text("This will reset your progress back to Week 1, Workout 1 of Cycle 1. Any incomplete workout for today will be cleared. Your training maxes and workout history will be preserved.")
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

    private func chimeSoundName(for soundID: Int) -> String {
        switch soundID {
        case 1016: return "Tri-tone"
        case 1007: return "Chime"
        case 1005: return "Alarm"
        case 1013: return "Note"
        case 1014: return "Synth"
        case 1315: return "Bell"
        case 1304: return "Fanfare"
        case 1057: return "Tink"
        default: return "Default"
        }
    }

    private func resetCycle() {
        // Reset cycle progress
        if let progress = cycleProgressArray.first {
            progress.resetCycle()
        }

        // Clear today's incomplete workout
        let today = Calendar.current.startOfDay(for: Date())
        if let todayWorkout = allWorkouts.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today) && !$0.isComplete
        }) {
            // Delete associated sets
            if let sets = todayWorkout.sets {
                for set in sets {
                    modelContext.delete(set)
                }
            }
            modelContext.delete(todayWorkout)
        }

        try? modelContext.save()
    }

    private func getAppIcon() -> UIImage? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last else {
            return nil
        }
        return UIImage(named: iconFileName)
    }

    private func generateExportText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "yyyy-MM-dd"

        var text = """
        # The Plus Set - Workout Export
        Generated: \(dateFormatter.string(from: Date()))

        ## About This Data
        This export contains workout history from "The Plus Set" app, which tracks
        the Wendler 5/3/1 strength training program with BBB (Boring But Big) assistance work.

        ### Program Overview
        - 4-week cycles with progressive overload
        - Week 1: 5/5/5+ (65%, 75%, 85% of Training Max)
        - Week 2: 3/3/3+ (70%, 80%, 90% of Training Max)
        - Week 3: 5/3/1+ (75%, 85%, 95% of Training Max)
        - Week 4: Deload (40%, 50%, 60% - no warmup/BBB)
        - The "+" sets are AMRAP (As Many Reps As Possible)
        - BBB: 5 sets of 10 reps at a lower percentage

        ## Current Settings

        """

        // Training Maxes
        text += "### Training Maxes\n"
        for liftType in LiftType.allCases {
            if let tm = trainingMaxes.first(where: { $0.liftType == liftType }) {
                text += "- \(liftType.rawValue): \(PlateCalculator.formatWeight(tm.weight)) lbs\n"
            }
        }

        // Exercise Order
        text += "\n### Exercise Order\n"
        for (index, lift) in settings.exerciseOrder.enumerated() {
            text += "\(index + 1). \(lift.rawValue)\n"
        }

        // Equipment
        text += "\n### Equipment\n"
        text += "- Bar Weight: \(PlateCalculator.formatWeight(settings.barWeight)) lbs\n"
        text += "- Available Plates: \(settings.availablePlates.map { PlateCalculator.formatWeight($0) }.joined(separator: ", ")) lbs\n"

        // Program Settings
        text += "\n### Program Settings\n"
        text += "- BBB Percentage: \(Int(settings.bbbPercentage * 100))%\n"

        // Current Progress
        if let progress = cycleProgressArray.first {
            text += "\n### Current Progress\n"
            text += "- Cycle: \(progress.cycleNumber)\n"
            text += "- Week: \(progress.currentWeek) (\(progress.weekDescription))\n"
            text += "- Day: \(progress.currentDay + 1) of 4\n"
        }

        // Personal Records
        if !personalRecords.isEmpty {
            text += "\n## Personal Records\n"
            text += "PRs are calculated using the Epley formula: weight × (1 + reps/30)\n\n"

            let prsByLift = Dictionary(grouping: personalRecords) { $0.liftType }
            for liftType in LiftType.allCases {
                if let prs = prsByLift[liftType], let bestPR = prs.first {
                    text += "### \(liftType.rawValue)\n"
                    text += "- Best Estimated 1RM: \(PlateCalculator.formatWeight(bestPR.estimated1RM)) lbs\n"
                    text += "- Achieved: \(PlateCalculator.formatWeight(bestPR.weight)) lbs × \(bestPR.reps) reps\n"
                    text += "- Date: \(shortDateFormatter.string(from: bestPR.date))\n\n"
                }
            }
        }

        // Workout History
        text += "\n## Workout History\n"
        text += "Total Completed Workouts: \(allWorkouts.filter { $0.isComplete }.count)\n"
        text += "Total Workouts (including incomplete): \(allWorkouts.count)\n\n"

        let completedWorkouts = allWorkouts.filter { $0.isComplete }.sorted { $0.date > $1.date }

        for workout in completedWorkouts {
            text += "### \(shortDateFormatter.string(from: workout.date)) - \(workout.liftType.rawValue)\n"
            text += "Cycle \(workout.cycleNumber), Week \(workout.weekNumber)\n"

            if !workout.warmupSets.isEmpty {
                text += "\nWarmup:\n"
                for set in workout.warmupSets {
                    let repsText = set.actualReps != nil ? "\(set.actualReps!)" : "-"
                    text += "  - \(PlateCalculator.formatWeight(set.targetWeight)) lbs × \(repsText) reps\n"
                }
            }

            if !workout.mainSets.isEmpty {
                text += "\nWorking Sets:\n"
                for set in workout.mainSets {
                    let repsText = set.actualReps != nil ? "\(set.actualReps!)" : "-"
                    let amrapMarker = set.isAMRAP ? " (AMRAP)" : ""
                    text += "  - \(PlateCalculator.formatWeight(set.targetWeight)) lbs × \(repsText) reps\(amrapMarker)\n"
                }
            }

            if !workout.bbbSets.isEmpty {
                text += "\nBBB (5×10):\n"
                for set in workout.bbbSets {
                    let repsText = set.actualReps != nil ? "\(set.actualReps!)" : "-"
                    text += "  - \(PlateCalculator.formatWeight(set.targetWeight)) lbs × \(repsText) reps\n"
                }
            }

            text += "\n"
        }

        text += """

        ---
        Export from The Plus Set app
        https://github.com/your-repo/the-plus-set
        """

        return text
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

// MARK: - Chime Sound Picker View

struct ChimeSoundPickerView: View {
    @Binding var selectedSoundID: Int

    private let sounds: [(id: Int, name: String)] = [
        (1016, "Tri-tone"),
        (1007, "Chime"),
        (1005, "Alarm"),
        (1013, "Note"),
        (1014, "Synth"),
        (1315, "Bell"),
        (1304, "Fanfare"),
        (1057, "Tink")
    ]

    var body: some View {
        List {
            Section {
                ForEach(sounds, id: \.id) { sound in
                    Button {
                        selectedSoundID = sound.id
                        NotificationManager.shared.previewSound(SystemSoundID(sound.id))
                    } label: {
                        HStack {
                            Text(sound.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSoundID == sound.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } footer: {
                Text("Tap a sound to preview and select it")
            }
        }
        .navigationTitle("Timer Chime")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let textData = text.data(using: .utf8)!
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ",", with: "")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ThePlusSet_Export_\(timestamp).md")
        try? textData.write(to: tempURL)

        let activityViewController = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        return activityViewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [AppSettings.self, TrainingMax.self])
}
