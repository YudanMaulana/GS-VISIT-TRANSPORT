import 'dart:async';
import 'package:flutter/material.dart';

import 'src/admin_auth.dart';
import 'src/api_client.dart';
import 'src/config.dart';
import 'src/models.dart';
import 'src/pages/transporter_area_page.dart';
import 'src/pages/transporter_checkin_page.dart';
import 'src/pages/transporter_checkout_page.dart';
import 'src/pages/transporter_dashboard_page.dart';
import 'src/pages/transporter_drivers_page.dart';
import 'src/pages/transporter_loads_page.dart';
import 'src/pages/transporter_support_page.dart';
import 'src/theme.dart';
import 'src/widgets/admin_login_dialog.dart';
import 'src/widgets/common_widgets.dart';
import 'src/widgets/header.dart';
import 'src/widgets/sidebar.dart';

const List<NavPageItem> transportNavItems = [
  NavPageItem(
    index: 0,
    title: 'Dashboard',
    subtitle: 'Ringkasan operasional armada & aktivitas transporter di pabrik.',
    icon: Icons.grid_view_rounded,
  ),
  NavPageItem(
    index: 1,
    title: 'Transporter di Area',
    subtitle: 'Daftar armada dan sopir yang sedang aktif berada di dalam area pabrik.',
    icon: Icons.local_shipping_rounded,
  ),
  NavPageItem(
    index: 2,
    title: 'Konfirmasi Masuk',
    subtitle: 'Pencatatan kedatangan transporter, alur bongkar/muat, dan TTD gerbang.',
    icon: Icons.login_rounded,
  ),
  NavPageItem(
    index: 3,
    title: 'Konfirmasi Keluar',
    subtitle: 'Pemeriksaan muatan, verifikasi segel/dokumen, dan penyelesaian sesi armada.',
    icon: Icons.logout_rounded,
  ),
  NavPageItem(
    index: 4,
    title: 'Akun Sopir',
    subtitle: 'Manajemen status aktif/non-aktif akun sopir, verifikasi SIM, & ekspedisi.',
    icon: Icons.manage_accounts_rounded,
  ),
  NavPageItem(
    index: 5,
    title: 'Bongkar Muat & Audit',
    subtitle: 'Riwayat audit log dan riwayat pergerakan muatan armada transporter.',
    icon: Icons.table_view_rounded,
  ),
  NavPageItem(
    index: 6,
    title: 'Bantuan & Laporan',
    subtitle: 'Pelaporan kendala gerbang dan pusat informasi teknis transporter.',
    icon: Icons.support_agent_rounded,
  ),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(GsVisitTransportApp(config: config));
}

class GsVisitTransportApp extends StatelessWidget {
  final AppConfig config;
  const GsVisitTransportApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garudashield Transporter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: TransportHomePage(config: config),
    );
  }
}

class TransportHomePage extends StatefulWidget {
  final AppConfig config;
  const TransportHomePage({super.key, required this.config});

  @override
  State<TransportHomePage> createState() => _TransportHomePageState();
}

class _TransportHomePageState extends State<TransportHomePage> {
  final AdminSession _session = AdminSession();
  late TransportApiClient _client;
  int _currentPage = 0;
  ActiveGuestRow? _selectedCheckoutRow;
  bool _initializing = true;
  bool _sidebarCollapsed = false;

  late DateTime _now;
  Timer? _clockTimer;
  String _statusText =
      'Aplikasi siap digunakan. Pilih menu di sidebar untuk memantau atau mengonfirmasi armada transporter.';

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _client = TransportApiClient(
      baseUrl: widget.config.baseUrl,
      adminToken: widget.config.adminToken,
    );
    _checkStoredSession();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStoredSession() async {
    if (widget.config.adminToken.isNotEmpty &&
        widget.config.adminEmail.isNotEmpty) {
      try {
        final me = await _client.fetchMe();
        if (me['success'] == true) {
          final admin = me['admin'] as Map<String, dynamic>?;
          _session.unlockFromServer(
            email: admin?['email']?.toString() ?? widget.config.adminEmail,
            fullName: admin?['full_name']?.toString() ?? '',
            role: admin?['role']?.toString() ?? 'admin_transport',
            branchId: me['branch_id'] is int
                ? me['branch_id'] as int
                : widget.config.branchId,
            token: widget.config.adminToken,
          );
        }
      } catch (_) {
        // Token expired/revoked, operator will log in
      }
    }
    if (mounted) setState(() => _initializing = false);
  }

