import 'package:flutter/material.dart';

import 'colors.dart';

/// Centralised in-app notification (toast) helper.
///
/// Shows a floating banner that sits just above the bottom navigation bar —
/// i.e. where the content list ends, not on top of the buttons — and can be
/// dismissed by swiping it horizontally to either side instead of waiting for
/// the auto-dismiss timeout.
///
/// Use this for every transient message that pops up inside the app so they all
/// look and behave the same way.
class AppNotification {
  AppNotification._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // Clear any in-flight banner so messages don't stack up.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        // Chevrons on both edges hint that the banner can be swiped away
        // to either side.
        content: Row(
          children: [
            const Icon(Icons.keyboard_double_arrow_left, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_double_arrow_right, size: 18, color: Colors.white70),
          ],
        ),
        backgroundColor: isError ? RadioV2Colors.error : RadioV2Colors.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        // Swipe to either side to dismiss.
        dismissDirection: DismissDirection.horizontal,
        duration: duration,
        // Keep it tight to the bottom so it lands where the list ends,
        // just above the navigation buttons.
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
    );
  }
}
