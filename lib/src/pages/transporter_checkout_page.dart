import 'dart:convert';
import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import '../widgets/signature_pad.dart';

class TransporterCheckoutPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;
  final ActiveGuestRow? initialSelection;
  final VoidCallback onDone;

  const TransporterCheckoutPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
    this.initialSelection,
    required this.onDone,
  });

  @override
  State<TransporterCheckoutPage> createState() => _TransporterCheckoutPageState();
}

class _TransporterCheckoutPageState extends State<TransporterCheckoutPage> {
  final _padKey = GlobalKey<SignaturePadState>();
  List<ActiveGuestRow> _activeTransporters = [];
  ActiveGuestRow? _selected;
  final _notes = TextEditingController();
  bool _loading = false;
  bool _busy = false;
  bool _hasSignature = false;
  String? _error;
  String? _success;

  bool _checkDocs = true;
  bool _checkLoad = true;
  bool _checkSeal = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
    _loadActive();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadActive() async {
    setState(() => _loading = true);
    try {
      final list = await widget.client.fetchActiveTransporters(
        branchId: widget.session.branchId ?? widget.config.branchId,
      );
      if (mounted) {
        setState(() {
          _activeTransporters = list;
          if (_selected != null) {
            _selected = list.firstWhere(
              (e) => e.planId == _selected!.planId,
              orElse: () => _selected!,
            );
          } else if (list.isNotEmpty) {
            _selected = list.first;
          }
        });
      }
    } catch (_) {
      // transient
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

  Future<void> _submitCheckout() async {
    if (_selected == null) {
      setState(() => _error = 'Pilih armada transporter yang akan check-out.');
      return;
    }

    if (!_hasSignature) {
      setState(() => _error = 'Tanda tangan petugas satpam gerbang wajib dibubuhkan.');
      return;
    }

    final pngBytes = await _padKey.currentState?.toPng();
    if (pngBytes == null) {
      setState(() => _error = 'Tanda tangan tidak valid atau kosong.');
      return;
    }
    final signatureB64 = base64Encode(pngBytes);

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    try {
      final payload = {
        'plan_id': _selected!.planId,
        'visitor_id': _selected!.visitorId,
        'officer_name': widget.session.email,
        'officer_signature_b64': signatureB64,
        'notes': _notes.text.trim(),
        'verification': {
          'docs_checked': _checkDocs,
          'load_checked': _checkLoad,
          'seal_checked': _checkSeal,
        },
      };

      final res = await widget.client.confirmCheckout(payload);
      if (res['success'] == false) {
        throw Exception(res['message'] ?? 'Gagal memproses check-out transporter.');
      }

      setState(() {
        _success = 'Konfirmasi keluar untuk ${_selected!.name} berhasil!';
        _selected = null;
        _hasSignature = false;
        _notes.clear();
      });
      _padKey.currentState?.clear();

      _loadActive();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onDone();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                child: const Icon(Icons.logout, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfirmasi Keluar Transporter (Check-out Gerbang)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pemeriksaan akhir barang keluar, segel kendaraan, dan stempel keluar gerbang',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                ],
              ),
            ),
          if (_success != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_success!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
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
                          const Text(
                            '1. Pilih Kendaraan / Transporter di Area',
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            onPressed: _loading ? null : _loadActive,
                            icon: const Icon(Icons.refresh, size: 18, color: Colors.white60),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_activeTransporters.isEmpty && !_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Tidak ada armada yang sedang berada di area.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<ActiveGuestRow>(
                          initialValue: _selected,
                          dropdownColor: const Color(0xFF0F1A2E),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Pilih Armada Transporter *',
                            labelStyle: const TextStyle(color: Colors.white60),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _activeTransporters.map((row) {
                            return DropdownMenuItem<ActiveGuestRow>(
                              value: row,
                              child: Text(
                                '${row.name} (${row.vehiclePlate.isNotEmpty ? row.vehiclePlate : row.company}) • Masuk: ${_formatTime(row.checkinAt)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selected = val),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        '2. Checklist Pemeriksaan Akhir Gerbang',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _checkDocs,
                        onChanged: (val) => setState(() => _checkDocs = val ?? true),
                        title: const Text(
                          'Surat Jalan / Bukti Timbang / DO telah distempel & lengkap',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.amber,
                      ),
                      CheckboxListTile(
                        value: _checkLoad,
                        onChanged: (val) => setState(() => _checkLoad = val ?? true),
                        title: const Text(
                          'Pemeriksaan muatan bak/kontainer telah sesuai fisik & tidak ada barang liar',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.amber,
                      ),
                      CheckboxListTile(
                        value: _checkSeal,
                        onChanged: (val) => setState(() => _checkSeal = val ?? true),
                        title: const Text(
                          'Segel pengaman terpasang dengan nomor segel yang sesuai',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3. Pengesahan Satpam Gerbang Keluar',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Petugas: ${widget.session.email}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tanda Tangan Digital:',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                          TextButton(
                            onPressed: () {
                              _padKey.currentState?.clear();
                              setState(() => _hasSignature = false);
                            },
                            child: const Text('Hapus / Ulangi', style: TextStyle(color: Colors.amber, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SignaturePad(
                          key: _padKey,
                          onChanged: (hasMarks) => setState(() => _hasSignature = hasMarks),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _notes,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Catatan Keluar (Opsional)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _busy || _selected == null ? null : _submitCheckout,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            _busy ? 'Memproses...' : 'Konfirmasi Armada Keluar',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            ],
          ),
        ],
      ),
    );
  }
}
