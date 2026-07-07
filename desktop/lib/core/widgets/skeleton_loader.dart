import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading generico — usado enquanto listas/telas aguardam a
/// resposta da API, no lugar de um spinner central (melhor percepcao de
/// performance).
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(borderRadius)),
      ),
    );
  }
}

class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonBox(height: 14, width: 90),
          SizedBox(width: 24),
          SkeletonBox(height: 14, width: 160),
          SizedBox(width: 24),
          SkeletonBox(height: 22, width: 100, borderRadius: 20),
          SizedBox(width: 24),
          SkeletonBox(height: 14, width: 120),
        ],
      ),
    );
  }
}
