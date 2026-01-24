import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query private var personalRecords: [PersonalRecord]
    @Query private var settingsArray: [AppSettings]

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var showingDeleteConfirmation = false
    @State private var workoutToDelete: Workout?

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    private var calendar: Calendar { Calendar.current }

    private var workoutDates: Set<Date> {
        Set(allWorkouts.filter { $0.isComplete }.map { calendar.startOfDay(for: $0.date) })
    }

    private var selectedWorkout: Workout? {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        return allWorkouts.first { calendar.isDate($0.date, inSameDayAs: selectedDay) && $0.isComplete }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month navigation
                    monthHeader

                    // Calendar grid
                    calendarGrid

                    // Selected workout details
                    if let workout = selectedWorkout {
                        workoutDetails(workout)
                    } else if calendar.isDate(selectedDate, inSameDayAs: Date()) {
                        noWorkoutToday
                    }
                }
                .padding()
            }
            .navigationTitle("History")
            .alert("Delete Workout?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    workoutToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete {
                        deleteWorkout(workout)
                    }
                }
            } message: {
                if let workout = workoutToDelete {
                    Text("Are you sure you want to delete this \(workout.liftType.rawValue) workout from \(dateString(for: workout.date))? This cannot be undone.")
                }
            }
        }
    }

    // MARK: - Delete Workout

    private func deleteWorkout(_ workout: Workout) {
        // Delete associated sets
        if let sets = workout.sets {
            for set in sets {
                // Remove any PR records linked to this set
                if let pr = personalRecords.first(where: { $0.workoutSetId == set.id }) {
                    modelContext.delete(pr)
                }
                modelContext.delete(set)
            }
        }

        // Delete the workout
        modelContext.delete(workout)

        try? modelContext.save()
        workoutToDelete = nil
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        hasWorkout: hasWorkout(on: date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                        onTap: { selectedDate = date }
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Workout Details

    private func workoutDetails(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.liftType.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(dateString(for: workout.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Cycle \(workout.cycleNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Week \(workout.weekNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Main sets
            if !workout.mainSets.isEmpty {
                Text("Main Sets")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(workout.mainSets, id: \.id) { set in
                    setRow(set, workout: workout)
                }
            }

            // BBB sets
            if !workout.bbbSets.isEmpty {
                Text("BBB Sets")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                ForEach(workout.bbbSets, id: \.id) { set in
                    setRow(set, workout: workout)
                }
            }

            // Notes
            if !workout.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(workout.notes)
                        .font(.body)
                }
                .padding(.top, 8)
            }

            Divider()
                .padding(.top, 8)

            // Delete button
            Button(role: .destructive) {
                workoutToDelete = workout
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Workout")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func setRow(_ set: WorkoutSet, workout: Workout) -> some View {
        HStack {
            // Set type badge
            Text(set.isBBB ? "BBB" : (set.isAMRAP ? "AMRAP" : "Main"))
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(set.isAMRAP ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundStyle(set.isAMRAP ? .orange : .blue)
                .clipShape(Capsule())

            Text("\(PlateCalculator.formatWeight(set.targetWeight)) lbs")
                .font(.body)

            Text("×")
                .foregroundStyle(.secondary)

            if let actualReps = set.actualReps {
                Text("\(actualReps)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(set.isAMRAP ? .orange : .primary)
            } else {
                Text("\(set.targetReps)")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // PR badge
            if set.isAMRAP, isPR(set: set, workout: workout) {
                PRBadgeView(isNewPR: true)
            }
        }
        .padding(.vertical, 4)
    }

    private var noWorkoutToday: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No workout logged for this day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helper Methods

    private func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }

        var days: [Date] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return days
    }

    private func hasWorkout(on date: Date) -> Bool {
        workoutDates.contains(calendar.startOfDay(for: date))
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func isPR(set: WorkoutSet, workout: Workout) -> Bool {
        guard let actualReps = set.actualReps else { return false }

        let estimated1RM = WendlerCalculator.estimatedOneRepMax(weight: set.targetWeight, reps: actualReps)

        // Check if this set created a PR
        if let pr = personalRecords.first(where: { $0.workoutSetId == set.id }) {
            // This set is linked to a PR record
            return true
        }

        return false
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [
            Workout.self,
            WorkoutSet.self,
            PersonalRecord.self,
            AppSettings.self
        ])
}
