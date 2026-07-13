# HealthLife

A healthy habit tracker app built for HarmonyOS using ArkTS declarative UI and the Stage model. Create, manage, and check in daily health tasks, track your progress through a calendar view, and unlock achievements as you build consistent habits.

## Features

- **13 Predefined Task Templates** covering 8 task types: count, value, duration, time-point, time-period, sub-task, auto-sync (steps/sleep from system health services), and cycle (weekly periodic)
- **Daily Check-In** — tap task cards to clock in with type-specific input methods; undo supported
- **4-Tab Navigation** — Tasks (home with progress & week calendar), Calendar (monthly grid with per-day drill-down), Achievements (consecutive-day badges & per-task milestones), Profile (avatar, nickname, BMI, settings)
- **Achievement System** — unlock badges at 1, 3, 7, 30, 50, 73, 99 consecutive check-in days; per-task milestone stars at 100%, 200%, 300%+ completion
- **Desktop Widgets** — 2×2 progress ring card and 2×4 task list card
- **Background Reminders** — alarm-type notifications via `reminderAgentManager` with customizable time and frequency
- **User Profile** — editable avatar, nickname, gender, birth date, height, weight with auto-calculated BMI
- **Past Editing Control** — toggle to allow/disallow modifying historical task records
- **Privacy Consent** — first-launch privacy dialog with persistent storage

## Tech Stack

- **Framework**: ArkTS (HarmonyOS declarative UI, Stage model, API 9+ / SDK 5.1.1)
- **State Management**: `@Observed`/`@ObjectLink`, `@Provide`/`@Consume`, `AppStorage`/`@StorageProp`
- **Persistence**: Relational Database (`@ohos.data.relationalStore`, 4 tables) + Preferences (`@ohos.data.preferences`)
- **Event Bus**: Custom `BroadCast` class for decoupled inter-component communication
- **Architecture**: MVVM-like pattern (Model → ViewModel → View)

## Project Structure

```
entry/src/main/ets/
├── entryability/        # UIAbility lifecycle & DB initialization
├── entryformability/    # Desktop widget (form) extension
├── pages/               # Page-level routes (Splash, Ads, Main, TaskList, TaskEdit)
├── view/                # Reusable UI components & sub-views
│   ├── home/            # Task tab components (week calendar, task cards)
│   ├── task/            # Task list & detail editing components
│   ├── dialog/          # Clock-in, settings, achievement, privacy dialogs
│   └── ...              # Badge panels, title bar, health text
├── viewmodel/           # Observable state classes & business logic
├── model/               # Data definitions, task templates, DB schema
├── service/             # Reminder agent wrapper
├── common/
│   ├── constants/       # App-wide constants & enums
│   ├── database/        # RDB helper layer & table API classes
│   └── utils/           # Logger, date utils, broadcast, form utils, global context
├── agency/pages/        # 2×4 desktop widget UI
└── progress/pages/      # 2×2 desktop widget UI
```

## Database Schema

| Table | Purpose |
|---|---|
| `globalInfo` | App-wide state: first date, last date, consecutive check-in days, unlocked achievements |
| `dayInfo` | Per-date summary: total tasks assigned, tasks finished |
| `taskInfo` | Per-date per-task records: target, progress, type, alarm, frequency, sub-tasks, status |
| `formInfo` | Desktop widget registration data |

## Permissions

- `ohos.permission.PUBLISH_AGENT_REMINDER` — required for background task reminders

## Requirements

- HarmonyOS standard system (phone or DevEco Studio emulator)
- Stage model, API version 9+
- DevEco Studio 3.1+
