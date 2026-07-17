import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../crash/presentation/providers/crash_providers.dart';
import '../../../sync/presentation/providers/progress_sync_providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';

enum _AuthMode { logIn, signUp }

/// Cloud sign-in, optional alongside Guest Mode — pushed from Settings
/// or Profile, never blocking play. Segmented Log In / Sign Up toggle +
/// email/password form + a magic-link fallback; Google is shown but not
/// yet wired (see the studio roadmap's Phase 4 for OAuth setup).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.logIn;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _info = null;
    });
  }

  String _friendlyError(Object error) {
    final String msg = error.toString();
    if (msg.contains('Invalid login credentials')) return 'Incorrect email or password.';
    if (msg.contains('User already registered')) return 'An account with this email already exists.';
    if (msg.contains('Password should be at least')) return 'Password must be at least 6 characters.';
    if (msg.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
      return 'Too many attempts — please wait a few minutes and try again.';
    }
    if (msg.contains('email_address_invalid')) return 'Enter a valid email address.';
    if (msg.contains('email_not_confirmed') || msg.contains('Email not confirmed')) {
      return 'Confirm your email first — check your inbox for the confirmation link.';
    }
    return 'Something went wrong — please try again.';
  }

  Future<void> _submit() async {
    final AuthRepository? repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      setState(() => _error = "Cloud sign-in isn't set up yet.");
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      if (_mode == _AuthMode.logIn) {
        await repo.signInWithPassword(email: email, password: password);
      } else {
        await repo.signUpWithPassword(email: email, password: password);
      }
      // No active session yet if the project requires email confirmation
      // (signUp succeeds but doesn't sign in until the link is clicked) —
      // nothing to sync in that case, so this is a no-op rather than a
      // missed sync.
      final String? userId = repo.currentUser?.id;
      if (userId != null) {
        unawaited(ref.read(progressSyncControllerProvider).syncOnSignIn(userId));
        // Best-effort: gives admin a real account to find/credit instead of
        // an anonymous guest. Never blocks sign-in — a stale/duplicate link
        // (e.g. this account already linked on another device) is just
        // dropped, same as a sync hiccup would be.
        final String? accessToken = repo.accessToken;
        if (ApiConfig.isConfigured && accessToken != null) {
          final String guestId = ref.read(crashGuestIdProvider);
          unawaited(
            ref
                .read(crashRepositoryProvider)
                .linkAccount(guestId: guestId, accessToken: accessToken)
                .catchError((_) {}),
          );
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMagicLink() async {
    final AuthRepository? repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      setState(() => _error = "Cloud sign-in isn't set up yet.");
      return;
    }
    final String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await repo.signInWithMagicLink(email: email);
      if (mounted) setState(() => _info = 'Check $email for a sign-in link.');
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _googleComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Google sign-in is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final bool notConfigured = ref.watch(authRepositoryProvider) == null;
    final bool signUp = _mode == _AuthMode.signUp;

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'Account'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
              children: <Widget>[
                _ModeToggle(mode: _mode, onChanged: _switchMode),
                const SizedBox(height: AppSpacing.xl),
                if (notConfigured) ...<Widget>[
                  PremiumCard(
                    borderColor: AppColors.warning,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            "Cloud sign-in isn't connected yet — you can still explore this screen.",
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      _AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (String? v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _AuthTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (String? v) =>
                            (v == null || v.length < 6) ? 'At least 6 characters' : null,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
                if (_info != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(_info!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
                ],
                const SizedBox(height: AppSpacing.xl),
                GradientButton.primary(
                  label: signUp ? 'SIGN UP' : 'LOG IN',
                  loading: _loading,
                  onPressed: notConfigured || _loading ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: notConfigured || _loading ? null : _sendMagicLink,
                    child: Text(
                      'Email me a magic link instead',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('OR', style: AppTextStyles.label),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                GradientButton.secondary(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: _googleComingSoon,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardPurple,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          for (final (_AuthMode value, String label) in <(_AuthMode, String)>[
            (_AuthMode.logIn, 'Log In'),
            (_AuthMode.signUp, 'Sign Up'),
          ])
            Expanded(
              child: PressableScale(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: value == mode ? AppGradients.neonPurple : null,
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: value == mode ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.cardPurple,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
