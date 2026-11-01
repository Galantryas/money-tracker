# Money Tracker

A personal finance app for tracking spending across pockets — separate balances for cash, bank, e-wallet, or anything else — with a dashboard, monthly reports, and an optional AI advisor.

Built with Flutter, stores everything on the device, and requires no account.

## Features

- **Pockets** — multiple balances with their own currency, icon, and colour; transfers between them.
- **Transactions** — income and expense entries per pocket, with categories, notes, and a date range filter.
- **Dashboard** — current balance, this month's spending, and recent activity.
- **Statistics** — category breakdown and trend charts over a chosen period.
- **Reports** — date-range report with totals per category.
- **Lock screen** — biometric unlock through the device's secure storage.
- **Backup and restore** — export and import the database.
- **Reminders** — scheduled notifications for recurring entries.
- **Privacy mode** — hide balances on demand, useful when showing the app to someone.
- **AI advisor** — optional; asks Gemini for a summary of your spending. You supply your own API key, stored in secure storage, and the feature stays off until you do.

## Stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter 3, Dart |
| State | Provider |
| Storage | SQLite via `sqflite`, local only |
| Charts | `fl_chart` |
| Security | `local_auth`, `flutter_secure_storage` |
| AI | Google Gemini API (optional, user key) |

## Running

```bash
flutter pub get
flutter run
```

Release build:

```bash
flutter build apk --release
```

Also builds for iOS, Windows, macOS, and Linux where the platforms are configured.

## Project layout

```
lib/
  core/          Database, theme, formatters, security, services
  models/        Pocket, transaction, category
  providers/     State: auth, pockets, transactions, theme, AI
  services/      Gemini integration
  views/         Screens: dashboard, pockets, transactions, stats, settings
```

## Notes

Data never leaves the device unless you export a backup or use the AI advisor, which sends a summary of your transactions to Gemini. The API key lives in platform secure storage, not in the repository.

## Licence

Personal project. Not licensed for redistribution.
