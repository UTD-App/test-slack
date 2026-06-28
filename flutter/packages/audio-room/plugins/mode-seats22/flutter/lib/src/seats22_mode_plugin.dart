import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class Seats22ModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'seats22';

  @override
  String get displayName => '22 Seats';

  @override
  String get backendCode => '7';

  @override
  String get rtmKey => 'seats22';

  @override
  int get seatCount => 22;

  @override
  bool get isPaid => true;

  @override
  double get seatSizeDivisor => 3;

  @override
  List<List<int>>? get gridRows => null;

  @override
  List<List<int>> get previewRows => const [
    [0],
    [1],
    [2, 3, 4, 5, 6],
    [7, 8, 9, 10, 11],
    [12, 13, 14, 15, 16],
    [17, 18, 19, 20, 21],
  ];

  @override
  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  ) {
    final rowGap = seatSize * 0.05;

    Widget buildRow(List<int> indices) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: indices.map((i) => seatBuilder(i, seatSize)).toList(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        seatBuilder(0, seatSize),
        SizedBox(height: rowGap),
        Align(
          alignment: Alignment.centerRight,
          child: seatBuilder(1, seatSize),
        ),
        SizedBox(height: rowGap),
        buildRow([2, 3, 4, 5, 6]),
        SizedBox(height: rowGap),
        buildRow([7, 8, 9, 10, 11]),
        SizedBox(height: rowGap),
        buildRow([12, 13, 14, 15, 16]),
        SizedBox(height: rowGap),
        buildRow([17, 18, 19, 20, 21]),
      ],
    );
  }

  @override
  Widget? buildRoomBackground(BuildContext context) => null;

  @override
  Widget? buildSeatDecoration(
    BuildContext context,
    int seatIndex,
    double seatSize,
  ) => null;
}
