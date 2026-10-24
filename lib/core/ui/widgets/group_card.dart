import 'package:flutter/material.dart';
import '../../model/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final double size;
  const GroupCard(
      {super.key, required this.group, required this.onTap, this.size = 144});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pixels =
        (size * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(1, 1024);
    return Semantics(
      button: true,
      label: '${group.name}, ${group.stationCount} stations',
      child: SizedBox(
          width: size,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: ExcludeSemantics(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/groups/${group.name}.png',
                          width: size,
                          height: size,
                          cacheWidth: pixels,
                          cacheHeight: pixels,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => SizedBox.square(
                              dimension: size,
                              child: ColoredBox(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  child: Icon(Icons.music_note_rounded,
                                      size: 40,
                                      color:
                                          theme.colorScheme.onSurfaceVariant))),
                        )),
                    const SizedBox(height: 10),
                    Text(group.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${group.stationCount} stations',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ])),
            ),
          )),
    );
  }
}
