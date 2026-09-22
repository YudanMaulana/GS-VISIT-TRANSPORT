import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../google_desktop_auth.dart';

/// Dialog Login Google Admin untuk GS VISIT TRANSPORT.
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
          color: const Color(0xFF0F1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 16),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.amber,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GS VISIT TRANSPORT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Konsol Admin & Logistik Transporter',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Masuk dengan Akun Google yang telah didaftarkan administrator server via CLI.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _busy ? null : _loginGoogle,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                    )
                  : const Icon(Icons.login, size: 20),
              label: Text(
                _busy ? 'Menghubungkan ke Google...' : 'Masuk dengan Google',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _showSettings = !_showSettings),
              icon: Icon(
                _showSettings ? Icons.expand_less : Icons.settings_outlined,
                size: 16,
                color: Colors.white60,
              ),
              label: Text(
                _showSettings ? 'Sembunyikan Pengaturan' : 'Pengaturan Server & OAuth',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            if (_showSettings) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _serverUrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'URL Server Backend',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _clientId,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Google Client ID (Desktop)',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _clientSecret,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Google Client Secret',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
