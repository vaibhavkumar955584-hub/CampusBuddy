import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/user_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  UserModel? currentUser;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() async => await _storage.read(key: 'refresh_token');

  Future<void> clearSession() async {
    await _storage.deleteAll();
    currentUser = null;
  }

  Future<http.Response> get(String url) async {
    return _sendWithAuth((headers) => _client.get(Uri.parse(url), headers: headers));
  }

  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return _sendWithAuth((headers) => _client.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ));
  }

  Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    return _sendWithAuth((headers) => _client.patch(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ));
  }

  Future<http.Response> _sendWithAuth(Future<http.Response> Function(Map<String, String> headers) requestFn) async {
    String? token = await getAccessToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response = await requestFn(headers);

    // If 401 Unauthorized, attempt refresh token rotation
    if (response.statusCode == 401) {
      bool refreshed = await _attemptRefreshToken();
      if (refreshed) {
        String? newToken = await getAccessToken();
        headers['Authorization'] = 'Bearer $newToken';
        return await requestFn(headers);
      }
    }

    return response;
  }

  Future<bool> _attemptRefreshToken() async {
    String? refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await _client.post(
        Uri.parse(ApiConstants.refresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken, 'deviceFingerprint': 'flutter-app-fp'}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      } else {
        await clearSession();
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}
