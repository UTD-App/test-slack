import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for checking network connectivity
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Check if the device has an internet connection
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveConnection(results);
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasActiveConnection);
  }

  /// Get current connectivity type
  Future<ConnectivityType> getConnectivityType() async {
    final results = await _connectivity.checkConnectivity();
    return _mapToConnectivityType(results);
  }

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  ConnectivityType _mapToConnectivityType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityType.mobile;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityType.ethernet;
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return ConnectivityType.vpn;
    }
    return ConnectivityType.none;
  }
}

/// Type of network connectivity
enum ConnectivityType { wifi, mobile, ethernet, vpn, none }
