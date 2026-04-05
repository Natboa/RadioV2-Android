import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'designsystem/tv_colors.dart';
import 'designsystem/tv_theme.dart';
import 'navigation/tv_router.dart';

class RadioV2TvApp extends ConsumerWidget {
  const RadioV2TvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(appDatabaseProvider);
    final router = ref.watch(tvRouterProvider);

    return MaterialApp.router(
      title: 'RadioV2 TV',
      theme: buildTvTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) => dbState.when(
        loading: () => const _LoadingScreen(),
        error: (e, _) => _ErrorScreen(message: e.toString()),
        data: (_) => child!,
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TvColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Loading RadioV2…',
              style: TextStyle(color: TvColors.onSurfaceVariant, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: TvColors.error, size: 64),
              const SizedBox(height: 24),
              Text(
                'Failed to load database',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
