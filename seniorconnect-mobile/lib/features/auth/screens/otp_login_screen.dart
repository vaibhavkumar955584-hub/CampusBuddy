import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_setup_screen.dart';

class OtpLoginScreen extends StatefulWidget {
  final String selectedRole;

  const OtpLoginScreen({super.key, this.selectedRole = 'JUNIOR'});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final TextEditingController _emailPrefixController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  late String _role;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  int _resendTimer = 60;
  Timer? _timer;

  final String _fixedDomain = '@galgotiacollege.edu';
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _role = widget.selectedRole;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailPrefixController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _fullEmail {
    String text = _emailPrefixController.text.trim();
    if (text.endsWith(_fixedDomain)) {
      return text;
    }
    return '$text$_fixedDomain';
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _sendOtp() async {
    if (_emailPrefixController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your college email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.post(
        ApiConstants.sendOtp,
        body: {
          'email': _fullEmail,
          'role': _role,
          'fullName': _emailPrefixController.text.trim().split('.')[0],
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        _startResendTimer();
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _errorMessage = err['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please verify backend server is accessible.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of your verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.post(
        '${ApiConstants.verifyOtp}?role=$_role',
        body: {
          'email': _fullEmail,
          'otp': _otpCode,
          'deviceFingerprint': 'mobile-app-client',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _apiClient.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        _apiClient.currentUser = UserModel.fromJson(data['user']);

        // Fetch smart email parsing prefill data
        Map<String, dynamic>? parsedData;
        try {
          final parseRes = await _apiClient.post(
            '${ApiConstants.baseUrl}/auth/parse-email',
            body: {'email': _fullEmail},
          );
          if (parseRes.statusCode == 200) {
            parsedData = jsonDecode(parseRes.body);
          }
        } catch (_) {}

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(
                email: _fullEmail,
                parsedData: parsedData,
              ),
            ),
          );
        }
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _errorMessage = err['message'] ?? 'Invalid OTP code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'SC',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Home',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _otpSent ? _buildInboxVerifyState() : _buildEmailInputState(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildEmailInputState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Illustration circle with graduation cap & badge
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF1F5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.school_rounded,
                  size: 54,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Verify your identity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Join your campus community to connect with\nmentors and peers.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'College Email Address',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailPrefixController,
          decoration: InputDecoration(
            hintText: 'student@university.edu',
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppTheme.outline),
            suffixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                _fixedDomain,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_outline, size: 15, color: AppTheme.outline),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'We only accept your college email to keep this community verified.',
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              : const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildInboxVerifyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 36),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFDFF1F5),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 38,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Check your inbox',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to your college email:\n$_fullEmail',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        ],
        // 6 Discrete PIN Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  fillColor: _otpControllers[index].text.isNotEmpty
                      ? const Color(0xFFDFF1F5)
                      : AppTheme.surfaceContainerLowest,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                    }
                  } else if (index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          "Didn't receive it?",
          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _resendTimer == 0 ? _sendOtp : null,
          child: Text(
            _resendTimer > 0
                ? 'Resend code in 0:${_resendTimer.toString().padLeft(2, '0')}'
                : 'Resend code now',
            style: TextStyle(
              color: _resendTimer > 0 ? AppTheme.outline : AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _verifyOtp,
          icon: _isLoading
              ? const SizedBox.shrink()
              : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          label: _isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              : const Icon(Icons.arrow_forward_rounded, size: 20),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _otpSent = false),
          child: const Text(
            'Change email address',
            style: TextStyle(color: AppTheme.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
