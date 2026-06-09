# Network Module

A comprehensive network handling module using Dio for Flutter applications.

## Features

- **Dio Client**: Singleton API client with configurable options
- **Error Handling**: Sealed class hierarchy for type-safe error handling
- **Interceptors**: Logging, authentication, and retry interceptors
- **Result Type**: Type-safe wrapper for handling success/failure states
- **Connectivity**: Network connectivity checking service

## Setup

### 1. Initialize the API Client

In your `main.dart`:

```dart
import 'package:utd_poc/network/network.dart';

void main() {
  ApiClient.initialize(
    ApiClientConfig(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      enableLogging: true,
      enableRetry: true,
      maxRetries: 3,
      getToken: () async {
        // Return your auth token
        return await SecureStorage.getToken();
      },
      onTokenExpired: () async {
        // Handle token refresh
        return await authService.refreshToken();
      },
      onLogout: () async {
        // Handle forced logout
        await authService.logout();
      },
    ),
  );

  runApp(MyApp());
}
```

### 2. Create API Services

```dart
import 'package:utd_poc/network/network.dart';

class UserApiService extends BaseApiService {
  // GET request
  Future<Result<User>> getUser(int id) async {
    return get(
      '/users/$id',
      fromJson: (data) => User.fromJson(data),
    );
  }

  // GET with query parameters
  Future<Result<List<User>>> getUsers({int page = 1, int limit = 10}) async {
    return get(
      '/users',
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (data) => (data as List).map((e) => User.fromJson(e)).toList(),
    );
  }

  // POST request
  Future<Result<User>> createUser(CreateUserRequest request) async {
    return post(
      '/users',
      data: request.toJson(),
      fromJson: (data) => User.fromJson(data),
    );
  }

  // PUT request
  Future<Result<User>> updateUser(int id, UpdateUserRequest request) async {
    return put(
      '/users/$id',
      data: request.toJson(),
      fromJson: (data) => User.fromJson(data),
    );
  }

  // DELETE request
  Future<Result<void>> deleteUser(int id) async {
    return delete('/users/$id');
  }

  // File upload with progress
  Future<Result<UploadResponse>> uploadAvatar(String filePath) async {
    return uploadFile(
      '/users/avatar',
      filePath: filePath,
      fieldName: 'avatar',
      fromJson: (data) => UploadResponse.fromJson(data),
      onProgress: (sent, total) {
        print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
      },
    );
  }
}
```

### 3. Handle Responses

Using the `Result` type:

```dart
final userApi = UserApiService();

// Pattern matching with when
final result = await userApi.getUser(1);
result.when(
  success: (user) {
    print('User: ${user.name}');
  },
  failure: (message, statusCode) {
    print('Error ($statusCode): $message');
  },
);

// Direct access
if (result.isSuccess) {
  final user = result.dataOrNull;
}

// Or throw on failure
try {
  final user = result.dataOrThrow;
} catch (e) {
  print('Error: $e');
}
```

## Error Handling

The module provides a sealed class hierarchy for network exceptions:

```dart
try {
  final response = await userApi.executeOrThrow(() => dio.get('/users'));
} on NetworkException catch (e) {
  switch (e) {
    case NoInternetException():
      showSnackBar('No internet connection');
    case UnauthorizedException():
      navigateToLogin();
    case ValidationException(:final errors):
      showValidationErrors(errors);
    case ServerException():
      showSnackBar('Server error. Please try again later.');
    case TimeoutException():
      showSnackBar('Request timed out');
    default:
      showSnackBar(e.message);
  }
}
```

Available exception types:

- `NoInternetException` - No network connectivity
- `TimeoutException` - Request timeout
- `BadRequestException` - 400 Bad Request
- `UnauthorizedException` - 401 Unauthorized
- `ForbiddenException` - 403 Forbidden
- `NotFoundException` - 404 Not Found
- `ConflictException` - 409 Conflict
- `ValidationException` - 422 Unprocessable Entity (with field errors)
- `TooManyRequestsException` - 429 Rate Limited
- `ServerException` - 5xx Server Errors
- `RequestCancelledException` - Request was cancelled
- `UnknownException` - Other errors

## Connectivity Checking

```dart
final connectivityService = ConnectivityService();

// Check current connectivity
if (await connectivityService.hasConnection()) {
  // Make API call
}

// Listen to connectivity changes
connectivityService.onConnectivityChanged.listen((hasConnection) {
  if (hasConnection) {
    syncData();
  } else {
    showOfflineMode();
  }
});

// Get connection type
final type = await connectivityService.getConnectivityType();
switch (type) {
  case ConnectivityType.wifi:
    // On WiFi
  case ConnectivityType.mobile:
    // On mobile data
  case ConnectivityType.none:
    // Offline
}
```

## Interceptors

### Logging Interceptor

Automatically logs requests and responses in debug mode:

```
┌───────────────────────────────────────────────────────
│ 🌐 REQUEST: GET https://api.example.com/users/1
├───────────────────────────────────────────────────────
│ Headers:
│   Authorization: [REDACTED]
│   Content-Type: application/json
└───────────────────────────────────────────────────────

┌───────────────────────────────────────────────────────
│ ✅ RESPONSE: 200 GET https://api.example.com/users/1
├───────────────────────────────────────────────────────
│ Body: {"id": 1, "name": "John Doe"}
└───────────────────────────────────────────────────────
```

### Auth Interceptor

- Automatically adds auth token to requests
- Handles token refresh on 401 responses
- Queues requests during token refresh
- Triggers logout callback when refresh fails

### Retry Interceptor

- Automatically retries failed requests
- Configurable retry count and delay
- Retries on timeout and server errors (500, 502, 503, 504)

## Advanced Usage

### Custom Interceptors

```dart
class CustomInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add custom header
    options.headers['X-App-Version'] = '1.0.0';
    handler.next(options);
  }
}

// Add to client
ApiClient.instance.addInterceptor(CustomInterceptor());
```

### Skip Authentication

```dart
return get(
  '/public/endpoint',
  options: Options(extra: {'skipAuth': true}),
);
```

### Disable Retry

```dart
return get(
  '/realtime/endpoint',
  options: Options(extra: {'disableRetry': true}),
);
```

### Cancel Requests

```dart
final cancelToken = CancelToken();

// Start request
final result = userApi.getUsers(cancelToken: cancelToken);

// Cancel when needed
cancelToken.cancel('User navigated away');
```
