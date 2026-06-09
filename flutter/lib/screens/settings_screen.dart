import 'package:authentication/core/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../cache/cache_manager.dart';
import '../config/theme_notifier.dart';
import '../localization/localization.dart';
import '../shared/notifiers/user_data_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('app.are_you_sure')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('app.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('app.confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await CacheManager.clear();
    if (!mounted) return;
    context.go(AuthRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final localeNotifier = context.watch<LocaleNotifier>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final user = context.watch<UserDataNotifier>().user;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(context.tr('app.settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              // Open the rich profile view (registered by the profile package
              // at /user-profile/:id). The view has its own "Edit Profile"
              // button that opens the /profile edit form.
              onTap: () => context.push('/user-profile/${user.id ?? 0}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: user.profile?.image != null &&
                              user.profile!.image!.isNotEmpty
                          ? NetworkImage(user.profile!.image!)
                          : null,
                      backgroundColor: colors.primaryContainer,
                      child: user.profile?.image == null ||
                              user.profile!.image!.isEmpty
                          ? Icon(Icons.person, size: 28, color: colors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? context.tr('app.profile'),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (user.email != null && user.email!.isNotEmpty)
                            Text(
                              user.email!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: colors.outline),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Language
          _sectionHeader(context.tr('app.language'), textTheme),
          Card(
            child: Column(
              children: localeNotifier.supportedLocales.map((locale) {
                final isSelected =
                    locale.languageCode == localeNotifier.locale.languageCode;
                final label = locale.languageCode == 'ar'
                    ? context.tr('app.arabic')
                    : context.tr('app.english');
                return ListTile(
                  title: Text(label),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: colors.primary)
                      : null,
                  onTap: () => localeNotifier.setLocale(locale),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Theme
          _sectionHeader(context.tr('app.theme'), textTheme),
          Card(
            child: SwitchListTile(
              title: Text(context.tr('app.dark_mode')),
              secondary: Icon(
                themeNotifier.isDark ? Icons.dark_mode : Icons.light_mode,
              ),
              value: themeNotifier.isDark,
              onChanged: (_) => themeNotifier.toggle(),
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: colors.error),
              title: Text(
                context.tr('app.logout'),
                style: TextStyle(color: colors.error),
              ),
              onTap: _logout,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
