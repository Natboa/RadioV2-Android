import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/designsystem/theme.dart';
import 'navigation/app_router.dart';

class RadioV2App extends ConsumerWidget {
  const RadioV2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'RadioV2',
      theme: buildRadioV2Theme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
