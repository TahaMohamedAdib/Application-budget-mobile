import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditingName = false;
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _nameController.text = auth.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.updateDisplayName(_nameController.text.trim());

    setState(() {
      _isLoading = false;
      _isEditingName = false;
      if (!result.success) {
        _errorMessage = result.error;
      }
    });

    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(S.of(context).nameUpdated),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _changePassword() async {
    setState(() => _errorMessage = null);

    final s = S.of(context);
    if (_currentPasswordController.text.isEmpty) {
      setState(() => _errorMessage = s.enterCurrentPwd);
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      setState(() => _errorMessage = s.enterNewPwd);
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = s.passwordTooShort);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = s.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.error;
      } else {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });

    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(S.of(context).passwordChanged),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final s = S.of(context);
    final email = auth.user?.email ?? s.localMode;
    final displayName = auth.displayName ?? s.user;
    final isLocalMode = auth.localMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 22,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(s.account,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .slideY(begin: -0.05, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.premiumCard(context),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Center(
                              child: Icon(Icons.person_rounded,
                                  color: AppTheme.goldPrimary, size: 36)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(isLocalMode ? s.localMode : email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 80.ms, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(s.profileInformation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  ),

                  // Display Name Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.premiumCard(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.goldPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                  child: Icon(Icons.badge_rounded,
                                      size: 20, color: AppTheme.goldPrimary)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(s.howYouAppear,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            if (!isLocalMode && !_isEditingName)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isEditingName = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.goldPrimary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(s.edit,
                                      style: const TextStyle(
                                          color: AppTheme.goldPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isEditingName) ...[
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: s.enterYourName,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : AppTheme.lightBackground,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      setState(() => _isEditingName = false),
                                  child: Text(s.cancel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveName,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.goldPrimary,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black))
                                      : Text(s.save,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 120.ms, curve: Curves.easeOut),

                  const SizedBox(height: 16),

                  // Email Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.premiumCard(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF3B82F6).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                  child: Icon(Icons.email_rounded,
                                      size: 20, color: Color(0xFF3B82F6))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.emailAddress,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(s.usedForSignIn,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lightBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(email,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 160.ms, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // Security Section Title
                  if (!isLocalMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(s.security,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8)),
                    ),

                  // Password Section
                  if (!isLocalMode)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.premiumCard(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                    child: Icon(Icons.lock_rounded,
                                        size: 20, color: Color(0xFF10B981))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.password,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(s.changePassword,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              if (!_isChangingPassword)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _isChangingPassword = true;
                                    _errorMessage = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(s.change,
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isChangingPassword) ...[
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        size: 18, color: AppTheme.error),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(_errorMessage!,
                                            style: TextStyle(
                                                color: AppTheme.error,
                                                fontSize: 13))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: !_showCurrentPassword,
                              decoration: InputDecoration(
                                hintText: s.currentPassword,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _showCurrentPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20),
                                  onPressed: () => setState(() =>
                                      _showCurrentPassword =
                                          !_showCurrentPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: !_showNewPassword,
                              decoration: InputDecoration(
                                hintText: s.newPassword,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _showNewPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20),
                                  onPressed: () => setState(() =>
                                      _showNewPassword = !_showNewPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: !_showConfirmPassword,
                              decoration: InputDecoration(
                                hintText: s.confirmNewPassword,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _showConfirmPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20),
                                  onPressed: () => setState(() =>
                                      _showConfirmPassword =
                                          !_showConfirmPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _isChangingPassword = false;
                                      _errorMessage = null;
                                      _currentPasswordController.clear();
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    }),
                                    child: Text(s.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.goldPrimary,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black))
                                        : Text(s.updatePassword,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('••••••••••••',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 2)),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(
                        duration: 280.ms, delay: 200.ms, curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
