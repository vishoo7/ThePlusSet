# Claude Code Instructions for The Plus Set

## Project Overview
iOS app for tracking Wendler 5/3/1 workouts with BBB (Boring But Big) assistance work. Built with SwiftUI and SwiftData.

**Priority:** iOS experience comes first. The watchOS companion app is secondary — never break iOS functionality to support the watch app.

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
git tag v1.0.0
git push origin v1.0.0
```

Beta/TestFlight builds:
```bash
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

To check existing tags: `git tag`
To delete a tag: `git tag -d v1.0.X && git push origin --delete v1.0.X`

## Versioning Strategy

**Version format:** `MAJOR.MINOR.PATCH` (e.g., 1.2.3)

| Change Type | Example | When to use |
|-------------|---------|-------------|
| PATCH (1.0.X) | 1.0.0 → 1.0.1 | Bug fixes, minor tweaks |
| MINOR (1.X.0) | 1.0.1 → 1.1.0 | New features, non-breaking changes |
| MAJOR (X.0.0) | 1.1.0 → 2.0.0 | Major overhaul, breaking changes |

**Current phase:** TestFlight testing at 1.0.0

**Guidelines:**
- Keep 1.0.0 throughout TestFlight beta testing
- Use beta tags for TestFlight builds: `v1.0.0-beta.1`, `v1.0.0-beta.2`
- First public App Store release = `v1.0.0` (final)
- After public release, bump version for each App Store update
- Xcode Cloud auto-increments build numbers, no manual management needed

**To update version:** Change MARKETING_VERSION in Xcode (Target → General → Version) or in project.pbxproj

**Claude: Before creating a release tag:**
1. Ask the current release status (TestFlight beta, public release, etc.) if not recently confirmed
2. Infer change type (bug fix → patch, new feature → minor, major overhaul → major) - only ask if uncertain
3. Suggest the appropriate version/tag based on context - only ask if uncertain

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
