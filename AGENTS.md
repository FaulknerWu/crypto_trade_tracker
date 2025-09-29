# Repository Guidelines

## Core Application Principles
- Manual-only workflow: users enter, edit, and delete every trade themselves.
- Never add exchange API sync or automated order execution; dialogs like `TradeFormDialog` stay human-driven.
- `DatabaseService` on top of `sqflite_common_ffi` owns persistence; keep schema changes backward-compatible.
- Always respond in Chinese-simplified.

## Project Structure & Module Organization
- `lib/main.dart` simply forwards to `lib/app/bootstrap.dart` and `lib/app/app.dart`.
- Domain logic belongs in `lib/models`, `lib/repositories`, and `lib/services`; keep widgets focused on presentation.
- Each screen lives in `lib/screens/<feature>/` with its own `widgets/` directory. Only extract to a shared module (e.g. `lib/widgets/`) after at least two screens reuse the widget and it is free of feature-specific imports.
- Register shared assets under `assets/` in `pubspec.yaml`.

## Build, Test, and Development Commands
- `flutter pub get` syncs dependencies after editing `pubspec.yaml`.
- `dart format lib test` and `flutter analyze` must pass before commits.
- `flutter run -d chrome` is the quickest manual smoke test.
- `flutter test [--coverage]` runs unit and widget suites; keep them green before PRs.

## Coding Style & Naming Conventions
- Two-space indentation, `UpperCamelCase` types, `lowerCamelCase` members, `snake_case.dart` files.
- Split files once they approach 200–250 lines, as done with `HomeView`, `HomeWorkspace`, and the dialog/table widgets.
- Prefer `const` constructors, `final` fields, and helpers for repeated logic.

## Data & Persistence
- Manage schema evolution inside `DatabaseService`; document migrations when bumping the version.
- Seed data currently adds sample exchanges and trades—update it only for demo tweaks and never commit credentials.

## Testing Guidelines
- Mirror the `lib/` tree under `test/` (`lib/screens/home/widgets/home_view.dart` → `test/screens/home/widgets/home_view_test.dart`).
- Cover manual workflows first: repository validation, `HomeWorkspace` loading/error/empty paths, and form validation edge cases.
- Use `fakeAsync` or stub repositories to simulate time-based calculations.

## Commit & Pull Request Guidelines
- Commits follow recent history: concise Simplified-Chinese subjects (≤50 chars) with optional English body, one logical change each.
- PRs list the manual test checklist (screenshots for UI tweaks), reference issues, and flag schema or asset updates so reviewers can migrate with confidence.
