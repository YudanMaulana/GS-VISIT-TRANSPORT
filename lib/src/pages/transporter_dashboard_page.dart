import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';

class TransporterDashboardPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;
  final Function(int pageIndex) onNavigate;

  const TransporterDashboardPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
    required this.onNavigate,
  });

  @override
  State<TransporterDashboardPage> createState() => _TransporterDashboardPageState();
}

class _TransporterDashboardPageState extends State<TransporterDashboardPage> {
  bool _loading = false;
  List<ActiveGuestRow> _transporters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.client.fetchActiveTransporters(
        branchId: widget.session.branchId ?? widget.config.branchId,
      );
      if (mounted) setState(() => _transporters = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final count = _transporters.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pusat Kendali Transporter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoring armada & konfirmasi gerbang logistik • ${widget.session.email}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                      )
                    : const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Muat ulang data',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Armada di Area',
                  value: '$count',
                  subtitle: 'Truk aktif di dalam pabrik',
                  icon: Icons.local_shipping,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  title: 'Sesi Petugas',
                  value: widget.session.role.isNotEmpty ? widget.session.role : 'Aktif',
                  subtitle: widget.session.email,
                  icon: Icons.verified_user,
                  color: Colors.tealAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionCard(
                  title: 'Konfirmasi Masuk',
                  subtitle: 'Input armada baru & TTD satpam',
                  icon: Icons.login,
                  onTap: () => widget.onNavigate(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionCard(
                  title: 'Konfirmasi Keluar',
                  subtitle: 'Pemeriksaan muatan & selesai',
                  icon: Icons.logout,
                  onTap: () => widget.onNavigate(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Armada di Area Pabrik (Real-time)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => widget.onNavigate(1),
                        icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.amber),
                        label: const Text('Buka Papan Penuh', style: TextStyle(color: Colors.amber)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Galat: $_error', style: const TextStyle(color: Colors.redAccent)),
                    )
                  else if (_transporters.isEmpty && !_loading)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Tidak ada armada transporter di area saat ini.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _transporters.length,
                        separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.06)),
                        itemBuilder: (context, index) {
                          final row = _transporters[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_shipping, color: Colors.amber, size: 22),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    row.name.isNotEmpty ? row.name : 'Pengemudi Transporter',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (row.loadType == 'bongkar' ? Colors.blue : Colors.orange).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: (row.loadType == 'bongkar' ? Colors.blue : Colors.orange).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '#${row.queueNumber ?? row.planId} • ${(row.loadType.isNotEmpty ? row.loadType.toUpperCase() : "TRANSPORTER")}',
                                    style: TextStyle(
                                      color: row.loadType == 'bongkar' ? Colors.blueAccent : Colors.orangeAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Antrean: #${row.queueNumber ?? row.planId} • Nopol: ${row.vehiclePlate.isNotEmpty ? row.vehiclePlate : "-"} • Ekspedisi: ${row.company.isNotEmpty ? row.company : "-"} • Masuk: ${_formatTime(row.checkinAt)}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => widget.onNavigate(3),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Konfirmasi Keluar'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(icon, color: Colors.amber, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
