import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import '../../../core/reels_strings.dart';
import '../bloc/reels_feed/reels_feed_bloc.dart';
import '../bloc/reels_feed/reels_feed_event.dart';
import '../bloc/reels_feed/reels_feed_state.dart';

class AddReelPage extends StatefulWidget {
  const AddReelPage({super.key});

  @override
  State<AddReelPage> createState() => _AddReelPageState();
}

class _AddReelPageState extends State<AddReelPage> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  File? _video;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _video = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReelsFeedBloc, ReelsFeedState>(
      listenWhen: (p, c) => p.isSubmitting && !c.isSubmitting,
      listener: (context, state) {
        if (state.error == null) {
          if (context.canPop()) context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
          title: Text(
            context.tr(ReelsStrings.newReel),
            style: const TextStyle(
              color: ColorManager.lumiaTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            BlocBuilder<ReelsFeedBloc, ReelsFeedState>(
              builder: (context, state) => TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ColorManager.lumiaTextPrimary,
                ),
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        if (_video == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr(ReelsStrings.noVideoSelected))),
                          );
                          return;
                        }
                        context.read<ReelsFeedBloc>().add(
                              ReelCreated(video: _video!, description: _text.text.trim()),
                            );
                      },
                child: state.isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.tr(ReelsStrings.post)),
              ),
            ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: _video == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.video_call_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(context.tr(ReelsStrings.pickVideo), style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 48, color: Colors.green),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _video!.path.split(Platform.pathSeparator).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: context.tr(ReelsStrings.describeReel),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}
