
# ExpenseTracker

ExpenseTracker is a local-first Flutter application for recording, organizing, and reviewing personal expenses. It stores data in SQLite on the device, works without an account or network connection, and keeps the interface responsive while the database initializes.

## Features

- Add expenses with a title, amount, category, and date.
- Edit an expense by tapping its list item.
- Delete an individual expense with the delete button or swipe-to-delete gesture.
- Clear all expenses from the AppBar menu with a confirmation step.
- Search expenses by title or category.
- Filter the list by category.
- View monthly spending and the number of recorded expenses.
- View a category spending breakdown with percentage progress bars.
- Set an optional monthly budget and see progress or an exceeded-budget warning.
- Continue using the app with an in-memory fallback if SQLite is temporarily unavailable.

## Technology

- **Flutter** and Dart with null safety.
- **Provider** and `ChangeNotifier` for state management.
- **Sqflite** for local SQLite persistence.
- **Intl** for currency and date formatting.
- **Path** for platform-safe database paths.

## Project Structure

```text
lib/
├── main.dart                         # App entry point and theme
├── data/
│   └── expense_database.dart         # SQLite initialization and CRUD queries
├── models/
│   └── expense.dart                  # Expense data model and map conversion
├── providers/
│   └── expense_provider.dart         # Cached state, fallbacks, and derived totals
└── screens/
	├── home_screen.dart              # Dashboard, search, filters, and expense list
	└── add_expense_screen.dart       # Add and edit expense form

test/
└── widget_test.dart                  # App smoke test with a test database
```

## Database

The app creates `expense_tracker.db` locally with these tables:

### `expenses`

| Column | Type | Description |
| --- | --- | --- |
| `id` | INTEGER | Auto-incrementing primary key |
| `title` | TEXT | Expense name |
| `amount` | REAL | Expense amount |
| `category` | TEXT | Expense category |
| `date` | TEXT | ISO 8601 date |

### `settings`

The settings table stores the optional monthly budget. Existing version 1 databases are upgraded automatically to version 2.

Database initialization is protected by a shared in-flight `Future`, a three-second timeout at the provider boundary, and exception handling. If initialization or a query fails, the app shows the cached or empty state instead of leaving the user on an infinite loading screen.

## Getting Started

### Requirements

- Flutter SDK with Dart 3.13 or later.
- A configured Flutter device or browser target.

### Install and run

```bash
flutter pub get
flutter run
```

To run in Chrome:

```bash
flutter run -d chrome
```

SQLite persistence is intended for native Flutter targets such as Android, iOS, Windows, macOS, and Linux. The web build is useful for UI preview and compilation checks; browser storage support depends on the selected SQLite/web platform implementation.

## Testing and Validation

Run static analysis:

```bash
flutter analyze
```

Run widget tests:

```bash
flutter test
```

Build the web version:

```bash
flutter build web
```

## State Management

`ExpenseProvider` owns the in-memory expense list and exposes immutable views to the UI. Add, edit, delete, and clear-all operations update the list immediately and then persist through `ExpenseDatabase`. Search and category filtering remain local to `HomeScreen`, keeping keystrokes and filter changes fast without additional database queries.

## License

This project is currently maintained as a private application repository. Add a license file before distributing it publicly.
