import '../widgets/app_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feature_help_button.dart';
import '../widgets/settings_ui.dart';
import '../widgets/stored_image.dart';
import '../services/supabase_sync_service.dart';
import 'package:image_picker/image_picker.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _deleting = false;

  /// Confirms, deletes the account on the server, then tears down the
  /// session and local data the same way sign-out does.
  Future<void> _deleteAccount(BuildContext context) async {
    final s = S.of(context);
    final confirmed = await showSettingsConfirm(
      context,
      title: s.tr('accountDeletionConfirmTitle'),
      message: s.tr('accountDeletionConfirmMessage'),
      confirmLabel: s.tr('accountDeletionAction'),
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final auth = context.read<AuthService>();
    final provider = context.read<AppProvider>();
    // Save this before signing out: deleting the remote Auth user invalidates
    // the current session, but the local SQLite rows still need its id.
    final deletedUserId = auth.userId;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _deleting = true);
    final result = await auth.deleteAccount();
    if (!mounted) return;
    setState(() => _deleting = false);

    if (!result.success) {
      messenger
          .showSnackBar(SnackBar(content: Text(s.tr('accountDeletionFailed'))));
      return;
    }

    await auth.signOut();
    // Do not report a completed deletion while this device could still retain
    // the account's SQLite rows or queued writes.
    await provider.clearData(userId: deletedUserId);
    if (!mounted) return;
    messenger
        .showSnackBar(SnackBar(content: Text(s.tr('accountDeletionDone'))));
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final provider = Provider.of<AppProvider>(context);
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
                      child: Icon(IOSIcons.arrow_back_rounded,
                          size: 22, color: AppTheme.adaptiveIcon(context)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(s.account,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  FeatureHelpButton(
                    title: s.account,
                    description: s.profileInformation,
                    icon: IOSIcons.person_rounded,
                  ),
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
                        _ProfileAvatar(
                          avatarPath: provider.settings.avatarPath,
                          enabled: !isLocalMode,
                          onEdit: () => _showAvatarOptions(context, provider),
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
                                color: AppTheme.adaptiveIconSurface(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                  child: Icon(IOSIcons.badge_rounded,
                                      size: 20,
                                      color: AppTheme.adaptiveIcon(context))),
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
                            if (!isLocalMode)
                              GestureDetector(
                                onTap: () => _openProfileEditor(context,
                                    changePassword: false),
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
                                color: AppTheme.adaptiveIconSurface(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                  child: Icon(IOSIcons.email_rounded,
                                      size: 20,
                                      color: AppTheme.adaptiveIcon(context))),
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
                                  color: AppTheme.adaptiveIconSurface(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                    child: Icon(IOSIcons.lock_rounded,
                                        size: 20,
                                        color: AppTheme.adaptiveIcon(context))),
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
                              GestureDetector(
                                onTap: () => _openProfileEditor(context,
                                    changePassword: true),
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

                  // Account deletion (App Store 5.1.1(v), Google Play policy)
                  if (!isLocalMode) ...[
                    const SizedBox(height: 32),
                    Container(
                      decoration: AppTheme.premiumCard(context),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap:
                              _deleting ? null : () => _deleteAccount(context),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                      child: Icon(
                                          IOSIcons.delete_outline_rounded,
                                          size: 20,
                                          color: AppTheme.error)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.tr('accountDeletionAction'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.error)),
                                      const SizedBox(height: 2),
                                      Text(s.tr('accountDeletionDetail'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ),
                                if (_deleting)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(
                        duration: 280.ms, delay: 240.ms, curve: Curves.easeOut),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Offers to pick a new profile picture, or remove the current one.
  Future<void> _showAvatarOptions(
      BuildContext context, AppProvider provider) async {
    final s = S.of(context);
    final hasAvatar = (provider.settings.avatarPath ?? '').isNotEmpty;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AvatarOptionsSheet(canRemove: hasAvatar),
    );
    if (action == null || !context.mounted) return;

    if (action == 'remove') {
      await provider.removeProfilePicture();
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      // Downscale at capture: an avatar is displayed at 72px, so a full
      // camera frame is wasted bytes on the user's connection and quota.
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.setProfilePicture(picked.path);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.tr('profilePictureFailed'))),
      );
    }
  }
}

/// Picker for the profile-picture action. Separate so the sheet can be
/// dismissed before the async work starts.
class _AvatarOptionsSheet extends StatelessWidget {
  const _AvatarOptionsSheet({required this.canRemove});

  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(IOSIcons.camera_alt_rounded,
                  color: AppTheme.adaptiveIcon(context)),
              title: Text(s.tr('takePhoto')),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: Icon(IOSIcons.photo_library_rounded,
                  color: AppTheme.adaptiveIcon(context)),
              title: Text(s.tr('chooseFromGallery')),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (canRemove)
              ListTile(
                leading: Icon(IOSIcons.delete_rounded, color: AppTheme.error),
                title: Text(s.tr('removePhoto'),
                    style: TextStyle(color: AppTheme.error)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
  }
}

void _openProfileEditor(BuildContext context, {required bool changePassword}) {
  showAppFormSheet<void>(
    context: context,
    builder: (_) => _ProfileEditSheet(changePassword: changePassword),
  );
}

/// The profile picture, with an edit affordance.
///
/// Falls back to a person glyph when no picture is set, and while one is
/// being resolved, so the header never collapses or shows a broken image.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarPath,
    required this.enabled,
    required this.onEdit,
  });

  final String? avatarPath;

  /// False in local mode: there is no account to attach a picture to.
  final bool enabled;

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(IOSIcons.person_rounded,
        color: AppTheme.adaptiveIcon(context), size: 36);

    return GestureDetector(
      onTap: enabled ? onEdit : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.adaptiveIconSurface(context),
              borderRadius: BorderRadius.circular(22),
            ),
            child: avatarPath == null || avatarPath!.isEmpty
                ? Center(child: placeholder)
                : StoredImage(
                    reference: avatarPath,
                    bucket: SupabaseSyncService.avatarsBucket,
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(22),
                    errorWidget: placeholder,
                  ),
          ),
          if (enabled)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({required this.changePassword});
  final bool changePassword;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _visible = <bool>[false, false, false];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AuthService>().displayName ?? '';
  }

  @override
  void dispose() {
    for (final controller in [_name, _current, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final s = S.of(context);
    String? error;
    if (widget.changePassword) {
      if (_current.text.isEmpty) {
        error = s.enterCurrentPwd;
      } else if (_password.text.isEmpty) {
        error = s.enterNewPwd;
      } else if (_password.text.length < 6) {
        error = s.passwordTooShort;
      } else if (_password.text != _confirm.text) {
        error = s.passwordsDoNotMatch;
      }
    } else if (_name.text.trim().isEmpty) {
      error = s.enterYourName;
    }
    setState(() => _error = error);
    if (error != null) return;

    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final result = widget.changePassword
        ? await auth.changePassword(_current.text, _password.text)
        : await auth.updateDisplayName(_name.text.trim());
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _saving = false;
        _error = s.tr('actionCouldNotBeCompleted');
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.changePassword ? s.passwordChanged : s.nameUpdated),
      backgroundColor: AppTheme.success,
    ));
    Navigator.pop(context);
  }

  Widget _passwordField(
      TextEditingController controller, String label, int index) {
    return TextField(
      controller: controller,
      obscureText: !_visible[index],
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _visible[index] = !_visible[index]),
          icon: Icon(
              _visible[index]
                  ? IOSIcons.visibility_off_rounded
                  : IOSIcons.visibility_rounded,
              size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AppFormSheet(
      header: AppFormSheetHeader(
        title: widget.changePassword ? s.changePassword : s.displayName,
        icon: widget.changePassword
            ? IOSIcons.lock_rounded
            : IOSIcons.badge_rounded,
        accent: AppTheme.adaptiveIcon(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 16),
          ],
          if (widget.changePassword) ...[
            _passwordField(_current, s.currentPassword, 0),
            const SizedBox(height: 16),
            _passwordField(_password, s.newPassword, 1),
            const SizedBox(height: 16),
            _passwordField(_confirm, s.confirmNewPassword, 2),
          ] else
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: s.displayName, hintText: s.enterYourName),
            ),
        ],
      ),
      actions: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.changePassword ? s.updatePassword : s.save),
        ),
      ),
    );
  }
}
