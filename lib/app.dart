import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/designsystem/theme.dart';
import 'core/designsystem/colors.dart';
import 'core/providers.dart';
import 'navigation/app_router.dart';

class RadioV2App extends ConsumerWidget {
  const RadioV2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(appDatabaseProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'RadioV2',
      theme: buildRadioV2Theme(),
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
      backgroundColor: RadioV2Colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Loading RadioV2…',
              style: TextStyle(color: RadioV2Colors.onSurfaceVariant),
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
      backgroundColor: RadioV2Colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: RadioV2Colors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load database',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(message,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
