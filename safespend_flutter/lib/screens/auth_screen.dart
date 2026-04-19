import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = _isLogin
        ? await auth.signIn(email, password)
        : await auth.signUp(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Sign-up succeeded but email confirmation is required
    if (result.error == 'email_confirmation_required') {
      if (!mounted) return;
      _showEmailConfirmationDialog(email);
    } else if (result.success && auth.userId != null) {
      // Fully authenticated — load cloud data
      await appProvider.loadFromSupabase(auth.userId!);
    } else if (result.error != null) {
      if (!mounted) return;
      final isEmailNotConfirmed =
          result.error!.toLowerCase().contains('email not confirmed') ||
              result.error!.toLowerCase().contains('not confirmed');
      if (isEmailNotConfirmed) {
        _showEmailConfirmationDialog(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.error!), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showEmailConfirmationDialog(String email) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_unread_rounded,
                color: AppTheme.goldPrimary),
            const SizedBox(width: 10),
            Text(s.confirmEmail,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          s.checkInbox.replaceAll('{email}', email),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.ok),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthService>(context, listen: false);
              final result = await auth.resendConfirmationEmail(email);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result.success
                    ? s.confirmationEmailResent
                    : (result.error ?? s.failedToResend)),
                backgroundColor:
                    result.success ? AppTheme.success : AppTheme.error,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(s.resendEmail),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.signInWithGoogle();
    if (!mounted) return;
    if (!result.success && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _signInWithApple() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.signInWithApple();
    if (!mounted) return;
    if (!result.success && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 40, color: AppTheme.goldPrimary),
                )
                    .animate()
                    .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                    .scaleXY(
                        begin: 0.85,
                        end: 1.0,
                        duration: 300.ms,
                        curve: Curves.easeOut),
                const SizedBox(height: 20),

                // Title
                Text(
                  'SafeSpend',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldPrimary,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: 260.ms, delay: 60.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 6),
                Text(
                  _isLogin ? 'Welcome back' : s.createAccount,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ).animate().fadeIn(
                    duration: 260.ms, delay: 100.ms, curve: Curves.easeOut),
                const SizedBox(height: 36),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: s.email,
                          hintText: 'you@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Email is required';
                          final email = v.trim();
                          final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(email))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: s.password,
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Password is required';
                          if (v.length < 8) return 'At least 8 characters';
                          if (!RegExp(r'[A-Z]').hasMatch(v))
                            return 'Include an uppercase letter';
                          if (!RegExp(r'[0-9]').hasMatch(v))
                            return 'Include a number';
                          if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v))
                            return 'Include a special character';
                          return null;
                        },
                      ),

                      // Confirm password (sign up only)
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(
                                  _isLogin ? s.signIn : s.createAccount,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: 280.ms,
                              delay: 200.ms,
                              curve: Curves.easeOut)
                          .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: 280.ms, delay: 140.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 28),

                // Toggle login/signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? s.dontHaveAccount : s.alreadyHaveAccount,
                      style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset();
                      }),
                      child: Text(
                        _isLogin ? s.signUp : s.signIn,
                        style: const TextStyle(
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
