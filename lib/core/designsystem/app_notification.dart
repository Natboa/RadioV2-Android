import 'package:flutter/material.dart';

/// Compact, accessible feedback shared by every in-app transient message.
class AppNotification {
  AppNotification._();
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final t = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
            icon ??
                (isError ? Icons.info_outline_rounded : Icons.check_rounded),
            size: 20,
            color: t.colorScheme.onInverseSurface),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis)),
      ]),
      action: onAction == null
          ? null
          : SnackBarAction(label: actionLabel!, onPressed: onAction),
      dismissDirection: DismissDirection.horizontal,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }
}
