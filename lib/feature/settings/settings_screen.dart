import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
            subtitle: const Text('M3U, M3U8, or JSON'),
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
            subtitle: const Text('Save as M3U or JSON'),
            trailing: state is SettingsExporting
                ? const _Spinner()
                : null,
            enabled: !isBusy,
            onTap: () => _showExportDialog(context, ref),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.added == 0
                ? 'No matching stations found in the file.'
                : '${state.added} station${state.added == 1 ? '' : 's'} added to favourites.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (state is SettingsImportError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: RadioV2Colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Export as',
                style: ctx.textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_outlined),
              title: const Text('M3U playlist'),
              subtitle: const Text('Compatible with most media players'),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(context, ref, 'm3u');
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('JSON'),
              subtitle: const Text('Compatible with RadioV2 Desktop'),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(context, ref, 'json');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    ref.read(settingsNotifierProvider.notifier).reset();
    await ref
        .read(settingsNotifierProvider.notifier)
        .exportFavourites(format);
    if (!context.mounted) return;
    final state = ref.read(settingsNotifierProvider);
    if (state is SettingsExportError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: RadioV2Colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

extension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
