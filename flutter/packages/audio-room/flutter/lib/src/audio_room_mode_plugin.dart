import 'package:flutter/material.dart';

typedef SeatWidgetBuilder = Widget Function(int seatIndex, double seatSize);

abstract class AudioRoomModePlugin {
  String get id;
  String get displayName;
  String get backendCode;
  String get rtmKey;
  int get seatCount;
  bool get isPaid;
  double get seatSizeDivisor;

  List<List<int>>? get gridRows;

  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  );

  Widget? buildRoomBackground(BuildContext context);

  Widget? buildSeatDecoration(
      BuildContext context, int seatIndex, double seatSize);
}
