import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Seats8ModePlugin extends AudioRoomModePlugin {
  @override
  String get id => 'seats8';

  @override
  String get displayName => '8 Seats';

  @override
  String get backendCode => '8';

  @override
  String get rtmKey => 'eight';

  @override
  int get seatCount => 8;

  @override
  bool get isPaid => false;

  @override
  double get seatSizeDivisor => 5.5;

  @override
  List<List<int>>? get gridRows => null;

  @override
  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  ) {
    return SizedBox(
      height: seatSize * 4,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Row 1 (top): seats 0-1
          Positioned(
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 85.w),
                  child: seatBuilder(0, seatSize),
                ),
                seatBuilder(1, seatSize),
              ],
            ),
          ),
          // Row 2: seats 2-3
          Positioned(
            top: 35.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 25.w),
                  child: seatBuilder(2, seatSize),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 25.w),
                  child: seatBuilder(3, seatSize),
                ),
              ],
            ),
          ),
          // Row 3: seats 4-5
          Positioned(
            top: 105.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 15.w),
                  child: seatBuilder(4, seatSize),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15.w),
                  child: seatBuilder(5, seatSize),
                ),
              ],
            ),
          ),
          // Row 4 (bottom): seats 6-7
          Positioned(
            top: 180.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 15.w),
                  child: seatBuilder(6, seatSize),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15.w),
                  child: seatBuilder(7, seatSize),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildRoomBackground(BuildContext context) => null;

  @override
  Widget? buildSeatDecoration(
          BuildContext context, int seatIndex, double seatSize) =>
      null;
}
