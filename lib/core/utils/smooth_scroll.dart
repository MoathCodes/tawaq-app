import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class SmoothDesktopScrollPhysics extends ScrollPhysics {
  /// Controls the stiffness of the bounce animation
  static const SpringDescription _kDefaultSpring = SpringDescription(
    mass: 0.5,
    stiffness: 100.0,
    damping: 20.0,
  );

  const SmoothDesktopScrollPhysics({super.parent});

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // This is key to enable overscroll - we must follow Flutter's contract
    // by never returning a value with magnitude greater than the delta
    if (value < position.minScrollExtent) {
      final double delta = value - position.minScrollExtent;
      return delta;
    }
    if (value > position.maxScrollExtent) {
      final double delta = value - position.maxScrollExtent;
      return delta;
    }
    return 0.0;
  }

  /// This method is called when the user scrolls with a mouse wheel or trackpad
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Base damping for smoother initial feel
    const double baseDampingFactor = 0.75;
    double finalOffset = offset * baseDampingFactor;

    // Apply progressive resistance when overscrolling
    if ((offset > 0 && position.pixels <= position.minScrollExtent) ||
        (offset < 0 && position.pixels >= position.maxScrollExtent)) {
      final double overscrollFraction = (position.pixels -
                  (offset > 0
                      ? position.minScrollExtent
                      : position.maxScrollExtent))
              .abs() /
          position.viewportDimension;

      // Apply increasing resistance as overscroll increases
      finalOffset *= _applyResistance(overscrollFraction);
    }

    return finalOffset;
  }

  @override
  SmoothDesktopScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothDesktopScrollPhysics(parent: buildParent(ancestor));
  }

  /// Creates the simulation for bounce-back and fling behaviors
  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // For smooth bounce when overscrolled
    if (position.pixels < position.minScrollExtent ||
        position.pixels > position.maxScrollExtent) {
      // Target position for bounce-back
      final double target = position.pixels < position.minScrollExtent
          ? position.minScrollExtent
          : position.maxScrollExtent;

      // Apply mild velocity adjustment for smoother bounce
      double adjustedVelocity = velocity * 0.4;

      // Create spring simulation with macOS-like parameters
      return SpringSimulation(
        _kDefaultSpring,
        position.pixels,
        target,
        adjustedVelocity,
      );
    }

    // Detect if we should create a simulation for normal fling
    final double targetPixels = position.pixels + 0.5 * velocity;
    if (targetPixels.abs() < 1.0 ||
        targetPixels < position.minScrollExtent ||
        targetPixels > position.maxScrollExtent) {
      // If we're very close to stopping or would fling beyond bounds, let default physics handle it
      return super.createBallisticSimulation(position, velocity);
    }

    // For normal fling, create a smoother simulation with reduced velocity
    return super.createBallisticSimulation(position, velocity * 0.8);
  }

  /// Apply progressively stronger resistance as user scrolls beyond boundaries
  double _applyResistance(double overscrollFraction) {
    // This provides the macOS-like resistance curve
    return 0.52 * math.pow(1 - math.min((overscrollFraction).abs(), 0.9), 2);
  }
}
