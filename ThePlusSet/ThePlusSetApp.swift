import SwiftUI
import SwiftData

@main
struct ThePlusSetApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            AppSettings.self,
            TrainingMax.self,
            CycleProgress.self,
            Workout.self,
            WorkoutSet.self,
            PersonalRecord.self
        ])

        // Try CloudKit first, fall back to local-only if it fails
        // CloudKit requires proper signing with a Development Team
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("CloudKit failed, using local storage: \(error)")
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
                modelContainer = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
