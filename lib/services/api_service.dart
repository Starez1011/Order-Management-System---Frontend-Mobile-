import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ApiService {
  static String get baseUrl {
    // if (kIsWeb) {
    //   return 'http://127.0.0.1:8000/api'; // Web localhost
    // }
    // return 'http://10.0.2.2:8000/api'; // Android emulator localhost
    final url = dotenv.env['BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL not set in .env');
    }

    return url;
  }

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---
  static Future<Map<String, dynamic>> checkPhone(String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/check-phone/'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'phone_number': phone}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> finalizeRegistration(String phone, String password, String firstName, String lastName) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/register-finalize/'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({
        'phone_number': phone,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['data']['access']);
      await prefs.setString('refresh_token', data['data']['refresh']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/send-otp/'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'phone_number': phone}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/verify-otp/'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'phone_number': phone, 'otp': otp}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['data']['access']);
      await prefs.setString('refresh_token', data['data']['refresh']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['data']['access']);
      await prefs.setString('refresh_token', data['data']['refresh']);
    }
    return data;
  }

  // --- Tables ---
  static Future<Map<String, dynamic>> validateQr(String qrToken, double lat, double lon) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tables/validate-qr/'),
      headers: await _getHeaders(),
      body: jsonEncode({'qr_token': qrToken, 'latitude': lat, 'longitude': lon}),
    );
    return jsonDecode(res.body);
  }

  // --- Menu & Location ---
  static Future<Map<String, dynamic>> getBranches() async {
    final res = await http.get(
      Uri.parse('$baseUrl/tables/branches/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getCafeDetails(int branchId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tables/location/?branch_id=$branchId'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMenu(int branchId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/menu/?branch_id=$branchId'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  // --- Cart & Orders ---
  static Future<Map<String, dynamic>> getCart(String qrToken) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/cart/?qr_token=$qrToken'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addToCart(String qrToken, int itemId, int quantity) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/cart/'),
      headers: await _getHeaders(),
      body: jsonEncode({'qr_token': qrToken, 'item_id': itemId, 'quantity': quantity}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> placeOrder(String qrToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/place/'),
      headers: await _getHeaders(),
      body: jsonEncode({'qr_token': qrToken}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateLoginPassword(String newPassword) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/accounts/profile/'),
      headers: await _getHeaders(),
      body: jsonEncode({'new_password': newPassword}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> setTransactionPassword(String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/transaction-password/'),
      headers: await _getHeaders(),
      body: jsonEncode({'transaction_password': password}),
    );
    return jsonDecode(res.body);
  }

  // --- Payments / Loyalty ---
  static Future<Map<String, dynamic>> transferPoints(String phoneNumber, double points, {String transactionPassword = '', bool biometricVerified = false}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/transfer-points/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'phone_number': phoneNumber,
        'points': points,
        if (!biometricVerified) 'transaction_password': transactionPassword,
        if (biometricVerified) 'biometric_verified': true,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> previewPayment(String orderNumber, double pointsToUse) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments/preview/'),
      headers: await _getHeaders(),
      body: jsonEncode({'order_number': orderNumber, 'points_to_use': pointsToUse}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/accounts/profile/'), headers: await _getHeaders());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> payViaQr(String qrToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments/pay-via-qr/'),
      headers: await _getHeaders(),
      body: jsonEncode({'qr_token': qrToken}),
    );
    return jsonDecode(res.body);
  }

  // --- Notifications ---
  static Future<Map<String, dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/accounts/notifications/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> markNotificationsRead() async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/notifications/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  // --- Order Status ---
  static Future<Map<String, dynamic>> getMyActiveOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/my-active/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> cancelOrder(String orderNumber) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/cancel/$orderNumber/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMyOrderHistory({int? days}) async {
    String url = '$baseUrl/orders/history/';
    if (days != null) {
      url += '?days=$days';
    }
    final res = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  // --- Promotions ---
  static Future<Map<String, dynamic>> getBanners() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin-panel/banners/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getOffers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin-panel/offers/'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPopularItems({int? branchId}) async {
    final uri = branchId != null
        ? '$baseUrl/admin-panel/popular/?branch_id=$branchId'
        : '$baseUrl/admin-panel/popular/';
    final res = await http.get(
      Uri.parse(uri),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }
}
