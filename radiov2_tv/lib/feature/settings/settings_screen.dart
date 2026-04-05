import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../designsystem/tv_colors.dart';
import '../../designsystem/tv_focus.dart';
import 'settings_notifier.dart';
import 'settings_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);

    // Show result dialogs
    ref.listen<SettingsUiState>(settingsNotifierProvider, (_, next) {
      if (next is SettingsImportDone) {
        _showSnack(
            context, 'Added ${next.added} of ${next.total} stations to favourites.');
        ref.read(settingsNotifierProvider.notifier).reset();
      } else if (next is SettingsImportError) {
        _showSnack(context, next.message, isError: true);
        ref.read(settingsNotifierProvider.notifier).reset();
      }
    });

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 40),
          _SettingsTile(
            icon: Icons.file_upload_outlined,
            title: 'Import Favourites',
            subtitle: 'Import from an M3U or M3U8 file',
            loading: state is SettingsImporting,
            autofocus: true,
            onTap: state is SettingsImporting
                ? null
                : () => ref
                    .read(settingsNotifierProvider.notifier)
                    .importFavourites(),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: _version.isEmpty ? '…' : _version,
            onTap: null,
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? TvColors.error : TvColors.accent,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;
  final bool autofocus;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.loading = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      autofocus: autofocus,
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: TvColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: TvColors.accent, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
