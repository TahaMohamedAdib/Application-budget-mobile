# VVollet Flutter App

VVollet is a personal finance app built with Flutter and Provider, with local persistence and Supabase synchronization. Its main tabs are Home, AI Coach, Budgets, and Wealth.

## App documentation

Start with the [living app map](docs/APP_MAP.md) for features, navigation, financial rules, data models, integrations, shared UI, test locations, and completed task history. It distinguishes implemented code from scaffolding and unverified services.

[AGENTS.md](AGENTS.md) instructs coding agents to keep the map current before closing tasks that change or add knowledge about the app.

## Local development

With a compatible Flutter SDK installed, run from this directory:

```sh
flutter pub get
flutter run
```

Runtime configuration is defined in [env_config.dart](lib/services/env_config.dart) and [ai_config.dart](lib/services/ai/ai_config.dart). Authentication, sync, and AI depend on their respective configuration and services.

## Checks

```sh
flutter analyze
flutter test
```

See the app map for focused tests associated with each feature. Dependencies and package metadata are in [pubspec.yaml](pubspec.yaml).
