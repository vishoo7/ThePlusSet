# Claude Code Instructions for The Plus Set

## Project Overview
iOS app for tracking Wendler 5/3/1 workouts with BBB (Boring But Big) assistance work. Built with SwiftUI and SwiftData.

## Development Workflow
- Use `dev` branch for development work
- Merge to `main` when features are complete and tested
- Push both branches after merging

## Release Workflow (Xcode Cloud)
Xcode Cloud is configured for **tag-based builds only** (pattern: `v*`).

- **"ship it"** = commit to dev, merge to main, push both branches (no build triggered)
- **"release it"** or **"tag it"** = also create and push a version tag to trigger Xcode Cloud build

To create a release:
```bash
git tag v1.0.X
git push origin v1.0.X
```

To check existing tags: `git tag`
To delete a tag: `git tag -d v1.0.X && git push origin --delete v1.0.X`

## Preferences
- Update README.md when adding/changing features that affect user-facing functionality
- Commit messages should be descriptive with bullet points for multiple changes
- Include `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>` in commits

## Build Command
```bash
xcodebuild -project ThePlusSet.xcodeproj -scheme ThePlusSet -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Test Command
```bash
xcodebuild test -project ThePlusSet.xcodeproj -scheme ThePlusSet -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:ThePlusSetTests
```

## Key Files
- `ThePlusSet/Models/AppSettings.swift` - User preferences and settings
- `ThePlusSet/Views/TodayWorkoutView.swift` - Main workout screen
- `ThePlusSet/Views/SettingsView.swift` - Settings UI
- `ThePlusSet/ViewModels/TimerViewModel.swift` - Shared timer state
- `ThePlusSet/Utilities/NotificationManager.swift` - Sound and notifications

## Adding New Swift Files
New `.swift` files must be added to `ThePlusSet.xcodeproj/project.pbxproj` in 4 places:
1. PBXBuildFile section
2. PBXFileReference section
3. Appropriate PBXGroup (Views, Models, etc.)
4. PBXSourcesBuildPhase
