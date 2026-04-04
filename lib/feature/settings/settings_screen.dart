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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Import favourites ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Favourites',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: RadioV2Colors.accent,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('Import favourites'),
            subtitle: const Text('Supports M3U, M3U8, and JSON files'),
            trailing: state is SettingsImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            enabled: state is! SettingsImporting,
            onTap: () async {
              ref.read(settingsNotifierProvider.notifier).reset();
              await ref
                  .read(settingsNotifierProvider.notifier)
                  .importFavourites();

              if (!context.mounted) return;
              final result = ref.read(settingsNotifierProvider);
              if (result is SettingsImportDone) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.added == 0
                          ? 'No matching stations found in the file.'
                          : '${result.added} station${result.added == 1 ? '' : 's'} added to favourites.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (result is SettingsImportError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: RadioV2Colors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const Divider(height: 32),

          // ── App info ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: RadioV2Colors.accent,
                letterSpacing: 1.1,
              ),
            ),
          ),
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
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text('—'),
            ),
          ),
        ],
      ),
    );
  }
}
