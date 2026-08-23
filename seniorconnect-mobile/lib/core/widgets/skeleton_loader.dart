import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF21262D) : const Color(0xFFE2E9EC);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceContainer : AppTheme.surfaceContainerLowest;
    final border = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 80, height: 22, borderRadius: 9999),
              Spacer(),
              ShimmerBox(width: 60, height: 18, borderRadius: 6),
            ],
          ),
          SizedBox(height: 14),
          ShimmerBox(width: double.infinity, height: 18, borderRadius: 6),
          SizedBox(height: 8),
          ShimmerBox(width: 220, height: 14, borderRadius: 6),
          SizedBox(height: 14),
          Row(
            children: [
              ShimmerBox(width: 65, height: 22, borderRadius: 6),
              SizedBox(width: 8),
              ShimmerBox(width: 65, height: 22, borderRadius: 6),
              Spacer(),
              ShimmerBox(width: 45, height: 14, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceContainer : AppTheme.surfaceContainerLowest;
    final border = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonFeedList extends StatelessWidget {
  final int count;

  const SkeletonFeedList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
