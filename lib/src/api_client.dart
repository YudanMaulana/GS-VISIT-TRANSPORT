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
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['branches'] is List) {
      list = decoded['branches'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ambil daftar sub-area pabrik (GF, DC, MBR)
  Future<List<PlantArea>> fetchAreas({int? branchId}) async {
    final query = <String, String>{
      if (branchId != null) 'branch_id': '$branchId',
    };
    final resp = await _client
        .get(_uri('/api/areas', query), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return [];
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['areas'] is List) {
      list = decoded['areas'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list.map((e) => PlantArea.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ambil daftar transporter yang sedang berada di area
  Future<List<ActiveGuestRow>> fetchActiveTransporters({int? branchId, int? areaId}) async {
    final query = <String, String>{
      'kind': 'transporter',
      if (branchId != null) 'branch_id': '$branchId',
      if (areaId != null) 'area_id': '$areaId',
    };

    final resp = await _client
        .get(_uri('/api/active-guests/today', query), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw Exception('Gagal memuat transporter di area: ${resp.body}');
    }
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['guests'] is List) {
      list = decoded['guests'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list.map((e) => ActiveGuestRow.fromJson(e as Map<String, dynamic>)).toList();
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
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['loads'] is List) {
      list = decoded['loads'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      list = const [];
    }
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
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['audit_logs'] is List) {
      list = decoded['audit_logs'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      list = const [];
    }
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

  /// Ambil seluruh daftar pengunjung dari server
  Future<List<Map<String, dynamic>>> fetchVisitors() async {
    try {
      final resp = await _client
          .get(_uri('/api/visitors'), headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return [];
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  /// Ambil daftar sopir transporter & status keaktifan akun
  Future<List<TransporterDriver>> fetchTransporterDrivers({
    String? search,
    bool? isActive,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (isActive != null) 'is_active': '$isActive',
    };
    try {
      final resp = await _client
          .get(_uri('/api/transporter/drivers', query), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['drivers'] is List) {
          list = decoded['drivers'] as List<dynamic>;
        } else {
          list = const [];
        }
        return list
            .whereType<Map<String, dynamic>>()
            .map((j) => TransporterDriver.fromJson(j))
            .toList();
      }
    } catch (_) {
      // Abaikan dan lanjutkan ke fallback di bawah jika endpoint khusus belum aktif di server
    }

    // Fallback: Jika endpoint /api/transporter/drivers belum tersedia di server (misal HTTP 404),
    // ambil data langsung dari /api/visitors dan filter visitor_type == 'transporter'
    try {
      final allVisitors = await fetchVisitors();
      var drivers = allVisitors
          .where((v) =>
              (v['visitor_type']?.toString().trim().toLowerCase() ?? '') ==
              'transporter')
          .map((j) => TransporterDriver.fromJson(j))
          .toList();

      if (isActive != null) {
        drivers = drivers.where((d) => d.isActive == isActive).toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        drivers = drivers.where((d) => d.matches(search)).toList();
      }
      if (drivers.length > limit) {
        drivers = drivers.sublist(0, limit);
      }
      return drivers;
    } catch (_) {
      return [];
    }
  }

  /// Aktifkan atau nonaktifkan profil sopir transporter
  Future<Map<String, dynamic>> toggleTransporterDriverActive({
    required int visitorId,
    required bool isActive,
    String? reason,
  }) async {
    try {
      final resp = await _client
          .patch(
            _uri('/api/transporter/drivers/$visitorId/toggle-active'),
            headers: _headers,
            body: jsonEncode({
              'is_active': isActive,
              if (reason != null && reason.isNotEmpty) 'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      if (resp.statusCode == 404) {
        return {
          'success': false,
          'message':
              'Fitur toggle status belum aktif di server produksi. Silakan jalankan git pull & restart server.',
        };
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'success': false,
        'message': 'Gagal memperbarui status (${resp.statusCode}).',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghubungi server: $e',
      };
    }
  }
}
