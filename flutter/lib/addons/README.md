# Add-ons API

Public API for optional paid add-ons in the platform.

## Core Components

### `AppFeature`

The primary interface that all add-ons must implement.

**Extension Points:**

- **Routes** (`getRoutes()`)
  - Features contribute their own navigation routes
  - Routes are merged into the core router at startup
  - Use namespaced paths to avoid conflicts
  - Example: `/addon/{featureId}/screen`

- **UI Contributions** (`getUiContributions()`)
  - Features inject widgets into predefined slots
  - Multiple features can contribute to the same slot
  - Contributions rendered in feature initialization order
  - Each contribution is a (Slot, WidgetBuilder) pair

- **Widget Registry** (`registerWidgets()`)
  - Features register reusable named widgets
  - Available to entire app via WidgetRegistry
  - Enable composition across multiple UI slots
  - Naming convention: `{featureId}_widgetName`

### `UiSlot` Enum

Predefined UI contribution points controlled by the core app:

- **appBar**: Top navigation area (buttons, badges, menus)
- **drawer**: Side navigation (items, shortcuts)
- **homeBody**: Home screen main content
- **homeFloatingAction**: Floating action buttons
- **settings**: Settings/preferences panels
- **statusBar**: Bottom status indicators

### `UiContribution`

Pairs a UiSlot with a widget builder function.

### `WidgetRegistry`

Shared registry for custom widgets. Features can:
- Register widgets by name
- Query registered widgets
- Retrieve and build widgets dynamically

## Feature Lifecycle

1. **Initialize** - `initialize()` called, validation happens
2. **Register Widgets** - `registerWidgets()` called
3. **Contribute Routes** - `getRoutes()` merged into router
4. **Contribute UI** - `getUiContributions()` rendered in designated slots
5. **Shutdown** - `dispose()` called

## Core App Responsibilities

The core app (not features) controls:

- Overall layout structure
- Routing configuration and initialization
- UI slot rendering and composition
- Feature lifecycle management
- Theme and styling
- System navigation

## Design Principles

- **Stable**: API is backward-compatible by default
- **Minimal**: Only essentials for extensibility
- **Decoupled**: Features don't know about each other
- **Composable**: Multiple features work together naturally
- **Safe**: Type-safe, errors caught at runtime clearly
