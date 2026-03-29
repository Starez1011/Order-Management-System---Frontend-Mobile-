import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator localhost

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/register/'), // or send-otp based on flow
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phone,
        'password': 'tempPassword123!', // Simplified for demo
        'first_name': 'Guest',
        'last_name': 'User',
      }),
    );
    // If already exists, maybe just throw or handle login flow instead
    if (res.statusCode == 400 && res.body.contains('already registered')) {
        final loginRes = await http.post(
          Uri.parse('$baseUrl/accounts/send-otp/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone_number': phone}),
        );
        return jsonDecode(loginRes.body);
    }
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/accounts/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
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

  // --- Menu ---
  static Future<Map<String, dynamic>> getMenu() async {
    final res = await http.get(Uri.parse('$baseUrl/menu/'));
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

  // --- Payments / Loyalty ---
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
}
