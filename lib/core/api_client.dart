import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ApiClient {
  // URL Server Online (Hosting Asli)
  // Catatan: Jika saat online Anda tidak menghapus kata "public", maka ganti menjadi 'https://maijek.polman.id/public/api'
  static String get baseUrl {
    return 'https://maijek.polman.id/api'; 
  }

  // Helper untuk membersihkan dan menstandarisasi URL gambar
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'https://ui-avatars.com/api/?name=Driver&background=random';
    
    // Jika backend sudah memberikan URL utuh (berawal http)
    if (path.startsWith('http')) return path;
    
    // Jika masih berupa path relatif, gabungkan dengan baseUrl (buang /api)
    String rootUrl = baseUrl.replaceAll('/api', '');
    if (!path.startsWith('/')) path = '/$path';
    
    return rootUrl + path;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  static void _checkUnauthorized(int statusCode) async {
    if (statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      // Jangan pernah redirect atau tampilkan "Sesi Berakhir" jika pengguna sedang di halaman Login, Register, atau Verifikasi OTP
      final currentRoute = Get.currentRoute;
      final authRoutes = ['/login', '/register', '/verify-otp'];
      if (!authRoutes.contains(currentRoute)) {
        Get.offAllNamed('/login');
        Get.snackbar(
          'Sesi Berakhir',
          'Sesi login Anda telah berakhir. Silakan masuk kembali.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(const Duration(seconds: 30));
    _checkUnauthorized(response.statusCode);
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    _checkUnauthorized(response.statusCode);
    return response;
  }

  static Future<http.StreamedResponse> multipartPost(
    String endpoint,
    Map<String, String> fields, {
    String? fileKey,
    String? filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    if (fileKey != null && filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileKey, filePath));
    }

    return await request.send().timeout(const Duration(seconds: 30));
  }
}
