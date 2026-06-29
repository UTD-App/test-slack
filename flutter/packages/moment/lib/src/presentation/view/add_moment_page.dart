import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import '../../../core/moment_strings.dart';
import '../bloc/moment_feed/moment_feed_bloc.dart';
import '../bloc/moment_feed/moment_feed_event.dart';
import '../bloc/moment_feed/moment_feed_state.dart';
import 'widgets/moment_avatar.dart';

/// Facebook-style "Create Post": a close/title/Post header, the author row, a
/// big free-typing area, and an "Add to your post" tray that expands into a card
/// grid or collapses to a compact icon row above the keyboard.
class AddMomentPage extends StatefulWidget {
  const AddMomentPage({super.key});

  @override
  State<AddMomentPage> createState() => _AddMomentPageState();
}

class _AddMomentPageState extends State<AddMomentPage> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final List<File> _images = [];
  final _picker = ImagePicker();

  /// Whether the "Add to your post" tray shows the full card grid (true) or the
  /// compact icon row (false).
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    // Rebuild the Post button as the user types; collapse the tray on focus.
    _text.addListener(() => setState(() {}));
    _focus.addListener(() {
      if (_focus.hasFocus && _expanded) setState(() => _expanded = false);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _hasContent => _text.text.trim().isNotEmpty || _images.isNotEmpty;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  void _toggleTray() {
    setState(() => _expanded = !_expanded);
    if (_expanded) FocusScope.of(context).unfocus();
  }

  void _submit() {
    if (!_hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(MomentStrings.writeOrPhoto))),
      );
      return;
    }
    context.read<MomentFeedBloc>().add(MomentCreated(text: _text.text.trim(), images: _images));
  }

  // Only options that actually work end-to-end. Photo/Video + Gif both open the
  // gallery (images & GIFs upload fine). Poll/Adoption/Lost-Notice/Event were
  // removed — they need dedicated backends, so no "coming soon" placeholders.
  List<_PostOption> _options() => [
        _PostOption(Icons.photo_library, const Color(0xFF1877F2), MomentStrings.photoVideo, _pickImages),
        _PostOption(Icons.gif_box, const Color(0xFF2D9CDB), MomentStrings.gif, _pickImages),
      ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDataNotifier>().user;
    final theme = Theme.of(context);

    return BlocListener<MomentFeedBloc, MomentFeedState>(
      listenWhen: (p, c) => p.isSubmitting && !c.isSubmitting,
      listener: (context, state) {
        if (state.error == null) {
          if (context.canPop()) context.pop();
        } else {
          // The create flow emits a MomentStrings.* key as the error; resolve it
          // to the active locale here (admin/server overrides win via context.tr).
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(state.error!))),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.canPop() ? context.pop() : null,
          ),
          title: Text(
            context.tr(MomentStrings.createPost),
            style: const TextStyle(
              color: ColorManager.lumiaTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: BlocBuilder<MomentFeedBloc, MomentFeedState>(
                builder: (context, state) => _PostButton(
                  enabled: _hasContent && !state.isSubmitting,
                  busy: state.isSubmitting,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
          child: Column(
            children: [
              // Author row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    MomentAvatar(image: user.profile?.image ?? '', name: user.name ?? '', radius: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              (user.name ?? '').isEmpty ? context.tr(MomentStrings.user) : user.name!,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Color(0xFF1877F2), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Free-typing area + selected photos
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    TextField(
                      controller: _text,
                      focusNode: _focus,
                      autofocus: true,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 18, height: 1.4),
                      decoration: InputDecoration(
                        hintText: context.tr(MomentStrings.whatToTalkAbout),
                        hintStyle: TextStyle(fontSize: 18, color: theme.hintColor),
                        border: InputBorder.none,
                      ),
                    ),
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (int i = 0; i < _images.length; i++)
                            Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_images[i], fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _images.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // "Add to your post" tray
              _Tray(
                expanded: _expanded,
                options: _options(),
                onToggle: _toggleTray,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// The pill "Post" button — grey/disabled until there's content, accent when ready.
class _PostButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  const _PostButton({required this.enabled, required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: enabled ? accent : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  context.tr(MomentStrings.post),
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A "Add to your post" option (icon + color + label + action).
class _PostOption {
  final IconData icon;
  final Color color;
  final String labelKey;
  final VoidCallback onTap;
  const _PostOption(this.icon, this.color, this.labelKey, this.onTap);
}

/// The bottom tray: a card grid when [expanded], a compact icon row otherwise.
class _Tray extends StatelessWidget {
  final bool expanded;
  final List<_PostOption> options;
  final VoidCallback onToggle;
  const _Tray({required this.expanded, required this.options, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: expanded ? _grid(context) : _row(context),
    );
  }

  Widget _grid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(MomentStrings.addToYourPost),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [for (final o in options) _OptionCard(option: o)],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: IconButton(
                onPressed: o.onTap,
                icon: Icon(o.icon, color: o.color, size: 26),
              ),
            ),
          GestureDetector(
            onTap: onToggle,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.keyboard_arrow_up, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single "Add to your post" card (icon chip top-left, "+" top-right, label).
class _OptionCard extends StatelessWidget {
  final _PostOption option;
  const _OptionCard({required this.option});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: option.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(option.icon, color: option.color, size: 20),
                ),
                const Icon(Icons.add, color: Colors.grey, size: 20),
              ],
            ),
            Text(context.tr(option.labelKey), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
