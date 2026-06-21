/// Central application configuration
///
/// Contains all app-wide settings that can be configured per environment.
/// Use [AppConfig.development] or [AppConfig.production]
/// for environment-specific configurations.
class AppConfig {
  /// Application name displayed in the app
  final String appName;

  /// Base URL for API requests
  final String baseUrl;

  /// UTD Stream app ID for audio rooms
  final String utdStreamAppId;

  /// Storage bucket URL for file uploads/downloads
  final String storageBucketUrl;

  /// Domain URL (main website)
  final String domainUrl;

  /// Privacy policy URL
  final String privacyPolicyUrl;

  /// Internal build number, set at compile time via
  /// `--dart-define=APP_BUILD_NUMBER=<n>`; used by the launch gate. Bump it on
  /// every release.
  final int appBuildNumber;

  /// Whether to use device locale as initial locale
  final bool useDeviceLocale;

  /// Current environment
  final Environment environment;

  /// Whether debug features are enabled
  final bool enableDebugFeatures;

  /// API timeout duration
  final Duration apiTimeout;

  /// Maximum retry attempts for failed requests
  final int maxRetryAttempts;

  const AppConfig({
    required this.appName,
    required this.baseUrl,
    required this.storageBucketUrl,
    required this.domainUrl,
    required this.privacyPolicyUrl,
    required this.environment,
    this.utdStreamAppId = '',
    this.appBuildNumber = 1,
    this.useDeviceLocale = true,
    this.enableDebugFeatures = false,
    this.apiTimeout = const Duration(seconds: 30),
    this.maxRetryAttempts = 3,
  });

  /// Development environment configuration (local backend)
  factory AppConfig.development() {
    return AppConfig(
      appName: 'Tempo Dev',
      baseUrl: 'http://192.168.1.5:8000/api',
      storageBucketUrl: 'https://storage.googleapis.com/base-app-utd',
      domainUrl: 'http://192.168.1.5:8000',
      privacyPolicyUrl: 'http://192.168.1.5:8000/api/privacy-policy',
      utdStreamAppId: '3019100698',
      appBuildNumber: int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 1),
      environment: Environment.development,
      enableDebugFeatures: true,
    );
  }

  /// Production environment configuration
  factory AppConfig.production() {
    return AppConfig(
      appName: 'Tempo',
      // Server backend at project-x.utdsoftware.com.
      baseUrl: 'https://project-x.utdsoftware.com/api',
      storageBucketUrl: 'https://storage.googleapis.com/base-app-utd',
      domainUrl: 'https://project-x.utdsoftware.com',
      privacyPolicyUrl: 'https://project-x.utdsoftware.com/api/privacy-policy',
      utdStreamAppId: '4602085317',
      appBuildNumber: int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 1),
      environment: Environment.production,
      enableDebugFeatures: false,
    );
  }

  /// Check if running in development
  bool get isDevelopment => environment == Environment.development;

  /// Check if running in production
  bool get isProduction => environment == Environment.production;

  /// Get full URL for a storage path
  String storageUrl(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$storageBucketUrl/$cleanPath';
  }

  /// Get full URL for an API endpoint
  String apiUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$cleanEndpoint';
  }

  /// Create a copy with modified values
  AppConfig copyWith({
    String? appName,
    String? baseUrl,
    String? utdStreamAppId,
    String? storageBucketUrl,
    String? domainUrl,
    String? privacyPolicyUrl,
    int? appBuildNumber,
    bool? useDeviceLocale,
    Environment? environment,
    bool? enableDebugFeatures,
    Duration? apiTimeout,
    int? maxRetryAttempts,
  }) {
    return AppConfig(
      appName: appName ?? this.appName,
      baseUrl: baseUrl ?? this.baseUrl,
      utdStreamAppId: utdStreamAppId ?? this.utdStreamAppId,
      storageBucketUrl: storageBucketUrl ?? this.storageBucketUrl,
      domainUrl: domainUrl ?? this.domainUrl,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      appBuildNumber: appBuildNumber ?? this.appBuildNumber,
      useDeviceLocale: useDeviceLocale ?? this.useDeviceLocale,
      environment: environment ?? this.environment,
      enableDebugFeatures: enableDebugFeatures ?? this.enableDebugFeatures,
      apiTimeout: apiTimeout ?? this.apiTimeout,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
    );
  }

  @override
  String toString() {
    return 'AppConfig(appName: $appName, environment: $environment, baseUrl: $baseUrl)';
  }
}

/// Application environment
enum Environment { development, production }

/// Global app configuration instance
///
/// Initialize in main.dart before runApp:
/// ```dart
/// void main() {
///   AppConfigProvider.initialize(AppConfig.fromEnvironment());
///   runApp(MyApp());
/// }
/// ```
class AppConfigProvider {
  static AppConfig? _instance;

  /// Initialize the app configuration
  static void initialize(AppConfig config) {
    _instance = config;
  }

  /// Get the current configuration
  /// Throws if not initialized
  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig has not been initialized. '
        'Call AppConfigProvider.initialize() in main.dart',
      );
    }
    return _instance!;
  }

  /// Get configuration or null if not initialized
  static AppConfig? get instanceOrNull => _instance;

  /// Check if configuration is initialized
  static bool get isInitialized => _instance != null;
}

/// Shorthand for accessing app config
AppConfig get appConfig => AppConfigProvider.instance;
