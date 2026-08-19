import 'package:flutter/material.dart';

import 'aha_screen.dart';
import 'hook_screen.dart';
import 'language_selection_screen.dart';
import 'preview_screen.dart';
import 'setup_screen.dart';
import 'welcome_screen.dart';

/// Drives the first-run sequence.
///
/// Screens are held in a list rather than a `switch` over an index, so the
/// bounds follow the list instead of a literal that has to be remembered — the
/// previous version hardcoded `< 5` next to six screens, which meant adding one
/// silently made it unreachable.
class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _index = 0;

  /// Which way the next transition should slide. Going back reverses it, so
  /// the flow feels like a stack rather than a shuffle.
  bool _forward = true;

  late final List<Widget Function()> _screens = [
    () => WelcomeScreen(onNext: _next),
    () => LanguageSelectionScreen(onNext: _next, onBack: _previous),
    () => HookScreen(onNext: _next, onBack: _previous),
    () => AhaScreen(onNext: _next, onBack: _previous),
    () => PreviewScreen(onNext: _next, onBack: _previous),
    () => SetupScreen(onComplete: widget.onComplete, onBack: _previous),
  ];

  void _next() {
    if (_index >= _screens.length - 1) return;
    setState(() {
      _forward = true;
      _index++;
    });
  }

  void _previous() {
    if (_index == 0) return;
    setState(() {
      _forward = false;
      _index--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The flow owns its own back navigation; letting the system pop would
      // drop the user out of setup entirely rather than back one step.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previous();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final entering = child.key == ValueKey(_index);
          final begin = Offset(
            (entering == _forward ? 1 : -1) * 0.06,
            0,
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween(begin: begin, end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index](),
        ),
      ),
    );
  }
}
