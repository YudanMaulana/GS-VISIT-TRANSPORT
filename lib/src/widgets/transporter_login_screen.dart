import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../google_desktop_auth.dart';
import '../theme.dart';
import 'common_widgets.dart';

/// Halaman Login Gerbang Transporter dengan estetika Split Screen Neon Dark Tech
/// terinspirasi dari FaceID Windows Desktop (Garuda Shield).
class TransporterLoginScreen extends StatefulWidget {
  final AppConfig config;
  final AdminSession session;
  final void Function(AdminSession session, TransportApiClient client) onLoginSuccess;

  const TransporterLoginScreen({
    super.key,
    required this.config,
    required this.session,
    required this.onLoginSuccess,
  });

  @override
  State<TransporterLoginScreen> createState() => _TransporterLoginScreenState();
}

class _TransporterLoginScreenState extends State<TransporterLoginScreen> {
  late final TextEditingController _serverUrl =
      TextEditingController(text: widget.config.baseUrl);
  late final TextEditingController _clientId =
      TextEditingController(text: widget.config.googleClientId);
  late final TextEditingController _clientSecret =
      TextEditingController(text: widget.config.googleClientSecret);

  bool _busy = false;
  String? _error;
  bool _showSettings = false;
  String? _settingsFeedback;

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
      final sUrl = _serverUrl.text.trim();

      if (cId.isEmpty) {
        throw Exception(
          'Google Client ID belum diatur. Klik ikon roda gigi di pojok kanan atas untuk mengisi pengaturan OAuth.',
        );
      }

      final auth = GoogleDesktopAuth(clientId: cId, clientSecret: cSec);
      final idToken = await auth.signInIdToken();

