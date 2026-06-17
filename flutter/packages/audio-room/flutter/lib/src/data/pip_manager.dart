import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipManager {
  PipManager._() {
    _stateChannel.setMethodCallHandler((call) async {
      if (call.method == 'enteredPiP') {
        isInPip.value = true;
      } else if (call.method == 'exitedPiP') {
        isInPip.value = false;
      }
    });
  }

  static final instance = PipManager._();

  static const _channel = MethodChannel('pip_channel');
  static const _stateChannel = MethodChannel('pip_state_channel');

  final isInPip = ValueNotifier<bool>(false);

  Future<void> enableAutoPip() async {
    try {
      await _channel.invokeMethod('enableAutoPip');
    } on PlatformException catch (_) {}
  }

  Future<void> disableAutoPip() async {
    try {
      await _channel.invokeMethod('disableAutoPip');
    } on PlatformException catch (_) {}
  }

  Future<void> enterPip() async {
    try {
      await _channel.invokeMethod('enterPip');
    } on PlatformException catch (_) {}
  }
}
