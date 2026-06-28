import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';

import 'package:utd_app/network/models/api_response.dart';

import '../../../audio_room_strings.dart';
import '../../../data/audio_room_api_service.dart';
import '../../../data/audio_room_remote_datasource.dart';
import '../../../domain/audio_room_repository.dart';
import '../../../data/audio_room_repository_impl.dart';
import '../../../domain/room_model.dart';
import '../overlay/audio_room_app_overlay.dart';

class EnterRoomPasswordSheet extends StatefulWidget {
  final RoomModel room;
  const EnterRoomPasswordSheet({super.key, required this.room});

  @override
  State<EnterRoomPasswordSheet> createState() => _EnterRoomPasswordSheetState();
}

class _EnterRoomPasswordSheetState extends State<EnterRoomPasswordSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  late final AudioRoomRepository _repository = AudioRoomRepositoryImpl(
    remoteDataSource: AudioRoomRemoteDataSourceImpl(
      apiService: AudioRoomApiService(),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _controller.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repository.enterRoom(
      widget.room.id,
      password: password,
    );

    if (!mounted) return;

    switch (result) {
      case Success(data: final data):
        if (data.data != null) {
          Navigator.pop(context);
          AudioRoomAppOverlay.openRoom(widget.room.id, verifiedRoom: data.data);
        } else {
          setState(() {
            _loading = false;
            _error = data.message;
          });
        }
      case Failure(message: final message):
        setState(() {
          _loading = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.w,
        right: 24.w,
        top: 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 28.r, color: primary),
          ),
          SizedBox(height: 16.h),
          Text(
            widget.room.roomName,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(AudioRoomKeys.passwordHint),
            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
          ),
          if (_error != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 13.sp, color: Colors.red),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 20,
            autofocus: true,
            textAlign: TextAlign.center,
            enabled: !_loading,
            style: TextStyle(
              fontSize: 20.sp,
              letterSpacing: 6,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: context.tr(AudioRoomKeys.enterPassword),
              hintStyle: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 22.r,
                      width: 22.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.tr(AudioRoomKeys.enter),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

/// Shows the password entry bottom sheet for a password-protected room.
void showRoomPasswordSheet(BuildContext context, RoomModel room) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => EnterRoomPasswordSheet(room: room),
  );
}
