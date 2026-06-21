/// Defines the predefined UI contribution points in the application.
///
/// UI slots act as anchor points where features can inject custom widgets.
/// Each slot corresponds to a specific location in the app's layout controlled
/// by the core app. Features provide widgets for these slots; the core app
/// decides how to render them.
///
/// Extension points:
/// - [appBar]: App bar actions or title content.
/// - [drawer]: Drawer content.
/// - [bottomNav]: Bottom navigation bar content.
/// - [home]: Home screen content area.
/// - [dashboard]: Dashboard/overview area.
/// - [settings]: Settings/configuration section.
enum UiSlot {
  /// App bar actions/title area
  /// Core responsibility: AppBar layout and placement
  /// Feature responsibility: Actions, title widgets
  appBar,

  /// Drawer content area
  /// Core responsibility: Drawer container and layout
  /// Feature responsibility: Drawer items and content
  drawer,

  /// Bottom navigation bar
  /// Core responsibility: Bottom bar layout
  /// Feature responsibility: Buttons, tabs, indicators
  bottomNav,

  /// Home screen body - main content area
  /// Core responsibility: Layout, scrolling, spacing
  /// Feature responsibility: Widgets, content, actions
  /// Typical usage: primary feature UI, cards, content
  home,

  /// Dashboard/overview area - feature contributions displayed as cards/panels
  /// Core responsibility: Grid/list layout, card styling, containers
  /// Feature responsibility: Dashboard data, widget appearance
  /// Typical usage: metrics, summaries, overview widgets
  dashboard,

  /// Settings/preferences screen
  /// Core responsibility: Settings layout, navigation, grouping
  /// Feature responsibility: Settings options, preferences storage
  /// Typical usage: feature configuration, advanced options
  settings,

  /// Login methods area on the intro/login screen
  /// Core responsibility: Layout, spacing
  /// Feature responsibility: Social login buttons (Google, Apple, etc.)
  loginMethods,

  /// Sections inside a user profile page (Levels, Gifts, Social stats...)
  /// Core responsibility: Scrollable layout, section spacing
  /// Feature responsibility: Section content, data loading
  userProfile,

  /// Action buttons on another user's profile (Follow, Message, Gift)
  /// Core responsibility: Button row layout
  /// Feature responsibility: Individual action buttons
  userProfileActions,

  /// Content tabs on a visited user's profile (e.g. Moments, Reels).
  /// Core responsibility: TabBar layout + the built-in "General" tab.
  /// Feature responsibility: a labeled tab (UiContribution.label) whose builder
  /// renders that user's content, scoped via ProfileViewArguments.userId.
  profileTab,
}