  void _openLogin() async {
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          AdminLoginDialog(config: widget.config, session: _session),
    );

    if (unlocked == true && mounted) {
      setState(() {
        _client = TransportApiClient(
          baseUrl: widget.config.baseUrl,
          adminToken: _session.token,
        );
        _statusText = 'Operator terhubung sebagai ${_session.email}.';
      });
    }
  }

  void _logout() async {
    _session.lock();
    await widget.config.clearAuth();
    if (mounted) {
      setState(() {
        _statusText = 'Sesi terkunci. Silakan masuk untuk melanjutkan.';
      });
    }
  }

  void _onSelectPage(int index) {
    setState(() {
      _currentPage = index;
      if (index != 3) _selectedCheckoutRow = null;
      _statusText = 'Membuka menu ${transportNavItems[index].title}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F0F3D91),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/branding/logo.png',
                  height: 48,
                  width: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.local_shipping_rounded,
                    size: 40,
                    color: brandBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: brandBlue,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Menyiapkan Garudashield Transporter…',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_session.isUnlocked) {
      return _buildLockScreen();
    }

    final currentMeta = transportNavItems[_currentPage];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F8FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Sidebar(
                  selectedIndex: _currentPage,
                  onSelect: _onSelectPage,
                  items: transportNavItems,
                  isCollapsed: _sidebarCollapsed,
                ),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Header(
                            title: currentMeta.title,
                            subtitle: currentMeta.subtitle,
                            now: _now,
                            branchName: widget.config.branchName.isNotEmpty
                                ? widget.config.branchName
                                : (widget.config.branchId != null
                                    ? 'Cabang #${widget.config.branchId}'
                                    : 'Sumedang Plant'),
                            operatorEmail: _session.email,
                            onLogout: _logout,
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: _buildPage(),
                          ),
                          const SizedBox(height: 14),
                          StatusBar(text: _statusText),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Floating collapse toggle button persis seperti FaceID Windows shell
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _sidebarCollapsed ? 96.0 - 20 : 280.0 - 20,
              top: 36,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _sidebarCollapsed = !_sidebarCollapsed;
                    });
                  },
                  icon: Icon(
                    _sidebarCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: const CircleBorder(),
                    side: const BorderSide(
                      color: Colors.white24,
                      width: 1.5,
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F8FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F0F3D91),
                  blurRadius: 36,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: brandYellow.withValues(alpha: 0.72),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: brandYellow.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      const BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/branding/logo.png',
                    height: 58,
                    width: 58,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_shipping_rounded,
                      size: 48,
                      color: brandBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'GARUDASHIELD',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TRANSPORTER GATE DESK',
                  style: TextStyle(
                    color: brandBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sistem Manajemen Gerbang Logistik & Transporter\nPT. GARUDAFOOD PUTRA PUTRI JAYA Tbk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openLogin,
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      'Masuk dengan Akun Google Petugas',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case 0:
        return TransporterDashboardPage(
          client: _client,
          config: widget.config,
          session: _session,
          onNavigate: (idx) {
            setState(() {
              _currentPage = idx;
              if (idx != 3) _selectedCheckoutRow = null;
            });
          },
        );
      case 1:
        return TransporterAreaPage(
          client: _client,
          config: widget.config,
          session: _session,
          onSelectCheckout: (row) {
            setState(() {
              _selectedCheckoutRow = row;
              _currentPage = 3;
            });
          },
        );
      case 2:
        return TransporterCheckinPage(
          client: _client,
          config: widget.config,
          session: _session,
          onDone: () => setState(() => _currentPage = 1),
        );
      case 3:
        return TransporterCheckoutPage(
          client: _client,
          config: widget.config,
          session: _session,
          initialSelection: _selectedCheckoutRow,
          onDone: () => setState(() => _currentPage = 1),
        );
      case 4:
        return TransporterDriversPage(
          client: _client,
          config: widget.config,
          session: _session,
        );
      case 5:
        return TransporterLoadsPage(
          client: _client,
          config: widget.config,
          session: _session,
        );
      case 6:
        return TransporterSupportPage(
          client: _client,
          config: widget.config,
          session: _session,
        );
      default:
        return const SizedBox();
    }
  }
}
