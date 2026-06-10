import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class CouplesModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'couples';

  @override
  String get displayName => 'Couples';

  @override
  String get backendCode => '9';

  @override
  String get rtmKey => 'seats8';

  @override
  int get seatCount => 8;

  @override
  bool get isPaid => true;

  @override
  double get seatSizeDivisor => 6;

  @override
  List<List<int>>? get gridRows => null;

  @override
  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  ) {
    Widget buildCoupleGroup(int seat1, int seat2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seatBuilder(seat1, seatSize),
          const SizedBox(width: 4),
          seatBuilder(seat2, seatSize),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildCoupleGroup(0, 1),
            buildCoupleGroup(2, 3),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildCoupleGroup(4, 5),
            buildCoupleGroup(6, 7),
          ],
        ),
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
