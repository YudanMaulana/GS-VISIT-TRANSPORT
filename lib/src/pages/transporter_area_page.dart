import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';

class TransporterAreaPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;
  final Function(ActiveGuestRow row)? onSelectCheckout;

  const TransporterAreaPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
    this.onSelectCheckout,
  });

  @override
  State<TransporterAreaPage> createState() => _TransporterAreaPageState();
}

class _TransporterAreaPageState extends State<TransporterAreaPage> {
  final TextEditingController _search = TextEditingController();
  bool _loading = false;
  List<ActiveGuestRow> _transporters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  List<ActiveGuestRow> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _transporters;
    return _transporters.where((row) {
      return row.name.toLowerCase().contains(q) ||
          row.company.toLowerCase().contains(q) ||
          row.vehiclePlate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_outlined, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Papan Transporter di Area',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Daftar kendaraan dan armada pengangkut yang sedang berada di area pabrik',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Segarkan data',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari sopir, nopol kendaraan, atau ekspedisi...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF0F1A2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  'Total: ${list.length} Armada',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
                  : _error != null
                      ? Center(
                          child: Text('Galat: $_error', style: const TextStyle(color: Colors.redAccent)),
                        )
                      : list.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada armada transporter yang cocok.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                              itemBuilder: (context, index) {
                                final row = list[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                                    child: const Icon(Icons.local_shipping, color: Colors.amber),
                                  ),
                                  title: Text(
                                    row.name.isNotEmpty ? row.name : 'Pengemudi Transporter',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            row.vehiclePlate.isNotEmpty
                                                ? row.vehiclePlate
                                                : row.company,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ekspedisi: ${row.company.isNotEmpty ? row.company : "-"} • Masuk: ${_formatTime(row.checkinAt)}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () {
                                      if (widget.onSelectCheckout != null) {
                                        widget.onSelectCheckout!(row);
                                      }
                                    },
                                    icon: const Icon(Icons.logout, size: 16),
                                    label: const Text('Proses Keluar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                                      foregroundColor: Colors.amber,
                                      elevation: 0,
                                      side: BorderSide(
                                        color: Colors.amber.withValues(alpha: 0.3),
                                      ),
                                    ),
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
