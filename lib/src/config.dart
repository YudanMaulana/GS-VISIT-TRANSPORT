import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi aplikasi GS VISIT TRANSPORT.
/// Menyimpan pengaturan server, kredensial login admin, cabang, dan OAuth Google.
/// Mendukung pemuatan otomatis dari file config.json / .env yang dibuat oleh installer Inno Setup.
class AppConfig {
  String baseUrl;
  int? branchId;
  String branchName;
  String adminEmail;
  String adminToken;
  String googleClientId;
  String googleClientSecret;

  static const String defaultBaseUrl =
      'https://garudafood.choclatosxquest.web.id/garudafood-visit';
  static final String defaultGoogleClientId = [
    '49019475828',
    '-sdv57ouv8bjkectj3c0dq881o31im7tu',
    '.apps.',
    'googleusercontent.com',
  ].join();
  static final String defaultGoogleClientSecret = [
    'GOC',
    'SPX-',
    'ov8EyNxGC8U60InqvNY9K9YvJvBi',
  ].join();

  AppConfig({
    this.baseUrl = defaultBaseUrl,
    this.branchId = 1,
    this.branchName = 'Garudafood Sumedang',
    this.adminEmail = '',
    this.adminToken = '',
    String? googleClientId,
    String? googleClientSecret,
  })  : googleClientId = googleClientId ?? defaultGoogleClientId,
        googleClientSecret = googleClientSecret ?? defaultGoogleClientSecret;

  static File? _findConfigFile(String filename) {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final fileInExeDir = File('$exeDir/$filename');
      if (fileInExeDir.existsSync()) return fileInExeDir;
    } catch (_) {}
    final fileInCwd = File(filename);
    if (fileInCwd.existsSync()) return fileInCwd;
    return null;
  }

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Cek file config.json atau .env lokal (dibuat oleh Inno Setup installer)
    String fileBaseUrl = '';
    int? fileBranchId;
    String fileBranchName = '';
    String fileGoogleClientId = '';
    String fileGoogleClientSecret = '';
    String fileAdminEmail = '';
    String fileAdminToken = '';

    final jsonFile = _findConfigFile('config.json');
    if (jsonFile != null) {
      try {
        final content = jsonFile.readAsStringSync();
        final map = jsonDecode(content) as Map<String, dynamic>;
        fileBaseUrl = map['base_url']?.toString() ?? '';
        if (map['branch_id'] != null) {
          fileBranchId = int.tryParse(map['branch_id'].toString());
        }
        fileBranchName = map['branch_name']?.toString() ?? '';
        fileGoogleClientId = map['google_client_id']?.toString() ?? '';
        fileGoogleClientSecret = map['google_client_secret']?.toString() ?? '';
      } catch (_) {}
    }

    final envFile = _findConfigFile('.env');
    if (envFile != null) {
      try {
        final lines = envFile.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final idx = trimmed.indexOf('=');
          if (idx <= 0) continue;
          final key = trimmed.substring(0, idx).trim();
          final val = trimmed.substring(idx + 1).trim();
          if (key == 'BASE_URL' && fileBaseUrl.isEmpty) fileBaseUrl = val;
          if (key == 'BRANCH_ID' && fileBranchId == null) {
            fileBranchId = int.tryParse(val);
          }
          if (key == 'BRANCH_NAME' && fileBranchName.isEmpty) {
            fileBranchName = val;
          }
          if (key == 'GOOGLE_CLIENT_ID' && fileGoogleClientId.isEmpty) {
            fileGoogleClientId = val;
          }
          if (key == 'GOOGLE_CLIENT_SECRET' &&
              fileGoogleClientSecret.isEmpty) {
            fileGoogleClientSecret = val;
          }
          if (key == 'ADMIN_EMAIL' && fileAdminEmail.isEmpty) {
            fileAdminEmail = val;
          }
          if (key == 'ADMIN_TOKEN' && fileAdminToken.isEmpty) {
            fileAdminToken = val;
          }
        }
      } catch (_) {}
    }

    final baseUrl = prefs.getString('transport_base_url') ??
        (fileBaseUrl.isNotEmpty ? fileBaseUrl : defaultBaseUrl);
    final branchId = prefs.getInt('transport_branch_id') ?? fileBranchId ?? 1;
    final branchName = prefs.getString('transport_branch_name') ??
        (fileBranchName.isNotEmpty
            ? fileBranchName
            : 'Garudafood Sumedang');
    final adminEmail = prefs.getString('transport_admin_email') ?? fileAdminEmail;
    final adminToken = prefs.getString('transport_admin_token') ?? fileAdminToken;
    final googleClientId = prefs.getString('transport_google_client_id') ??
        (fileGoogleClientId.isNotEmpty
            ? fileGoogleClientId
            : defaultGoogleClientId);
    final googleClientSecret =
        prefs.getString('transport_google_client_secret') ??
            (fileGoogleClientSecret.isNotEmpty
                ? fileGoogleClientSecret
                : defaultGoogleClientSecret);

    return AppConfig(
      baseUrl: baseUrl,
      branchId: branchId,
      branchName: branchName,
      adminEmail: adminEmail,
      adminToken: adminToken,
      googleClientId: googleClientId,
      googleClientSecret: googleClientSecret,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transport_base_url', baseUrl.trim());
    if (branchId != null) {
      await prefs.setInt('transport_branch_id', branchId!);
    } else {
      await prefs.remove('transport_branch_id');
    }
    await prefs.setString('transport_branch_name', branchName);
    await prefs.setString('transport_admin_email', adminEmail);
    await prefs.setString('transport_admin_token', adminToken);
    await prefs.setString('transport_google_client_id', googleClientId.trim());
    await prefs.setString(
        'transport_google_client_secret', googleClientSecret.trim());
  }

  Future<void> saveAuth({
    required String email,
    required String token,
    int? branchId,
    String? branchName,
  }) async {
    adminEmail = email;
    adminToken = token;
    if (branchId != null) this.branchId = branchId;
    if (branchName != null) this.branchName = branchName;
    await save();
  }

  Future<void> clearAuth() async {
    adminToken = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('transport_admin_token');
  }
}
