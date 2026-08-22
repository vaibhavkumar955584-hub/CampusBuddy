import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/queries/screens/query_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeniorConnectApp());
}

class SeniorConnectApp extends StatefulWidget {
  const SeniorConnectApp({super.key});

  @override
  State<SeniorConnectApp> createState() => _SeniorConnectAppState();
}

class _SeniorConnectAppState extends State<SeniorConnectApp> {
  final ApiClient _apiClient = ApiClient();
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    String? token = await _apiClient.getAccessToken();
    setState(() {
      _isAuthenticated = token != null && token.isNotEmpty;
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeniorConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isCheckingAuth
          ? const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          : _isAuthenticated
              ? const QueryFeedScreen()
              : const RoleSelectionScreen(),
    );
  }
}
