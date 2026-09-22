import 'package:flutter/material.dart';
import 'src/admin_auth.dart';
import 'src/api_client.dart';
import 'src/config.dart';
import 'src/models.dart';
import 'src/pages/transporter_area_page.dart';
import 'src/pages/transporter_checkin_page.dart';
import 'src/pages/transporter_checkout_page.dart';
import 'src/pages/transporter_dashboard_page.dart';
import 'src/pages/transporter_loads_page.dart';
import 'src/pages/transporter_support_page.dart';
import 'src/widgets/admin_login_dialog.dart';

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
      title: 'GS VISIT TRANSPORT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09111E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Color(0xFF0F1A2E),
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _client = TransportApiClient(
      baseUrl: widget.config.baseUrl,
      adminToken: widget.config.adminToken,
    );
    _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    if (widget.config.adminToken.isNotEmpty && widget.config.adminEmail.isNotEmpty) {
      try {
        final me = await _client.fetchMe();
        if (me['success'] == true) {
          final admin = me['admin'] as Map<String, dynamic>?;
          _session.unlockFromServer(
            email: admin?['email']?.toString() ?? widget.config.adminEmail,
            fullName: admin?['full_name']?.toString() ?? '',
            role: admin?['role']?.toString() ?? 'admin_transport',
            branchId: me['branch_id'] is int ? me['branch_id'] as int : widget.config.branchId,
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
      builder: (_) => AdminLoginDialog(config: widget.config, session: _session),
    );

    if (unlocked == true && mounted) {
      setState(() {
        _client = TransportApiClient(
          baseUrl: widget.config.baseUrl,
          adminToken: _session.token,
        );
      });
    }
  }

  void _logout() async {
    _session.lock();
    await widget.config.clearAuth();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    if (!_session.isUnlocked) {
      return _buildLockScreen();
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070F1E), Color(0xFF0F1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.amber, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'GS VISIT TRANSPORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aplikasi Manajemen & Logistik Transporter (Windows)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openLogin,
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: const Text(
                      'Masuk dengan Akun Google Petugas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2E),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                widget.config.branchName.isNotEmpty
                    ? 'Cabang: ${widget.config.branchName}'
                    : 'Cabang Garudafood (ID: ${widget.config.branchId ?? "Global"})',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 16, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              Text(
                _session.email,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 20),
                tooltip: 'Keluar / Kunci Konsol',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1424),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GS TRANSPORT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Admin Gerbang Logistik',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _navItem(0, Icons.dashboard_outlined, 'Dashboard Utama'),
                _navItem(1, Icons.airport_shuttle_outlined, 'Transporter di Area'),
                _navItem(2, Icons.login_outlined, 'Konfirmasi Masuk'),
                _navItem(3, Icons.logout_outlined, 'Konfirmasi Keluar'),
                _navItem(4, Icons.history_outlined, 'Bongkar Muat & Audit'),
                _navItem(5, Icons.support_agent_outlined, 'Bantuan & Laporan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentPage == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: active,
        selectedTileColor: Colors.amber.withValues(alpha: 0.15),
        leading: Icon(icon, color: active ? Colors.amber : Colors.white60, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.amber : Colors.white70,
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _currentPage = index;
            if (index != 3) _selectedCheckoutRow = null;
          });
        },
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
          onNavigate: (idx) => setState(() => _currentPage = idx),
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
        return TransporterLoadsPage(
          client: _client,
          config: widget.config,
          session: _session,
        );
      case 5:
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
