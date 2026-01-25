# Contributing to The Plus Set

Thanks for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Open `ThePlusSet.xcodeproj` in Xcode
4. Create a new branch for your changes

## Development Setup

- **Xcode 15.0+** required
- **iOS 17.0+** deployment target
- Select your Development Team in Signing & Capabilities

## Making Changes

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates

### Code Style
- Follow existing SwiftUI patterns in the codebase
- Keep views focused and modular
- Use meaningful variable and function names

### Before Submitting

1. **Build successfully:**
   ```bash
   xcodebuild -project ThePlusSet.xcodeproj -scheme ThePlusSet -destination 'platform=iOS Simulator,name=iPhone 17' build
   ```

2. **Test your changes** manually in the simulator

3. **Keep commits focused** - One logical change per commit

## Submitting a Pull Request

1. Push your branch to your fork
2. Open a PR against the `dev` branch (not `main`)
3. Describe what your changes do and why
4. Link any related issues

## What We're Looking For

- Bug fixes
- Performance improvements
- UX enhancements
- Documentation improvements

## Questions?

Open an issue if you have questions or want to discuss a feature before implementing it.
