import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    @State private var showOnboarding = false

    private var settings: AppSettings? {
        settingsArray.first
    }

    var body: some View {
        Group {
            if showOnboarding || settings?.hasCompletedOnboarding != true {
                OnboardingView {
                    showOnboarding = false
                }
            } else {
                MainTabView()
            }
        }
        .onAppear {
            ensureSettingsExist()
            checkOnboardingStatus()
        }
    }

    private func ensureSettingsExist() {
        if settingsArray.isEmpty {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }

    private func checkOnboardingStatus() {
        if settings?.hasCompletedOnboarding != true {
            showOnboarding = true
        }
    }
}

struct MainTabView: View {
    @StateObject private var timerVM = TimerViewModel()

    var body: some View {
        TabView {
            TodayWorkoutView()
                .tabItem {
                    Label("Today", systemImage: "figure.strengthtraining.traditional")
                }

            TimerTabView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .environmentObject(timerVM)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            AppSettings.self,
            TrainingMax.self,
            CycleProgress.self,
            Workout.self,
            WorkoutSet.self,
            PersonalRecord.self
        ])
}
