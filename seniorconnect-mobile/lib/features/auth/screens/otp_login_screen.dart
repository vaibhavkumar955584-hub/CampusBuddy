import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_setup_screen.dart';

class OtpLoginScreen extends StatefulWidget {
  final String selectedRole;

  const OtpLoginScreen({super.key, this.selectedRole = 'JUNIOR'});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Phone Auth State
  bool _isCodeSent = false;
  String? _verificationId;

  final String _fixedDomain = '@galgotiacollege.edu';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  String get _computedEmail {
    String text = _emailController.text.trim();
    if (text.isEmpty) return '';
    if (text.contains('@')) return text;
    return '$text$_fixedDomain';
  }

  Future<void> _handleEmailAuth() async {
    final email = _computedEmail;
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCred;
      if (_isSignUp) {
        final name = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : email.split('@')[0];
        userCred = await _authService.signUpWithEmailPassword(
          email: email,
          password: password,
          displayName: name,
        );
      } else {
        userCred = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
        );
      }

      if (userCred.user != null) {
        await _onAuthSuccess(userCred.user!);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCred = await _authService.signInWithGoogle();
      if (userCred != null && userCred.user != null) {
        await _onAuthSuccess(userCred.user!);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid phone number (e.g. +919876543210)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
            _isLoading = false;
          });
        },
        onVerificationFailed: (e) {
          setState(() {
            _errorMessage = e.message ?? 'Phone verification failed.';
            _isLoading = false;
          });
        },
        onVerificationCompleted: (credential) async {
          try {
            final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCred.user != null) {
              await _onAuthSuccess(userCred.user!);
            }
          } catch (e) {
            if (mounted) setState(() => _errorMessage = e.toString());
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final code = _smsCodeController.text.trim();
    if (code.length < 6 || _verificationId == null) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP received.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCred = await _authService.signInWithPhoneOtp(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (userCred.user != null) {
        await _onAuthSuccess(userCred.user!);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAuthSuccess(User user) async {
    final String displayName = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Campus User');

    // Save/update profile in Firestore with timeout protection
    try {
      await _firestoreService.createUserProfile(
        uid: user.uid,
        email: user.email ?? user.phoneNumber ?? '',
        fullName: displayName,
        role: widget.selectedRole,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Firestore profile sync error: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            email: user.email ?? user.phoneNumber ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.selectedRole == 'SENIOR' ? 'Senior Access' : 'Junior Access',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded, size: 48, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verify your identity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join your campus community to connect with mentors and peers.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Auth Tabs: Email/Password vs Phone OTP
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  tabs: const [
                    Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'College Email'),
                    Tab(icon: Icon(Icons.phone_android_rounded, size: 18), text: 'Phone OTP'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab View Content
              SizedBox(
                height: _tabController.index == 0 ? 320 : 250,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Email & Password
                    _buildEmailTab(),
                    // Tab 2: Phone OTP
                    _buildPhoneTab(),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppTheme.outline, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Expanded(child: Divider(color: AppTheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 16),

              // Google Sign-In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.surfaceContainerLowest,
                ),
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Vaibhav Kumar',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'College Email Address',
            hintText: 'roll_number or email',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            suffixText: _emailController.text.contains('@') ? null : _fixedDomain,
            suffixStyle: const TextStyle(color: AppTheme.outline, fontSize: 13),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isLoading ? null : _handleEmailAuth,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  _isSignUp ? 'Create Account' : 'Sign In',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _isSignUp = !_isSignUp;
            _errorMessage = null;
          }),
          child: Text(
            _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
            style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isCodeSent) ...[
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+919876543210',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _sendPhoneOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Verification Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ] else ...[
          TextField(
            controller: _smsCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit SMS OTP',
              hintText: '123456',
              prefixIcon: Icon(Icons.security, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _verifyPhoneOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verify & Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => setState(() => _isCodeSent = false),
            child: const Text('Change Phone Number', style: TextStyle(color: AppTheme.outline, fontSize: 12)),
          ),
        ],
      ],
    );
  }
}
