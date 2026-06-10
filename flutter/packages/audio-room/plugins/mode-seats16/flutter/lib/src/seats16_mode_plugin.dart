import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class Seats16ModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'seats16';

  @override
  String get displayName => 'Party';

  @override
  String get backendCode => '1';

  @override
  String get rtmKey => 'party';

  @override
  int get seatCount => 16;

  @override
  bool get isPaid => false;

  @override
  double get seatSizeDivisor => 5;

  @override
  List<List<int>>? get gridRows => const [
        [0, 1, 2, 3],
        [4, 5, 6, 7],
        [8, 9, 10, 11],
        [12, 13, 14, 15],
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
