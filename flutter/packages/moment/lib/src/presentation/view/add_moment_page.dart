import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../core/moment_strings.dart';
import '../bloc/moment_feed/moment_feed_bloc.dart';
import '../bloc/moment_feed/moment_feed_event.dart';
import '../bloc/moment_feed/moment_feed_state.dart';

class AddMomentPage extends StatefulWidget {
  const AddMomentPage({super.key});

  @override
  State<AddMomentPage> createState() => _AddMomentPageState();
}

class _AddMomentPageState extends State<AddMomentPage> {
  final _text = TextEditingController();
  final List<File> _images = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MomentFeedBloc, MomentFeedState>(
      listenWhen: (p, c) => p.isSubmitting && !c.isSubmitting,
      listener: (context, state) {
        if (state.error == null) {
          if (context.canPop()) context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(MomentStrings.newMoment)),
          actions: [
            BlocBuilder<MomentFeedBloc, MomentFeedState>(
              builder: (context, state) => TextButton(
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        if (_text.text.trim().isEmpty && _images.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr(MomentStrings.writeOrPhoto))),
                          );
                          return;
                        }
                        context.read<MomentFeedBloc>().add(
                              MomentCreated(text: _text.text.trim(), images: _images),
                            );
                      },
                child: state.isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.tr(MomentStrings.post)),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _text,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: context.tr(MomentStrings.whatsOnMind),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty)
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (int i = 0; i < _images.length; i++)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_images[i], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(context.tr(MomentStrings.addPhotos)),
            ),
          ],
        ),
      ),
    );
  }
}
