import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/designsystem/theme.dart';

void main() {
  test('export implemented theme roles for design documentation', () {
    String hex(Color c) =>
        '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final data = <String, Object>{};
    for (final brightness in Brightness.values) {
      final t = buildRadioV2Theme(brightness: brightness);
      final c = t.colorScheme;
      data[brightness.name] = {
        'primary': hex(c.primary),
        'onPrimary': hex(c.onPrimary),
        'primaryContainer': hex(c.primaryContainer),
        'onPrimaryContainer': hex(c.onPrimaryContainer),
        'surface': hex(c.surface),
        'surfaceContainerLow': hex(c.surfaceContainerLow),
        'surfaceContainerHigh': hex(c.surfaceContainerHigh),
        'onSurface': hex(c.onSurface),
        'onSurfaceVariant': hex(c.onSurfaceVariant),
        'error': hex(c.error),
      };
    }
    Directory('build/design').createSync(recursive: true);
    File('build/design/tokens.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  });
}
