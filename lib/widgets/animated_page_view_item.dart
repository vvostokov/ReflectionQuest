import 'package:flutter/material.dart';

class AnimatedPageViewItem extends StatelessWidget {
  final Widget child;
  final PageController pageController;
  final int index;

  const AnimatedPageViewItem({
    super.key,
    required this.child,
    required this.pageController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double page = pageController.hasClients && pageController.page != null
            ? pageController.page!
            : index.toDouble(); // Default to current index if page is not ready

        double value = page - index; // Offset from the current page

        // Define animation properties based on the offset
        // Opacity: fades out as it moves away from the center
        // Clamped to ensure values stay between 0.0 and 1.0
        final double opacity = (1 - value.abs()).clamp(0.0, 1.0);

        // Scale: shrinks as it moves away
        // Clamped to ensure values stay between 0.8 and 1.0
        final double scale = (1 - value.abs() * 0.1).clamp(0.8, 1.0);

        // Translation: slides horizontally
        // Adjust multiplier (e.g., 30) for desired slide distance
        final double translateX = value * 30;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(translateX, 0.0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: child, // The actual content to be animated
    );
  }
}