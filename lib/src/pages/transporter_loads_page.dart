import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';

class TransporterLoadsPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;

  const TransporterLoadsPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
  });

  @override
  State<TransporterLoadsPage> createState() => _TransporterLoadsPageState();
}

class _TransporterLoadsPageState extends State<TransporterLoadsPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _auditLogs = [];
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
      final logs = await widget.client.fetchAuditLogs(
        branchId: widget.session.branchId ?? widget.config.branchId,
      );
      if (mounted) setState(() => _auditLogs = logs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Riwayat Bongkar Muat & Audit Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Catatan histori muatan armada, waktu kedatangan/kepulangan, dan petugas penerima',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Segarkan data',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : _error != null
                      ? Center(child: Text('Galat: $_error', style: const TextStyle(color: Colors.redAccent)))
                      : _auditLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada catatan riwayat muatan atau audit log.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _auditLogs.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                              itemBuilder: (context, index) {
                                final log = _auditLogs[index];
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.history, color: Colors.amber, size: 20),
                                  ),
                                  title: Text(
                                    log['action']?.toString() ?? 'Aktivitas Transporter',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Petugas: ${log["officer"] ?? "-"} • Nopol: ${log["plate_number"] ?? "-"} • ${log["timestamp"] ?? ""}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    log['details']?.toString() ?? '',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
