import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: brandBlueSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.table_view_rounded,
                        color: brandBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Riwayat Bongkar Muat & Audit Log',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Total ${_auditLogs.length} riwayat tercatat di server',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: brandBlue,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: brandBlue,
                      strokeWidth: 3,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          'Galat: $_error',
                          style: const TextStyle(
                            color: Color(0xFFD64045),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : _auditLogs.isEmpty
                        ? const EmptyStateCard(
                            title: 'Belum Ada Riwayat Audit',
                            description:
                                'Belum ada catatan riwayat pergerakan muatan atau aktivitas konfirmasi gerbang.',
                            icon: Icons.history_rounded,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _auditLogs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final log = _auditLogs[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: panelColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: brandBlueSoft,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.history_rounded,
                                        color: brandBlue,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  log['action']?.toString() ??
                                                      'Aktivitas Transporter',
                                                  style: const TextStyle(
                                                    color: textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (log['queue_number'] != null ||
                                                  log['plan_id'] != null) ...[
                                                const SizedBox(width: 8),
                                                StatusPill(
                                                  text:
                                                      'Antrean #${log['queue_number'] ?? log['plan_id']}',
                                                  color: brandBlue,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Petugas: ${log["officer"] ?? "-"} • Nopol: ${log["plate_number"] ?? "-"} • ${log["timestamp"] ?? ""}',
                                            style: const TextStyle(
                                              color: textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (log['details'] != null &&
                                        log['details'].toString().isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        log['details'].toString(),
                                        style: const TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}
