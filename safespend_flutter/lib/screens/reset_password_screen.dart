import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _key = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                        key: _key,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(s.tr('resetPassword'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 20),
                              TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  decoration:
                                      InputDecoration(labelText: s.newPassword),
                                  validator: (v) => v != null &&
                                          v.length >= 8 &&
                                          RegExp(r'[A-Z]').hasMatch(v) &&
                                          RegExp(r'[0-9]').hasMatch(v) &&
                                          RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                                              .hasMatch(v)
                                      ? null
                                      : s.tr('passwordPolicy')),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _confirm,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                      labelText: s.confirmNewPassword),
                                  validator: (v) => v == _password.text
                                      ? null
                                      : s.passwordsDoNotMatch),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          if (!_key.currentState!.validate())
                                            return;
                                          setState(() => _loading = true);
                                          final result = await context
                                              .read<AuthService>()
                                              .resetPassword(_password.text);
                                          if (!mounted) return;
                                          setState(() => _loading = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(result.success
                                                      ? s.tr(
                                                          'passwordResetSuccess')
                                                      : s.tr(
                                                          'recoverySessionInvalid')),
                                                  backgroundColor:
                                                      result.success
                                                          ? AppTheme.success
                                                          : AppTheme.error));
                                        },
                                  child: Text(s.updatePassword))
                            ]))))));
  }
}
