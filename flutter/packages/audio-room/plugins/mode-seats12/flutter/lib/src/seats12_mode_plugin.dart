import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class Seats12ModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'seats12';

  @override
  String get displayName => '12 Seats';

  @override
  String get backendCode => '2';

  @override
  String get rtmKey => 'seats12';

  @override
  int get seatCount => 12;

  @override
  bool get isPaid => false;

  @override
  double get seatSizeDivisor => 4.5;

  @override
  List<List<int>>? get gridRows => const [
        [0, 1, 2, 3],
        [4, 5, 6, 7],
        [8, 9, 10, 11],
      ];

  @override
  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  ) =>
      null;

  @override
  Widget? buildRoomBackground(BuildContext context) => null;

  @override
  Widget? buildSeatDecoration(
          BuildContext context, int seatIndex, double seatSize) =>
      null;
}
