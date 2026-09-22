import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi aplikasi GS VISIT TRANSPORT.
/// Menyimpan pengaturan server, kredensial login admin, cabang, dan OAuth Google.
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

  AppConfig({
    this.baseUrl = defaultBaseUrl,
    this.branchId,
    this.branchName = '',
    this.adminEmail = '',
    this.adminToken = '',
    this.googleClientId = '',
    this.googleClientSecret = '',
  });

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      baseUrl: prefs.getString('transport_base_url') ?? defaultBaseUrl,
      branchId: prefs.getInt('transport_branch_id'),
      branchName: prefs.getString('transport_branch_name') ?? '',
      adminEmail: prefs.getString('transport_admin_email') ?? '',
      adminToken: prefs.getString('transport_admin_token') ?? '',
      googleClientId: prefs.getString('transport_google_client_id') ?? '',
      googleClientSecret: prefs.getString('transport_google_client_secret') ?? '',
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
    await prefs.setString('transport_google_client_secret', googleClientSecret.trim());
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
