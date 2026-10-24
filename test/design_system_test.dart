import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:radiov2_android/core/designsystem/theme.dart';
import 'package:radiov2_android/core/designsystem/theme_mode.dart';
import 'package:radiov2_android/core/providers.dart';
import 'package:radiov2_android/core/model/group.dart';
import 'package:radiov2_android/core/ui/widgets/group_card.dart';
import 'package:radiov2_android/core/ui/widgets/sound_bars.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('$brightness text and accent roles are accessible', () {
      final c = buildRadioV2Theme(brightness: brightness).colorScheme;
      expect(c.brightness, brightness);
      for (final pair in [
        [c.onSurface, c.surface],
        [c.onSurfaceVariant, c.surface],
        [c.primary, c.surface],
        [c.onPrimary, c.primary],
        [c.onPrimaryContainer, c.primaryContainer],
      ]) {
        expect(contrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5));
      }
      expect(c.primary, isNot(const Color(0xFFE81C9B)));
    });
  }

  test('appearance defaults to system and persists an explicit choice',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.system);
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    final reopened = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(reopened.dispose);
    expect(reopened.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('genre artwork stays square, contained and decode-bounded',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: GroupCard(
          group: const Group(id: 1, name: 'Jazz'), onTap: () {}, size: 144),
    ))));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 144);
    expect(image.height, 144);
    expect(image.fit, BoxFit.contain);
    expect(image.image, isA<ResizeImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion leaves no repeating sound-bar ticker',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: SoundBars(isAnimating: true),
    )));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.transientCallbackCount, 0);
  });
}
