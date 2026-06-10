import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class CinemaModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'cinema';

  @override
  String get displayName => 'Cinema';

  @override
  String get backendCode => '5';

  @override
  String get rtmKey => 'cinema';

  @override
  int get seatCount => 8;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // YouTube player placeholder — replaced with actual player during integration
        Container(
          height: MediaQuery.of(context).size.height * 0.33,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 48),
          ),
        ),
        const SizedBox(height: 10),
        // Row 1: seats 0-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (i) => seatBuilder(i, seatSize)),
        ),
        const SizedBox(height: 5),
        // Row 2: seats 4-7
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (i) => seatBuilder(i + 4, seatSize)),
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
