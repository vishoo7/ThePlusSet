# The Plus Set

A clean, minimal iOS app for tracking Wendler 5/3/1 workouts with BBB (Boring But Big) assistance work.

## Features

### Setup & Settings
- Configure 4 main lifts (Squat, Bench Press, Deadlift, Overhead Press) with starting training maxes
- Customizable exercise order (drag to reorder directly in settings)
- Specify available plates (default: 45, 35, 25, 10, 5, 2.5 lbs) and bar weight (default: 45 lbs)
- Configurable Training Max percentage (80-100% of 1RM, default 90%)
- Configurable BBB percentage (default: 50%)
- Adjustable rest timer durations for warmup, working sets, and BBB
- Configurable timer chime sound (8 options with preview)
- View and edit training maxes anytime
- Reset cycle progress to start fresh (clears any in-progress workout)
- Export workout history as markdown file with timestamp (for AI analysis or backup)
- Manual "Sync Now" button for iCloud sync
- Settings organized by frequency of use

### Workout Structure
- **4-week cycles:**
  - Week 1: 5/5/5+ (65%, 75%, 85%)
  - Week 2: 3/3/3+ (70%, 80%, 90%)
  - Week 3: 5/3/1+ (75%, 85%, 95%)
  - Week 4: Deload (40%, 50%, 60% — no warmup or BBB)
- **Warmup sets:** 40% × 5, 50% × 5, 60% × 3 (skipped on deload week)
- **Working sets:** 3 main sets per the weekly percentages
- **BBB sets:** 5 × 10 at configured percentage (skipped on deload week)

### Set Display & Logging
- Each set displays: target weight, target reps, and plate breakdown per side
- Sets must be completed in sequence (next set is highlighted, others dimmed)
- Tap a set to enter actual reps performed, or tap "Done" button for quick complete with target reps
- Undo the last completed set by tapping its green checkmark (cascades to previous sets)
- AMRAP sets (the + sets) prominently prompt for rep count
- Add free-form notes to any workout
- Automatic rest timer starts after logging any set
- Timer shows next set info: weight, reps, set type (Warmup/Working/BBB), and plate loading
- Timer displays as bottom sheet with visual progress ring
- Pull down timer overlay to dismiss (timer keeps running in background)
- Dedicated Timer tab for accessing timer anytime with quick-start presets
- Timer completion triggers configurable chime sound, vibration, and local notification

### Workout Flexibility
- Choose which exercise to start when beginning a workout
- Change exercise mid-workout (only exercises not yet done this week are available)
- Exercises already completed this week are automatically excluded from selection

### Progression
- After completing week 3, calculates estimated 1RM using Epley formula: `weight × (1 + reps/30)`
- Sets next cycle's training max to 90% of calculated 1RM
- No regression: if new TM would be lower than current, keeps current TM
- Shows new TMs before starting the next cycle

### History & PRs
- Calendar view with red dots on days with logged workouts
- Tap any date to see full workout details (lift, sets, weights, reps performed, notes)
- Supports multiple workouts per day (all displayed in sequence)
- Delete workouts from history (with confirmation)
- Tracks PRs on AMRAP sets based on estimated 1RM
- Highlights when a new PR is hit with celebration animation

### Data & Sync
- SwiftData for local persistence
- CloudKit sync for automatic backup and multi-device sync

### Open Source & Transparency
- Full source code available in this repository
- All App Store builds are compiled by Xcode Cloud directly from this public repository
- Each release is tagged (e.g., `v1.0.0`) so you can verify the exact source for any version

## Project Structure

