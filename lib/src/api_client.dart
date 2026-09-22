import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class TransportApiClient {
  final String baseUrl;
  final String adminToken;
  final http.Client _client = http.Client();

  TransportApiClient({required this.baseUrl, required this.adminToken});

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';
    return Uri.parse(fullUrl).replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (adminToken.isNotEmpty) 'Authorization': 'Bearer $adminToken',
        if (adminToken.isNotEmpty) 'X-Admin-Token': adminToken,
      };

  /// Autentikasi Google Admin dengan role `admin_transport`.
  static Future<Map<String, dynamic>> loginGoogle({
    required String baseUrl,
    required String idToken,
  }) async {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$cleanBase/api/admin/auth/google');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'target_role': 'admin_transport',
      }),
    ).timeout(const Duration(seconds: 25));

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 400 && data['message'] == null && data['detail'] != null) {
      data['message'] = data['detail'];
    }
    return data;
  }

  /// Verifikasi sesi admin saat ini
  Future<Map<String, dynamic>> fetchMe() async {
    final resp = await _client
        .get(_uri('/api/admin/auth/me'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Ambil daftar cabang
  Future<List<Branch>> fetchBranches() async {
    final resp = await _client
        .get(_uri('/api/branches'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as List<dynamic>;
    return json.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ambil daftar transporter yang sedang berada di area
  Future<List<ActiveGuestRow>> fetchActiveTransporters({int? branchId}) async {
    final query = <String, String>{
      'kind': 'transporter',
      if (branchId != null) 'branch_id': '$branchId',
    };
    final resp = await _client
        .get(_uri('/api/active-guests/today', query), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw Exception('Gagal memuat transporter di area: ${resp.body}');
    }
    final json = jsonDecode(resp.body) as List<dynamic>;
    return json.map((e) => ActiveGuestRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Konfirmasi masuk transporter (Check-in + TTD Satpam & Dokumen Muatan)
  Future<Map<String, dynamic>> confirmCheckin(Map<String, dynamic> payload) async {
    final resp = await _client
        .post(
          _uri('/api/transporter/confirm-checkin'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 35));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Konfirmasi keluar transporter (Check-out)
  Future<Map<String, dynamic>> confirmCheckout(Map<String, dynamic> payload) async {
    final resp = await _client
        .post(
          _uri('/api/transporter/confirm-checkout'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 35));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Ambil data muatan bongkar/muat
  Future<List<Map<String, dynamic>>> fetchLoads(int planId) async {
    final resp = await _client
        .get(_uri('/api/visit-plans/$planId/loads'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return [];
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Tambah item muatan
  Future<Map<String, dynamic>> addLoad(int planId, Map<String, dynamic> load) async {
    final resp = await _client
        .post(
          _uri('/api/visit-plans/$planId/loads'),
          headers: _headers,
          body: jsonEncode(load),
        )
        .timeout(const Duration(seconds: 20));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Ambil riwayat audit log transporter
  Future<List<Map<String, dynamic>>> fetchAuditLogs({int? branchId}) async {
    final query = <String, String>{
      if (branchId != null) 'branch_id': '$branchId',
    };
    final resp = await _client
        .get(_uri('/api/transporter/audit-logs', query), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) return [];
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Kirim laporan kendala / bug transporter
  Future<Map<String, dynamic>> submitSupportReport({
    required String title,
    required String description,
    String? category,
  }) async {
    final resp = await _client
        .post(
          _uri('/api/admin/support/reports'),
          headers: _headers,
          body: jsonEncode({
            'title': title,
            'description': description,
            'category': category ?? 'transporter',
          }),
        )
        .timeout(const Duration(seconds: 20));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
