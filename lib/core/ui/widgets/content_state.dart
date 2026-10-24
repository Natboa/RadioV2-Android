import 'package:flutter/material.dart';

class ContentState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const ContentState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: BoxShape.circle),
                    child: Icon(icon,
                        size: 32, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Text(title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (onAction != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                      onPressed: onAction, child: Text(actionLabel!))
                ],
              ]),
            )));
  }
}