      final result = await TransportApiClient.loginGoogle(
        baseUrl: sUrl,
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
      widget.config.baseUrl = sUrl;
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

      final client = TransportApiClient(
        baseUrl: sUrl,
        adminToken: token,
      );

      if (mounted) {
        widget.onLoginSuccess(widget.session, client);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _busy = false;
        });
      }
    }
  }

  void _saveSettings() async {
    final sUrl = _serverUrl.text.trim();
    final cId = _clientId.text.trim();
    final cSec = _clientSecret.text.trim();

    widget.config.baseUrl = sUrl;
    widget.config.googleClientId = cId;
    widget.config.googleClientSecret = cSec;
    await widget.config.save();

    if (mounted) {
      setState(() {
        _settingsFeedback = 'Pengaturan server & kredensial berhasil disimpan!';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _settingsFeedback = null);
      });
    }
  }

  String _cleanHost(String url) {
    try {
      final u = Uri.parse(url);
      return u.host.isNotEmpty ? u.host : url;
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06152B), Color(0xFF0F3D91), Color(0xFF030D1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1040,
                maxHeight: 640,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ============================================
                    // PANEL KIRI: HERO BRANDING (NEON DARK TECH)
                    // ============================================
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B2455), Color(0xFF061430)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Glowing Ambient Rings
                            Positioned(
                              top: -70,
                              left: -70,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: brandYellow.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -100,
                              right: -40,
                              child: Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            // Konten Utama Branding
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 44,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo Squircle Badge
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: brandYellow.withValues(alpha: 0.8),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: brandYellow.withValues(alpha: 0.28),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                        const BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/branding/logo.png',
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        Icons.local_shipping_rounded,
                                        size: 48,
                                        color: brandBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Flow Highlight Title
                                  const _FlowHighlightText(
                                    'GARUDA SHIELD',
                                    baseColor: Colors.white,
                                    highlightColor: brandYellow,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    delayMs: 300,
                                  ),
                                  const SizedBox(height: 8),

                                  // Badge Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: brandYellow,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const _FlowHighlightText(
                                          'TRANSPORTER',
                                          baseColor: brandBlueDeep,
                                          highlightColor: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.9,
                                          delayMs: 600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(7),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: const Text(
                                          'v1.0.0',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Text(
                                          'SUMEDANG',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    'Sistem pengamanan gerbang logistik, pos satpam, dan pengawasan armada pabrik Garudafood Sumedang terintegrasi.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13.5,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Bullet Features dengan Glowing Icon
                                  _buildBrandingFeature(
                                    Icons.local_shipping_rounded,
                                    'Monitoring 3 Area (GF, DC, MBR)',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildBrandingFeature(
                                    Icons.draw_rounded,
                                    'Verifikasi Dokumen & TTD Digital',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildBrandingFeature(
                                    Icons.cloud_sync_rounded,
                                    'Sinkronisasi Realtime Gerbang Logistik',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildBrandingFeature(
                                    Icons.security_rounded,
                                    'Autentikasi Akun Resmi Petugas Satpam',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ============================================
                    // PANEL KANAN: FORM LOGIN & PENGATURAN (LIGHT)
                    // ============================================
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Top: Status Koneksi & Tombol Pengaturan
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFD4E3FC),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _cleanHost(_serverUrl.text.trim()),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: brandBlueDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Tombol Roda Gigi Pengaturan
                                Tooltip(
                                  message: _showSettings
                                      ? 'Kembali ke Form Login'
                                      : 'Pengaturan Server & OAuth',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setState(() {
                                          _showSettings = !_showSettings;
                                          _error = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _showSettings
                                              ? brandBlueSoft
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _showSettings
                                                ? brandBlue
                                                : borderColor,
                                          ),
                                        ),
                                        child: Icon(
                                          _showSettings
                                              ? Icons.close_rounded
                                              : Icons.settings_outlined,
                                          size: 18,
                                          color: _showSettings
                                              ? brandBlue
                                              : textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // VIEW PENGATURAN SERVER / VIEW LOGIN
                            if (_showSettings)
                              _buildSettingsView()
                            else
                              _buildMainLoginView(),

                            const Spacer(),

                            // Security Footnote
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Akses terenkripsi & tercatat dalam audit log sistem Garudashield.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: textMuted.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tampilan Form Login Petugas
  Widget _buildMainLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: brandBlue,
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Login Petugas',
              style: TextStyle(
                color: textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const _FlowHighlightText(
          'Silakan masuk dengan akun Google resmi petugas untuk membuka akses operasional gerbang transporter.',
          baseColor: textMuted,
          highlightColor: Color(0xFF0A2558),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          lineHeight: 1.5,
          tintStrength: 1,
          baseOpacity: 0.75,
        ),
        const SizedBox(height: 24),

        // Error Banner jika ada kendala
        if ((_error ?? '').trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC9C9)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFF9D1C1C),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF9D1C1C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Tombol Login Google Interaktif
        if (_busy) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: brandBlueSoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(brandBlue),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Menghubungkan ke Google Authenticator...',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Browser peramban akan terbuka otomatis untuk menyelesaikan login.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: _AnimatedOutlinedButtonFrame(
              borderRadius: 14,
              enabled: true,
              child: OutlinedButton(
                onPressed: _loginGoogle,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1F1F1F),
                  side: BorderSide.none,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GoogleGIconPainter()),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Masuk dengan Akun Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F1F),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.open_in_browser_rounded,
                size: 14,
                color: textMuted,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Browser akan terbuka otomatis, lalu kembali ke aplikasi setelah verifikasi.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Tampilan Pengaturan Server & Kredensial OAuth
  Widget _buildSettingsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_outlined, color: brandBlue, size: 22),
                SizedBox(width: 8),
                Text(
                  'Pengaturan Server & OAuth',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _showSettings = false),
              child: const Text('Batal'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Konfigurasi alamat server backend API dan kredensial OAuth Google Desktop.',
          style: TextStyle(color: textMuted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (_settingsFeedback != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _settingsFeedback!,
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        InputField(
          label: 'URL Server Backend',
          controller: _serverUrl,
          hintText: 'https://garudafood.choclatosxquest.web.id/garudafood-visit',
          prefixIcon: Icons.dns_rounded,
        ),
        const SizedBox(height: 10),
        InputField(
          label: 'Google Client ID (Desktop)',
          controller: _clientId,
          hintText: 'xxxxxx.apps.googleusercontent.com',
          prefixIcon: Icons.key_rounded,
        ),
        const SizedBox(height: 10),
        InputField(
          label: 'Google Client Secret',
          controller: _clientSecret,
          hintText: 'GOCSPX-xxxxxx',
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveSettings,
            style: FilledButton.styleFrom(
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text(
              'Simpan Pengaturan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: brandYellow, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGETS ANIMASI (PERSIS SEPERTI DI FACEID WINDOWS FLUTTER)
// ============================================================================

class _AnimatedOutlinedButtonFrame extends StatefulWidget {
  const _AnimatedOutlinedButtonFrame({
    required this.child,
    required this.borderRadius,
    required this.enabled,
  });

  final Widget child;
  final double borderRadius;
  final bool enabled;

  @override
  State<_AnimatedOutlinedButtonFrame> createState() =>
      _AnimatedOutlinedButtonFrameState();
}

class _AnimatedOutlinedButtonFrameState
    extends State<_AnimatedOutlinedButtonFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AnimatedButtonBorderPainter(
          progress: _controller,
          borderRadius: widget.borderRadius,
          enabled: widget.enabled,
        ),
        child: widget.child,
      ),
    );
  }
}

class _AnimatedButtonBorderPainter extends CustomPainter {
  _AnimatedButtonBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.enabled,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double borderRadius;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.8),
      Radius.circular(borderRadius),
    );

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = enabled
          ? const Color(0xFFCBD5E1)
          : const Color(0xFFE2E8F0);
    canvas.drawRRect(rrect, basePaint);

    if (!enabled) return;

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..shader = LinearGradient(
        colors: const [
          Color(0x001249AB),
          Color(0x464D74B7),
          Color(0x962353AB),
          Color(0xA52A62C9),
          Color(0x461249AB),
          Color(0x003D6BBB),
        ],
        stops: const [0, 0.4, 0.48, 0.52, 0.6, 1],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        transform: _SlidingGradientTransform(
          slidePercent: (progress.value * 2) - 1,
        ),
      ).createShader(rect);
    canvas.drawRRect(rrect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedButtonBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.enabled != enabled ||
        oldDelegate.progress != progress;
  }
}

class _FlowHighlightText extends StatefulWidget {
  const _FlowHighlightText(
    this.text, {
    required this.baseColor,
    required this.highlightColor,
    this.fontSize = 12,
    this.fontWeight,
    this.lineHeight = 1.4,
    this.delayMs = 0,
    this.tintStrength = 0.75,
    this.letterSpacing,
    this.baseOpacity = 1,
  });

  final String text;
  final Color baseColor;
  final Color highlightColor;
  final double fontSize;
  final FontWeight? fontWeight;
  final double lineHeight;
  final int delayMs;
  final double tintStrength;
  final double? letterSpacing;
  final double baseOpacity;

  @override
  State<_FlowHighlightText> createState() => _FlowHighlightTextState();
}

class _FlowHighlightTextState extends State<_FlowHighlightText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: widget.baseColor.withValues(alpha: widget.baseOpacity),
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
      height: widget.lineHeight,
      letterSpacing: widget.letterSpacing,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Text(widget.text, style: textStyle),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    widget.highlightColor.withValues(
                      alpha: widget.tintStrength * 0.28,
                    ),
                    widget.highlightColor.withValues(
                      alpha: widget.tintStrength * 0.82,
                    ),
                    widget.highlightColor.withValues(
                      alpha: widget.tintStrength * 0.28,
                    ),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.28, 0.42, 0.5, 0.58, 0.72, 1],
                  transform: _SlidingGradientTransform(
                    slidePercent: (_controller.value * 2) - 1,
                  ),
                ).createShader(bounds);
              },
              child: Text(
                widget.text,
                style: textStyle.copyWith(color: widget.highlightColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Pelukis resmi logo 4 warna Google 'G'. Dikonversi dari standar SVG 48x48 Google.
class _GoogleGIconPainter extends CustomPainter {
  const _GoogleGIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0;
    canvas.save();
    canvas.scale(s, s);

    final paint = Paint()..style = PaintingStyle.fill;

    // Merah: busur atas
    paint.color = const Color(0xFFEA4335);
    final red = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.5, 9.5, 30.6, 10.7, 33, 13.1)
      ..lineTo(39.7, 6.4)
      ..cubicTo(35.6, 2.4, 30.2, 0, 24, 0)
      ..cubicTo(14.6, 0, 6.5, 5.4, 2.6, 13.2)
      ..lineTo(10.4, 19.3)
      ..cubicTo(12.3, 13.2, 17.6, 9.5, 24, 9.5)
      ..close();
    canvas.drawPath(red, paint);

    // Biru: sisi kanan & palang
    paint.color = const Color(0xFF4285F4);
    final blue = Path()
      ..moveTo(46.5, 24.5)
      ..cubicTo(46.5, 22.9, 46.4, 21.4, 46.1, 20.0)
      ..lineTo(24, 20.0)
      ..lineTo(24, 29)
      ..lineTo(36.7, 29)
      ..cubicTo(36.1, 32, 34.4, 34.5, 31.9, 36.2)
      ..lineTo(39.4, 42.0)
      ..cubicTo(43.9, 37.9, 46.5, 31.8, 46.5, 24.5)
      ..close();
    canvas.drawPath(blue, paint);

    // Kuning: sisi kiri
    paint.color = const Color(0xFFFBBC05);
    final yellow = Path()
      ..moveTo(10.4, 28.7)
      ..cubicTo(9.9, 27.2, 9.6, 25.7, 9.6, 24.0)
      ..cubicTo(9.6, 22.3, 9.9, 20.8, 10.4, 19.3)
      ..lineTo(2.6, 13.2)
      ..cubicTo(0.9, 16.4, 0, 20.1, 0, 24)
      ..cubicTo(0, 27.9, 0.9, 31.6, 2.6, 34.8)
      ..lineTo(10.4, 28.7)
      ..close();
    canvas.drawPath(yellow, paint);

    // Hijau: busur bawah
    paint.color = const Color(0xFF34A853);
    final green = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.2, 48, 35.5, 46, 39.3, 42.5)
      ..lineTo(31.8, 36.7)
      ..cubicTo(29.8, 38.1, 27.1, 39.0, 24, 39.0)
      ..cubicTo(17.6, 39.0, 12.3, 35.3, 10.4, 29.7)
      ..lineTo(2.6, 35.8)
      ..cubicTo(6.5, 42.6, 14.6, 48, 24, 48)
      ..close();
    canvas.drawPath(green, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
