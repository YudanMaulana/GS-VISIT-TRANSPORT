import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../google_desktop_auth.dart';
import '../theme.dart';
import 'common_widgets.dart';

/// Dialog Login Google Admin untuk GS VISIT TRANSPORT berpenampilan senada FaceID Desktop.
class AdminLoginDialog extends StatefulWidget {
  final AppConfig config;
  final AdminSession session;

  const AdminLoginDialog({
    super.key,
    required this.config,
    required this.session,
  });

  @override
  State<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog> {
  late final TextEditingController _serverUrl =
      TextEditingController(text: widget.config.baseUrl);
  late final TextEditingController _clientId =
      TextEditingController(text: widget.config.googleClientId);
  late final TextEditingController _clientSecret =
      TextEditingController(text: widget.config.googleClientSecret);

  bool _busy = false;
  String? _error;
  bool _showSettings = false;

  @override
  void dispose() {
    _serverUrl.dispose();
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final cId = _clientId.text.trim();
      final cSec = _clientSecret.text.trim();

      if (cId.isEmpty) {
        throw Exception(
            'Google Client ID belum diatur. Klik "Pengaturan Server & OAuth" di bawah untuk mengisi.');
      }

      final auth = GoogleDesktopAuth(clientId: cId, clientSecret: cSec);
      final idToken = await auth.signInIdToken();

      final result = await TransportApiClient.loginGoogle(
        baseUrl: _serverUrl.text.trim(),
        idToken: idToken,
      );

      final success = result['success'] == true;
      if (!success) {
        final msg = result['message'] ?? result['detail'] ?? 'Login ditolak oleh server.';
        throw Exception(msg);
      }

      final adminData = result['admin'] as Map<String, dynamic>?;
      final email = adminData?['email']?.toString() ?? 'admin@garudafood.com';
      final role = adminData?['role']?.toString() ?? 'admin_transport';
      final fullName = adminData?['full_name']?.toString() ?? '';
      final token = result['token']?.toString() ?? '';
      final branchId = result['branch_id'] is int ? result['branch_id'] as int : null;

      // Simpan konfigurasi
      widget.config.baseUrl = _serverUrl.text.trim();
      widget.config.googleClientId = cId;
      widget.config.googleClientSecret = cSec;
      await widget.config.saveAuth(
        email: email,
        token: token,
        branchId: branchId,
      );

      widget.session.unlockFromServer(
        email: email,
        fullName: fullName,
        role: role,
        branchId: branchId,
        token: token,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0F3D91),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: brandBlueSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Image.asset(
                    'assets/branding/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_shipping_rounded,
                      color: brandBlue,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GARUDASHIELD',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'TRANSPORTER • LOGIN PETUGAS',
                        style: TextStyle(
                          color: brandBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brandBlueSoft.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: brandBlue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Silakan masuk menggunakan Akun Google Petugas yang terdaftar pada sistem keamanan GarudaFood.',
                      style: TextStyle(color: textPrimary, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFC0C0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFD64045), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFD64045), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _loginGoogle,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded, size: 20),
              label: Text(
                _busy ? 'Menghubungkan ke Google...' : 'Masuk dengan Akun Google',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _showSettings = !_showSettings),
              icon: Icon(
                _showSettings ? Icons.expand_less_rounded : Icons.settings_outlined,
                size: 16,
                color: textMuted,
              ),
              label: Text(
                _showSettings ? 'Sembunyikan Pengaturan' : 'Pengaturan Server & OAuth',
                style: const TextStyle(color: textMuted, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            if (_showSettings) ...[
              const SizedBox(height: 12),
              InputField(
                label: 'URL Server Backend',
                controller: _serverUrl,
                hintText: 'http://127.0.0.1:8000',
              ),
              const SizedBox(height: 10),
              InputField(
                label: 'Google Client ID (Desktop)',
                controller: _clientId,
                hintText: 'xxxxxx.apps.googleusercontent.com',
              ),
              const SizedBox(height: 10),
              InputField(
                label: 'Google Client Secret',
                controller: _clientSecret,
                hintText: 'GOCSPX-xxxxxx',
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal', style: TextStyle(color: textMuted, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
