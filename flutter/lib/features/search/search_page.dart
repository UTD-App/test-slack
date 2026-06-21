import 'dart:async';

import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/profile/profile_navigator.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import 'search_api_service.dart';
import 'search_user_model.dart';

/// User search reached from the home top bar. Type a name or a UID; results are
/// fetched (debounced) from `GET /users/search` and shown as user cells
/// (avatar + name + UID). Tapping a result opens that user's profile.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchApiService _api = SearchApiService();
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  String _query = '';
  List<SearchUser> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() {
      _query = query;
      _error = null;
    });

    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final result = await _api.searchUsers(query);
    if (!mounted) return;

    result.when(
      success: (users) => setState(() {
        _results = users;
        _loading = false;
      }),
      failure: (message, _) => setState(() {
        _error = message;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: _SearchField(
          controller: _controller,
          hint: context.tr('app.search_users_hint'),
          onChanged: _onChanged,
          onClear: () {
            _controller.clear();
            _search('');
          },
        ),
      ),
      body: GradientBackground(
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorManager.lumiaAccentLight),
      );
    }

    if (_error != null) {
      return _Centered(
        icon: Icons.error_outline,
        iconColor: ColorManager.walletRed,
        title: context.tr('app.error'),
        action: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ColorManager.lumiaAccent,
          ),
          onPressed: () => _search(_query),
          child: Text(context.tr('app.retry')),
        ),
      );
    }

    if (_query.isEmpty) {
      return _Centered(
        icon: Icons.search,
        iconColor: ColorManager.lumiaTextSecondary,
        title: context.tr('app.search_users_hint'),
      );
    }

    if (_results.isEmpty) {
      return _Centered(
        icon: Icons.person_search_outlined,
        iconColor: ColorManager.lumiaTextSecondary,
        title: context.tr('app.no_results'),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        color: ColorManager.frostedBorder,
      ),
      itemBuilder: (context, i) => _UserResultTile(
        user: _results[i],
        onTap: () => ProfileNavigator.open(context, userId: _results[i].id),
      ),
    );
  }
}

/// The search input shown in the app bar.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: ColorManager.lumiaTextPrimary),
      cursorColor: ColorManager.lumiaAccentLight,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: ColorManager.lumiaTextSecondary),
        prefixIcon: const Icon(Icons.search, color: ColorManager.lumiaTextSecondary),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close,
                      color: ColorManager.lumiaTextSecondary),
                  onPressed: onClear,
                ),
        ),
        filled: true,
        fillColor: ColorManager.lumiaCardBg.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// A single search result: avatar + name + UID (the user-cell convention).
class _UserResultTile extends StatelessWidget {
  final SearchUser user;
  final VoidCallback onTap;

  const _UserResultTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: ColorManager.lumiaCardBg,
        backgroundImage:
            user.image != null ? NetworkImage(user.image!) : null,
        child: user.image == null
            ? Text(
                initial,
                style: const TextStyle(
                  color: ColorManager.lumiaTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ColorManager.lumiaTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${context.tr('app.uid')}: ${user.uuid}',
        style: const TextStyle(color: ColorManager.lumiaTextSecondary),
      ),
      trailing: user.isOnline
          ? const Icon(Icons.circle, size: 10, color: Color(0xFF4CAF50))
          : null,
    );
  }
}

/// A centered empty/error placeholder.
class _Centered extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? action;

  const _Centered({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorManager.lumiaTextPrimary,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
