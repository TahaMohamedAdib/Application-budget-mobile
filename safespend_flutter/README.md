# SafeSpend Flutter App

This is a Flutter version of the SafeSpend budget tracking application.

## Features Implemented

### ✅ Core Functionality
- **Theme System**: Light mode (Marble blue) and Dark mode (Oxford blue) with gold accents
- **State Management**: Provider for app-wide state
- **Data Persistence**: SharedPreferences for local storage
- **Models**: Account, Transaction, Category, Settings

### ✅ Screens
- **Today Screen**: Main dashboard with Safe to Spend card, Net Worth, Cash on Hand, Recent Transactions
- **Plan Screen**: Placeholder for bills management
- **Wealth Screen**: Placeholder for net worth tracking

### 🎨 Design
- Premium gold color scheme (#B8860B)
- Light theme: Marble background (#F2F8FC), White surfaces (#FFFFFF)
- Dark theme: Oxford Blue background (#212A37), Dark Slate Gray surfaces (#191919)
- Material Design 3 with custom theming

## How to Run

### Prerequisites
1. Flutter SDK installed (bundled with Android Studio)
2. Android Studio with Flutter plugin
3. Android emulator or physical device

### Steps to Run

1. **Open in Android Studio**:
   - Open Android Studio
   - File → Open → Select `safespend_flutter` folder

2. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   - Select your device/emulator from the device dropdown
   - Click the green "Run" button (▶️)
   - Or use terminal: `flutter run`

### Alternative: Command Line

```bash
cd d:\Work\Freelance\BudgetApp\safespend_flutter
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── account.dart
│   ├── transaction.dart
│   ├── category.dart
│   └── settings.dart
├── providers/                # State management
│   └── app_provider.dart
├── screens/                  # UI screens
│   ├── today_screen.dart
│   ├── plan_screen.dart
│   └── wealth_screen.dart
└── theme/                    # Theme configuration
    └── app_theme.dart
```

## Next Steps to Complete

The following screens need full implementation:
- [ ] Plan Screen (bills and recurring expenses)
- [ ] Wealth Screen (net worth breakdown, portfolio)
- [ ] Settings Screen
- [ ] Accounts Screen
- [ ] Coach Screen (AI assistant)
- [ ] Portfolio Screen
- [ ] Transactions Screen
- [ ] Onboarding flow (5 screens)
- [ ] Add transaction modal
- [ ] All animations and transitions

## Notes

This is a **foundational implementation** with:
- Complete project structure
- Theme system matching the React app
- Core data models and state management
- Today Screen with main features
- Ready for expansion

The app currently shows the Today screen with Safe to Spend card, Net Worth, Cash on Hand, and Recent Transactions. Other screens are placeholders.
