import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/network/client/api_client.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserDataNotifier>().user;
    _nameController = TextEditingController(text: user.name ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ApiClient.instance.dio.post(
        '/profile/update',
        data: FormData.fromMap({
          'name': name,
          'bio': _bioController.text.trim(),
        }),
      );
      if (mounted) {
        context.read<UserDataNotifier>().update(
              name: name,
              bio: _bioController.text.trim(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('app.success'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('app.error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDataNotifier>().user;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('app.profile')),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('app.save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.profile?.image != null &&
                          user.profile!.image!.isNotEmpty
                      ? NetworkImage(user.profile!.image!)
                      : null,
                  child: user.profile?.image == null ||
                          user.profile!.image!.isEmpty
                      ? Icon(Icons.person, size: 50, color: colors.outline)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '',
                  style: textTheme.bodyMedium?.copyWith(color: colors.outline),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Name
          Text(context.tr('app.name'), style: textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bio
          Text(context.tr('app.bio'), style: textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
