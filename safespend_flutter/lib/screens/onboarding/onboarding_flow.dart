import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'hook_screen.dart';
import 'aha_screen.dart';
import 'preview_screen.dart';
import 'setup_screen.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentScreen = 0;

  void _nextScreen() {
    if (_currentScreen < 4) {
      setState(() => _currentScreen++);
    }
  }

  void _previousScreen() {
    if (_currentScreen > 0) {
      setState(() => _currentScreen--);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 0:
        return WelcomeScreen(onNext: _nextScreen);
      case 1:
        return HookScreen(onNext: _nextScreen, onBack: _previousScreen);
      case 2:
        return AhaScreen(onNext: _nextScreen, onBack: _previousScreen);
      case 3:
        return PreviewScreen(onNext: _nextScreen, onBack: _previousScreen);
      case 4:
        return SetupScreen(onComplete: widget.onComplete, onBack: _previousScreen);
      default:
        return WelcomeScreen(onNext: _nextScreen);
    }
  }
}
