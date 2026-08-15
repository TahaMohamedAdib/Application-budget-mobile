import 'package:flutter/material.dart';

/// Page transition used for every pushed route in the app.
///
/// The slide, the outgoing-page parallax and — importantly — the iOS
/// interactive back-swipe all come from [CupertinoPageTransitionsBuilder], so
/// this delegates to it rather than reimplementing it. On top of that it eases
/// the incoming page in with a short fade, which takes the hard edge off the
/// push and makes the arrival feel settled rather than snapped into place.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  static const PageTransitionsBuilder _base = CupertinoPageTransitionsBuilder();

  /// Drives the *outgoing* page. Forwarded so the page being covered keeps its
  /// parallax slide instead of sitting still.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _base.delegatedTransition;

  @override
  Duration get transitionDuration => _base.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _base.reverseTransitionDuration;

  // Front-loaded so the page is fully opaque well before the slide settles —
  // a fade running the whole way reads as sluggish rather than smooth.
  static final Animatable<double> _fade =
      CurveTween(curve: const Interval(0, 0.55, curve: Curves.easeOutCubic));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _base.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      // `drive` rather than CurvedAnimation: it needs no disposal, so it is
      // safe to build one per frame here.
      FadeTransition(opacity: animation.drive(_fade), child: child),
    );
  }
}
