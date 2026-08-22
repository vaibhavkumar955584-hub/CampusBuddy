import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_setup_screen.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final TextEditingController _emailPrefixController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedRole = 'JUNIOR';
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  final String _fixedDomain = '@galgotiacollege.edu';
  final ApiClient _apiClient = ApiClient();

  String get _fullEmail {
    String prefix = _emailPrefixController.text.trim();
    if (prefix.endsWith(_fixedDomain)) {
      return prefix;
    }
    return '$prefix$_fixedDomain';
  }

  Future<void> _sendOtp() async {
    if (_emailPrefixController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your college roll/email ID.');
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
          'role': _selectedRole,
          'fullName': _emailPrefixController.text.trim().split('.')[0],
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _errorMessage = err['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.post(
        '${ApiConstants.verifyOtp}?role=$_selectedRole',
        body: {
          'email': _fullEmail,
          'otp': _otpController.text.trim(),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 36),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SeniorConnect',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Zero-Trust Campus Mentorship & Query Platform',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.dangerColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.dangerColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (!_otpSent) ...[
                  const Text('Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Junior (Student)')),
                          selected: _selectedRole == 'JUNIOR',
                          onSelected: (val) => setState(() => _selectedRole = 'JUNIOR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Senior (Mentor)')),
                          selected: _selectedRole == 'SENIOR',
                          onSelected: (val) => setState(() => _selectedRole = 'SENIOR'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('College Email ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailPrefixController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'vk.24gcebit093',
                      prefixIcon: const Icon(Icons.school_outlined, size: 20),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Text(
                          _fixedDomain,
                          style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 13, color: AppTheme.accentColor),
                      SizedBox(width: 6),
                      Text(
                        "We'll auto-detect your branch and year from this",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : const Text('Send Verification OTP'),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Enter the 6-digit code sent to $_fullEmail',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : const Text('Verify & Continue to Profile Setup'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: const Text('Change email or role', style: TextStyle(color: AppTheme.primaryLight)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
