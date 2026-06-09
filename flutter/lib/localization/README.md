# Localization System

Decentralized, modular localization for the UTD Add-on Platform.

Each feature package owns its translations. The base app controls the locale and aggregates all translations at startup.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        main.dart                            │
│  LocaleNotifier.initialize() → supported locales, fallback  │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                        app.dart                             │
│  FeatureRegistry.aggregateTranslations(baseTranslations)    │
│  → merges base + all feature translations                   │
│  → passes to AppLocalizationsDelegate                       │
│  → provides LocaleNotifier via Provider                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   MaterialApp.router                        │
│  locale: localeNotifier.locale                              │
│  supportedLocales: localeNotifier.supportedLocales           │
│  localizationsDelegates: [AppLocalizationsDelegate, ...]    │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     Any Widget                              │
│  context.tr('auth.login_title')                             │
│  context.trArgs('auth.welcome', {'name': 'John'})           │
└─────────────────────────────────────────────────────────────┘
```

## Supported Languages

| Code | Language | Direction |
|------|----------|-----------|
| `en` | English  | LTR       |
| `ar` | Arabic   | RTL       |

## Quick Start

### Using translations in a widget

```dart
import 'package:utd_app/localization/localization.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple translation
        Text(context.tr('app.welcome')),

        // Translation with arguments
        Text(context.trArgs('auth.welcome', {'name': userName})),
      ],
    );
  }
}
```

### Switching locale

```dart
// From any widget with access to BuildContext
context.read<LocaleNotifier>().setLocale(Locale('ar'));

// Reset to fallback
context.read<LocaleNotifier>().resetLocale();

// Check current state
final isRtl = context.read<LocaleNotifier>().isRtl;
```

## Adding Translations to a Feature Package

### Step 1: Create a translations file

Create `lib/src/translations/your_translations.dart`:

```dart
const Map<String, Map<String, String>> authTranslations = {
  'en': {
    'auth.login_title': 'Login',
    'auth.login_button': 'Sign In',
    'auth.login_email': 'Email Address',
    'auth.login_password': 'Password',
    'auth.welcome': 'Welcome back, {name}!',
    'auth.logout': 'Logout',
  },
  'ar': {
    'auth.login_title': 'تسجيل الدخول',
    'auth.login_button': 'دخول',
    'auth.login_email': 'البريد الإلكتروني',
    'auth.login_password': 'كلمة المرور',
    'auth.welcome': 'مرحباً بعودتك، {name}!',
    'auth.logout': 'تسجيل الخروج',
  },
};
```

### Step 2: Override `getTranslations()` in your AppFeature

```dart
import 'src/translations/auth_translations.dart';

class AuthFeature extends AppFeature {
  @override
  String get id => 'com.utd.auth';

  @override
  String get displayName => 'Authentication';

  @override
  Map<String, Map<String, String>> getTranslations() => authTranslations;

  // ... other overrides (routes, UI contributions, etc.)
}
```

### Step 3: Register the feature (in main.dart)

```dart
runApp(AddonPlatformApp(
  features: [AuthFeature()],
  localeNotifier: localeNotifier,
));
```

That's it. No other files need to change. The `FeatureRegistry` merges your translations automatically.

### Step 4: Use in your screens

```dart
Text(context.tr('auth.login_title'))
Text(context.trArgs('auth.welcome', {'name': 'John'}))
```

## Key Naming Conventions

| Rule | Example | Why |
|------|---------|-----|
| Prefix with feature name | `auth.login_title` | Avoids collisions between features |
| Use snake_case | `auth.forgot_password` | Consistent, readable |
| Use `app.` for base translations | `app.ok`, `app.cancel` | Reserved namespace for shared strings |
| Be descriptive but concise | `auth.login_button` not `auth.the_button_for_logging_in` | Easy to find and use |

### Suggested key structure

```
{feature}.{section}_{element}

Examples:
  auth.login_title
  auth.login_button
  auth.register_email_label
  billing.invoice_total
  settings.theme_dark
```

## Interpolation

Use `{argName}` placeholders in translation strings:

```dart
// Translation definition
'auth.welcome': 'Welcome back, {name}! You have {count} messages.'

// Usage
context.trArgs('auth.welcome', {
  'name': 'John',
  'count': '5',
});
// Output: "Welcome back, John! You have 5 messages."
```

## Fallback Chain

When a translation key is looked up:

1. Check current locale (e.g., `ar`)
2. If not found, check English (`en`)
3. If not found, return the raw key string

This means:
- Missing translations are **visible** in the UI (the raw key appears)
- The app **never crashes** due to a missing translation
- English serves as the universal fallback

## Adding a New Language

1. Add the `Locale` to `supportedLocales` in `main.dart`:
   ```dart
   supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
   ```

2. Add translations in `base_translations.dart`:
   ```dart
   'fr': {
     'app.ok': 'D\'accord',
     'app.cancel': 'Annuler',
     // ...
   },
   ```

3. Add translations in each feature's translation file.

Missing keys in the new locale will fall back to English automatically.

## RTL Support

When the locale is set to Arabic (`ar`), Flutter automatically:
- Switches `Directionality` to RTL
- Mirrors layout for `Row`, `Padding`, `Align`, etc.
- Adjusts Material widgets (date pickers, navigation, etc.)

**Important for developers**: Use `start`/`end` instead of `left`/`right` in your layouts:

```dart
// ✅ Correct - works with both LTR and RTL
EdgeInsetsDirectional.only(start: 16)
Alignment.centerStart

// ❌ Avoid - breaks RTL layout
EdgeInsets.only(left: 16)
Alignment.centerLeft
```

## File Structure

```
lib/localization/
├── localization.dart              # Barrel file (import this)
├── app_translations.dart          # Translation lookup class
├── base_translations.dart         # Base app shared translations
├── locale_notifier.dart           # Locale state management
├── localization_delegate.dart     # Flutter LocalizationsDelegate
├── localization_extensions.dart   # context.tr() extensions
└── README.md                     # This file
```

## Performance

- All translations are Dart `const` maps — zero I/O, zero parsing
- Aggregation happens once at startup (microseconds for ~1000 keys)
- `context.tr()` is a single O(1) map lookup
- Locale switching is synchronous — no loading state or flicker
- All locales are held in memory (~few KB for a realistic app)

## Testing

```dart
// Set up translations for tests
testWidgets('shows translated text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [
        AppLocalizationsDelegate(baseTranslations),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Text(context.tr('app.ok')),
      ),
    ),
  );

  expect(find.text('OK'), findsOneWidget);
});
```
