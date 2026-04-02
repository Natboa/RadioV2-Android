import 'package:flutter/material.dart';
import '../../../core/model/group.dart';
import '../../designsystem/colors.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  /// Size of the square image. Also sets the card width.
  final double size;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPath(group.name);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              group.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: RadioV2Colors.onBackground,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${group.stationCount} stations',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  String _assetPath(String groupName) =>
      'assets/images/groups/$groupName.png';

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: RadioV2Colors.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.music_note,
      color: RadioV2Colors.onSurfaceVariant,
      size: 40,
    ),
  );
}
