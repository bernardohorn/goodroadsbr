import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading generico — usado enquanto listas/telas aguardam a
/// resposta da API, no lugar de um spinner central (melhor percepcao de
/// performance, requisito explicito do briefing).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.borderRadius = 8});

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerHigh,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SkeletonBox(height: 64, width: 64, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 14, width: 160),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
