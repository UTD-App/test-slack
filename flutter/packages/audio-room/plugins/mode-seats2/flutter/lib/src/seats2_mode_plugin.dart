import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class Seats2ModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'seats2';

  @override
  String get displayName => 'Date';

  @override
  String get backendCode => '6';

  @override
  String get rtmKey => 'seats2';

  @override
  int get seatCount => 2;

  @override
  bool get isPaid => true;

  @override
  double get seatSizeDivisor => 5;

  @override
  List<List<int>>? get gridRows => null;

  @override
  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        seatBuilder(0, seatSize),
        seatBuilder(1, seatSize),
      ],
    );
  }

  @override
  Widget? buildRoomBackground(BuildContext context) => null;

  @override
  Widget? buildSeatDecoration(
          BuildContext context, int seatIndex, double seatSize) =>
      null;
}
