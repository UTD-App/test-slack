import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

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

  /// Rows for the mode selector preview.
  /// Defaults to [gridRows]; custom-layout plugins should override.
  List<List<int>> get previewRows =>
      gridRows ?? [List.generate(seatCount, (i) => i)];

  Widget? buildCustomLayout(
    BuildContext context,
    int roomId,
    SeatWidgetBuilder seatBuilder,
    double seatSize,
  );

  Widget? buildRoomBackground(BuildContext context);

  Widget? buildSeatDecoration(
    BuildContext context,
    int seatIndex,
    double seatSize,
  );

  UTDRoomMode toUTDRoomMode() {
    final plugin = this;
    return UTDRoomMode(
      id: backendCode,
      seatCount: seatCount,
      rows: previewRows,
      displayName: displayName,
      containerBuilder: plugin.gridRows == null
          ? (seats, seatWidgetCreator) {
              return Builder(
                builder: (context) {
                  final w = MediaQuery.sizeOf(context).width;
                  final sz = w / plugin.seatSizeDivisor;
                  Widget adapted(int i, double s) => seatWidgetCreator(i);
                  return plugin.buildCustomLayout(context, 0, adapted, sz) ??
                      const SizedBox.shrink();
                },
              );
            }
          : null,
    );
  }
}
