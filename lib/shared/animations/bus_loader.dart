import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BusLoaderAnimation extends StatelessWidget {
  const BusLoaderAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.directions_bus_filled,
      size: 100,
      color: Theme.of(context).colorScheme.primary,
    )
    .animate(onPlay: (controller) => controller.repeat())
    .moveX(
      begin: -100,
      end: 100,
      duration: 1.seconds,
      curve: Curves.easeInOut,
    )
    .then(delay: 0.5.seconds)
    .shimmer(duration: 0.8.seconds);
  }
}
