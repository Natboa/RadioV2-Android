import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/designsystem/app_notification.dart';
import '../../core/designsystem/colors.dart';
import 'settings_notifier.dart';
import 'settings_state.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final packageInfo = ref.watch(_packageInfoProvider);
    final isBusy =
        state is SettingsImporting || state is SettingsExporting;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Favourites section ─────────────────────────────────────────
          _SectionLabel('Favourites'),

          // Import
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('Import favourites'),
            subtitle: const Text('M3U or M3U8 playlist'),
            trailing: state is SettingsImporting
                ? const _Spinner()
                : null,
            enabled: !isBusy,
            onTap: () async {
              ref.read(settingsNotifierProvider.notifier).reset();
              await ref
                  .read(settingsNotifierProvider.notifier)
                  .importFavourites();
              if (!context.mounted) return;
              _showImportResult(context, ref.read(settingsNotifierProvider));
            },
          ),

          // Export
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('Export favourites'),
            subtitle: const Text('Share as M3U playlist'),
            trailing: state is SettingsExporting
                ? const _Spinner()
                : null,
            enabled: !isBusy,
            onTap: () => _runExport(context, ref),
          ),

          const Divider(height: 32),

          // ── About section ──────────────────────────────────────────────
          _SectionLabel('About'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: packageInfo.when(
              data: (info) => Text(
                info.version,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RadioV2Colors.onSurfaceVariant,
                ),
              ),
              loading: () => const _Spinner(),
              error: (_, __) => const Text('—'),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportResult(BuildContext context, SettingsUiState state) {
    if (state is SettingsImportDone) {
      AppNotification.show(
        context,
        state.added == 0
            ? 'No matching stations found in the file.'
            : '${state.added} station${state.added == 1 ? '' : 's'} added to favourites.',
      );
    } else if (state is SettingsImportError) {
      AppNotification.show(context, state.message, isError: true);
    }
  }

  Future<void> _runExport(BuildContext context, WidgetRef ref) async {
    ref.read(settingsNotifierProvider.notifier).reset();
    await ref.read(settingsNotifierProvider.notifier).exportFavourites();
    if (!context.mounted) return;
    final state = ref.read(settingsNotifierProvider);
    if (state is SettingsExportError) {
      AppNotification.show(context, state.message, isError: true);
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: RadioV2Colors.accent,
            letterSpacing: 1.1,
          ),
        ),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}

