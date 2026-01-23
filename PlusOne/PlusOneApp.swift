import SwiftUI
import SwiftData

@main
struct PlusOneApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                AppSettings.self,
                TrainingMax.self,
                CycleProgress.self,
                Workout.self,
                WorkoutSet.self,
                PersonalRecord.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
