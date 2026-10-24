import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/designsystem/app_notification.dart';
import '../../core/designsystem/theme_mode.dart';
import 'settings_notifier.dart';
import 'settings_state.dart';

final _packageInfoProvider =
    FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final info = ref.watch(_packageInfoProvider);
    final appearance = ref.watch(themeModeProvider);
    final busy = state is SettingsImporting || state is SettingsExporting;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
          top: false,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                _section(context, 'Appearance',
                    'Choose what feels right for your surroundings.'),
                Material(
                    color: t.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      for (final mode in ThemeMode.values)
                        Semantics(
                            selected: appearance == mode,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Icon(switch (mode) {
                                ThemeMode.system =>
                                  Icons.brightness_auto_outlined,
                                ThemeMode.light => Icons.light_mode_outlined,
                                ThemeMode.dark => Icons.dark_mode_outlined
                              }),
                              title: Text(switch (mode) {
                                ThemeMode.system => 'Follow system',
                                ThemeMode.light => 'Light',
                                ThemeMode.dark => 'Dark'
                              }),
                              trailing: Icon(
                                  appearance == mode
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: appearance == mode
                                      ? t.colorScheme.primary
                                      : t.colorScheme.outline),
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(mode),
                            )),
                    ])),
                _section(
                    context, 'Your library', 'Take your favourites with you.'),
                Material(
                    color: t.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    child: Column(children: [
                      ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: const Icon(Icons.playlist_add_rounded),
                          title: const Text('Import favourites'),
                          subtitle: const Text('From an M3U or M3U8 playlist'),
                          enabled: !busy,
                          trailing: state is SettingsImporting
                              ? const _Spinner()
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            ref.read(settingsNotifierProvider.notifier).reset();
                            await ref
                                .read(settingsNotifierProvider.notifier)
                                .importFavourites();
                            if (context.mounted) {
                              _showImportResult(
                                  context, ref.read(settingsNotifierProvider));
                            }
                          }),
                      const Divider(indent: 56, endIndent: 16),
                      ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: const Icon(Icons.ios_share_rounded),
                          title: const Text('Export favourites'),
                          subtitle: const Text(
                              'Share your saved stations as a playlist'),
                          enabled: !busy,
                          trailing: state is SettingsExporting
                              ? const _Spinner()
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => _runExport(context, ref)),
                    ])),
                _section(context, 'About RadioV2',
                    'A world of radio. Your own rotation.'),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.radio_rounded),
                    title: const Text('RadioV2'),
                    subtitle: const Text('Internet radio for Android'),
                    trailing: info.when(
                        data: (i) =>
                            Text(i.version, style: t.textTheme.bodySmall),
                        loading: () => const _Spinner(),
                        error: (_, __) => const Text('—'))),
              ])),
    );
  }

  Widget _section(BuildContext context, String title, String detail) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]));
  void _showImportResult(BuildContext context, SettingsUiState state) {
    if (state is SettingsImportDone) {
      AppNotification.show(
          context,
          state.added == 0
              ? 'No matching stations found in the file.'
              : '${state.added} station${state.added == 1 ? '' : 's'} added to favourites.');
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

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox.square(
      dimension: 20, child: CircularProgressIndicator(strokeWidth: 2));
}
