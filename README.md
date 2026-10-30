# MathCounts - iOS App

A SwiftUI arithmetic practice app for iPhone and iPad. The app runs fully on device and stores completed tests and challenge high scores locally.

## Requirements

- Xcode 15+
- iOS 17 deployment target
- No third-party dependencies

## Project Structure

```
MathCounts/
├── Assets.xcassets/
│   └── AppIcon.appiconset/
├── MathCounts.xcodeproj/
├── PrivacyInfo.xcprivacy
├── math-counts-logo.png
└── MathCounts/
    ├── MathCountsApp.swift
    ├── Models.swift
    ├── NumberGenerator.swift
    ├── DatabaseManager.swift
    ├── HomeView.swift
    ├── TestConfigView.swift
    ├── TestView.swift
    ├── TestResultView.swift
    ├── ChallengeViews.swift
    ├── SavedTestsView.swift
    └── SettingsView.swift
```

## How to Open in Xcode

1. Open `MathCounts.xcodeproj`.
2. Select a simulator or device.
3. Build and run with Command-R.

On first device build or archive, Xcode may require a Development Team in the target's Signing & Capabilities settings.

## Features

### Standard Tests

- Addition, subtraction, multiplication, and division practice
- Difficulty levels for addition and subtraction: Easy, Medium, Hard, Expert
- Multiplication and division levels: 2s through 12s, plus Mixed
- Configurable test length: 5, 10, 15, 20, 25, 30, or 40 questions
- Optional time limits from 30 seconds to 5 minutes, plus Unlimited mode
- Optional student name, with a default name setting
- Custom number pad for answer entry
- Local result saving with per-question review

### Challenge Modes

| Mode | Description | Time |
| --- | --- | --- |
| Squares Challenge | Squares and square roots | 1 minute |
| Percentages Challenge | Percentage calculations | 1 minute |
| 10 Question Challenge | Mixed operations scored by speed and accuracy | Stopwatch |
| Multiplication Madness | Order-of-operations multiplication | 1 minute |
| Two Minute Drill | Mixed addition, subtraction, multiplication, and division | 2 minutes |

### Results and History

- Completed standard tests are saved to a local SQLite database
- Saved tests include score, date, operation, difficulty, timing, and question breakdown
- Challenge high scores are saved locally as `Anonymous`
- Saved tests can be searched and deleted
- Settings include a default student name and a delete-all-data action

## Privacy

The app does not use accounts, ads, analytics, network requests, or third-party SDKs. User-entered names, test history, and high scores stay on device.

`PrivacyInfo.xcprivacy` declares:

- No tracking
- No collected data types
- UserDefaults access for app functionality, used by `@AppStorage` for the default student name

## Release Notes

- App icon asset is included at 1024 x 1024.
- The generated Info.plist is configured through Xcode build settings.
- The app currently targets both iPhone and iPad.
- Before App Store submission, confirm app name/branding rights and prepare accurate App Store Connect metadata, screenshots, support URL, and privacy answers.
