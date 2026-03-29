# MathCounts — iOS App (Swift/SwiftUI)

Converted from the original Android/Java app. No Dropbox functionality included per request.

## Requirements

- **Xcode 15+** (or Xcode 14 with minor tweaks)
- **iOS 17 deployment target** (can be lowered to iOS 16 if needed)
- No third-party dependencies — uses only Foundation, SwiftUI, and SQLite3 (built into iOS)

## Project Structure

```
MathCounts/
├── MathCounts.xcodeproj/
│   └── project.pbxproj
└── MathCounts/
    ├── MathCountsApp.swift       ← App entry point
    ├── Models.swift              ← Card, TestResult, enums
    ├── NumberGenerator.swift     ← All math question generation logic
    ├── DatabaseManager.swift     ← SQLite persistence layer
    ├── HomeView.swift            ← Main menu
    ├── TestConfigView.swift      ← Test configuration (name, level, questions, time)
    ├── TestView.swift            ← Test-taking screen + custom numpad
    ├── TestResultView.swift      ← Results after a test
    ├── ChallengeViews.swift      ← All 5 challenge modes + results/high scores
    ├── SavedTestsView.swift      ← Browse and view past tests
    └── SettingsView.swift        ← App settings + password protection
```

## How to Open in Xcode

1. Unzip the downloaded file
2. Open `MathCounts.xcodeproj` in Xcode
3. Select your target device or simulator (iPhone, portrait)
4. Press **⌘R** to build and run

> **Note:** On first build, Xcode may ask you to set a Development Team for code signing.
> Go to the project settings → Signing & Capabilities → select your Apple ID.

## Features Included

### Test Mode
- Addition, Subtraction, Multiplication, Division
- 4 difficulty levels (Easy/Medium/Hard/Expert)
- Multiplication/Division: individual times tables (2s–12s) or Mixed
- Configurable number of questions: 5, 10, 15, 20, 25, 30, 40
- Optional time limits: Unlimited, 0:30, 1:00 – 5:00
- Optional student name entry
- Custom number pad (no system keyboard)
- Question-by-question navigation dots
- Per-question correct/incorrect tracking

### Challenge Modes
| Mode | Description | Time |
|------|-------------|------|
| Squares Challenge | Squares and square roots | 1 min |
| Percentages Challenge | Percentage calculations | 1 min |
| 10 Question Challenge | All operations, scored on speed + accuracy | Stopwatch |
| Multiplication Madness | Order-of-operations multiplication | 1 min |
| Two Minute Drill | All 4 operations mixed | 2 min |

### Results & History
- All completed tests saved to local SQLite database
- View per-question breakdown (correct answer vs. student answer)
- Filter saved tests by student name
- Delete all test data

### Settings
- Optional settings password lock
- Default student name
- Rate app link
- Delete all data

## What Was Removed
- **Dropbox integration** — removed as requested
- All `DropboxUploader.java` logic
- Network permissions

## Lowering iOS Deployment Target (optional)

If you need iOS 16 compatibility, in `project.pbxproj` change:
```
IPHONEOS_DEPLOYMENT_TARGET = 17.0;
```
to:
```
IPHONEOS_DEPLOYMENT_TARGET = 16.0;
```
The app uses no iOS 17-exclusive APIs, so this should work without code changes.