```
ThePlusSet/
├── ThePlusSet.xcodeproj/
│   └── project.pbxproj
└── ThePlusSet/
    ├── ThePlusSetApp.swift           # App entry point with SwiftData + CloudKit
    ├── Info.plist                    # App configuration
    ├── ThePlusSet.entitlements       # iCloud/CloudKit entitlements
    │
    ├── Models/
    │   ├── LiftType.swift            # Enum: Squat, Bench, Deadlift, OHP
    │   ├── AppSettings.swift         # User preferences (plates, timers, etc.)
    │   ├── TrainingMax.swift         # Per-lift training max values
    │   ├── CycleProgress.swift       # Current cycle/week/day tracking
    │   ├── Workout.swift             # Completed workout records
    │   ├── WorkoutSet.swift          # Individual set data with reps
    │   └── PersonalRecord.swift      # PR tracking with estimated 1RM
    │
    ├── Views/
    │   ├── ContentView.swift         # Root view with tab bar navigation
    │   ├── TodayWorkoutView.swift    # Main workout screen
    │   ├── TimerTabView.swift        # Dedicated timer tab with quick-start
    │   ├── CalendarView.swift        # Monthly history view
    │   ├── SettingsView.swift        # All configuration options
    │   ├── OnboardingView.swift      # First-launch setup flow
    │   ├── AboutView.swift           # Philosophy and donation info
    │   └── Components/
    │       ├── SetRowView.swift      # Tappable set row with weight/reps/plates
    │       ├── PlateLoadingView.swift # Plate breakdown display
    │       ├── TimerView.swift       # Rest countdown with controls
    │       ├── RepInputSheet.swift   # Sheet for logging actual reps
    │       ├── CalendarDayView.swift # Individual calendar day cell
    │       └── PRBadgeView.swift     # New PR indicator badge
    │
    ├── ViewModels/
    │   ├── TimerViewModel.swift      # Rest timer state and logic
    │   └── WorkoutViewModel.swift    # Workout generation and completion
    │
    ├── Utilities/
    │   ├── WendlerCalculator.swift   # 5/3/1 percentages, Epley formula, progression
    │   ├── PlateCalculator.swift     # Weight rounding, plate math per side
    │   └── NotificationManager.swift # Local notifications for timer
    │
    └── Resources/
        └── Assets.xcassets/
            ├── AppIcon.appiconset/
            └── AccentColor.colorset/
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `ThePlusSet.xcodeproj` in Xcode
3. Select your Development Team in Signing & Capabilities
4. Update the Bundle Identifier if needed (default: `com.theplusset.app`)
5. Build and run on your device or simulator

### CloudKit Setup

The app uses CloudKit for syncing data across devices. To enable:

1. In Xcode, select the ThePlusSet target
2. Go to Signing & Capabilities
3. Ensure "iCloud" capability is added with CloudKit enabled
4. The container `iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)` will be created automatically

## Usage

### First Launch
1. Grant notification permissions when prompted (for rest timer alerts)
2. Enter your training maxes (90% of your true 1RM for each lift)
3. Start training!

### During Workouts
1. Tap "Start Today's Workout" to begin
2. Complete each set by tapping it and entering reps performed
3. Rest timer automatically starts after each set
4. For AMRAP sets, enter your actual rep count to track progress
5. Tap "Complete Workout" when finished

### Progression
- After finishing all 4 lifts in Week 3, the app calculates new training maxes
- Review the suggested increases before starting the next cycle
- Training maxes only go up, never down

## Technical Details

### Wendler 5/3/1 Percentages
| Week | Set 1 | Set 2 | Set 3 |
|------|-------|-------|-------|
| 1    | 65%   | 75%   | 85%+  |
| 2    | 70%   | 80%   | 90%+  |
| 3    | 75%   | 85%   | 95%+  |
| 4    | 40%   | 50%   | 60%   |

### Formulas
- **Epley Formula (Estimated 1RM):** `weight × (1 + reps / 30)`
- **New Training Max:** `estimated1RM × 0.90`

## Contributing

Found a bug? Have a feature idea? Contributions are welcome! Please open an issue or submit a pull request.

## Support Development

Donations big or small are appreciated and help provide more resources for maintaining and improving the app.

**Bitcoin:** `bc1ql99gmvxv8ceza3wdy8z6m4hzt8scj4jadu900z`

## License

MIT License
