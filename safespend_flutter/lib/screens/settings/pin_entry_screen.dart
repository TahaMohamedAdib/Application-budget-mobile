import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_lock_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/settings_ui.dart';

enum PinMode {
  /// Enter a new PIN, then repeat it.
  create,

  /// Enter the existing PIN to prove ownership.
  verify,
}

/// Numeric PIN pad.
///
/// Used two ways, which is why the result is reported through a callback
/// rather than only by popping:
///
/// * **Pushed as a route** (from Settings) — [onCompleted] is null, so it pops
///   with `true` once the PIN is set or matched, `false` if the user backs out.
/// * **Rendered directly** by the app-lock gate, which sits above the
///   Navigator and therefore cannot be popped — it passes [onCompleted] and
///   sets [dismissible] to false so there is no way past the lock.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({
    super.key,
    required this.mode,
    this.onCompleted,
    this.dismissible = true,
  });

  final PinMode mode;

  /// Called with the result instead of popping, when provided.
  final ValueChanged<bool>? onCompleted;

  /// Whether the close affordance is shown.
  final bool dismissible;

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _entry = '';
  String? _firstPass;
  String? _error;
  bool _busy = false;

  static const _length = AppLockService.pinLength;

  Future<void> _onDigit(String d) async {
    if (_busy || _entry.length >= _length) return;
    setState(() {
      _entry += d;
      _error = null;
    });
    if (_entry.length == _length) await _submit();
  }

  void _onDelete() {
    if (_busy || _entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  /// Reports the outcome the way this instance was configured for.
  void _finish(bool result) {
    final callback = widget.onCompleted;
    if (callback != null) {
      callback(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    // Let the final dot paint before the screen changes under the user.
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    final s = S.of(context);

    if (widget.mode == PinMode.verify) {
      final ok = await AppLockService.instance.verifyPin(_entry);
      if (!mounted) return;
      if (ok) {
        _finish(true);
        return;
      }
      HapticFeedback.heavyImpact();
      setState(() {
        _entry = '';
        _error = s.pinIncorrect;
        _busy = false;
      });
      return;
    }

    // Create: first pass captures, second pass must match.
    if (_firstPass == null) {
      setState(() {
        _firstPass = _entry;
        _entry = '';
        _busy = false;
      });
      return;
    }

    if (_firstPass != _entry) {
      HapticFeedback.heavyImpact();
      setState(() {
        _entry = '';
        _firstPass = null;
        _error = s.pinMismatch;
        _busy = false;
      });
      return;
    }

    await AppLockService.instance.setPin(_entry);
    if (!mounted) return;
    _finish(true);
  }

  String _title(S s) {
    if (widget.mode == PinMode.verify) return s.enterPin;
    return _firstPass == null ? s.setPin : s.confirmPin;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: widget.dismissible
                  ? IconButton(
                      icon: Icon(IOSIcons.close_rounded,
                          color: AppTheme.adaptiveIcon(context)),
                      onPressed: () => _finish(false),
                    )
                  : const SizedBox(height: 48),
            ),
            const Spacer(),
            Icon(IOSIcons.lock_rounded,
                size: 30, color: AppTheme.adaptiveIcon(context)),
            const SizedBox(height: 16),
            Text(
              _title(s),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 20,
              child: Text(
                _error ?? s.pinHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _error == null ? null : AppTheme.error,
                    ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_length, (i) {
                final filled = i < _entry.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  width: filled ? 15 : 13,
                  height: filled ? 15 : 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.adaptiveIcon(context, alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            _Keypad(onDigit: _onDigit, onDelete: _onDelete),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Column(
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', '<'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((key) {
                  if (key.isEmpty) return const SizedBox(width: 74, height: 66);
                  if (key == '<') {
                    return _Key(
                      onTap: onDelete,
                      child: Icon(IOSIcons.arrow_back_rounded,
                          size: 22, color: AppTheme.adaptiveIcon(context)),
                    );
                  }
                  return _Key(
                    onTap: () => onDigit(key),
                    child: Text(
                      key,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 110),
        child: SizedBox(
          width: 74,
          height: 66,
          child: GlassPanel(
            radius: 20,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
