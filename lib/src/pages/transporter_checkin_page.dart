import 'dart:convert';
import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../widgets/signature_pad.dart';

class TransporterCheckinPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;
  final VoidCallback onDone;

  const TransporterCheckinPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
    required this.onDone,
  });

  @override
  State<TransporterCheckinPage> createState() => _TransporterCheckinPageState();
}

class _TransporterCheckinPageState extends State<TransporterCheckinPage> {
  final _padKey = GlobalKey<SignaturePadState>();
  final _driverName = TextEditingController();
  final _plateNumber = TextEditingController();
  final _company = TextEditingController();
  final _doNumber = TextEditingController();
  final _loadDescription = TextEditingController();
  final _notes = TextEditingController();

  String _loadType = 'Bahan Baku';
  bool _hasSignature = false;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _driverName.dispose();
    _plateNumber.dispose();
    _company.dispose();
    _doNumber.dispose();
    _loadDescription.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final driver = _driverName.text.trim();
    final plate = _plateNumber.text.trim().toUpperCase();
    final company = _company.text.trim();

    if (driver.isEmpty || plate.isEmpty || company.isEmpty) {
      setState(() => _error = 'Nama Sopir, Plat Nomor, dan Perusahaan Transporter wajib diisi.');
      return;
    }

    if (!_hasSignature) {
      setState(() => _error = 'Tanda tangan digital satpam pemeriksa wajib dibubuhkan.');
      return;
    }

    final pngBytes = await _padKey.currentState?.toPng();
    if (pngBytes == null) {
      setState(() => _error = 'Tanda tangan tidak valid atau kosong.');
      return;
    }

    if (_loadType == 'bongkar' && _loadDescription.text.trim().isEmpty) {
      setState(() => _error = 'Untuk alur bongkar, rincian barang muatan wajib diisi sebelum konfirmasi masuk.');
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
        'driver_name': driver,
        'plate_number': plate,
        'transporter_company': company,
        'do_number': _doNumber.text.trim(),
        'load_type': _loadType,
        'load_description': _loadDescription.text.trim(),
        'notes': _notes.text.trim(),
        'officer_name': widget.session.email,
        'officer_signature_b64': signatureB64,
        'branch_id': widget.session.branchId ?? widget.config.branchId,
      };

      final res = await widget.client.confirmCheckin(payload);
      if (res['success'] == false) {
        throw Exception(res['message'] ?? 'Gagal menyimpan check-in transporter.');
      }

      setState(() {
        _success = 'Konfirmasi masuk transporter $plate berhasil dicatat!';
        _driverName.clear();
        _plateNumber.clear();
        _company.clear();
        _doNumber.clear();
        _loadDescription.clear();
        _notes.clear();
        _hasSignature = false;
      });
      _padKey.currentState?.clear();

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
                child: const Icon(Icons.login, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfirmasi Masuk Transporter (Check-in Gerbang)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pencatatan kedatangan armada, kelengkapan surat jalan, dan pengesahan satpam',
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
                      const Text(
                        '1. Identitas Kendaraan & Pengemudi',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _plateNumber,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Nomor Polisi / Plat Kendaraan *',
                          labelStyle: const TextStyle(color: Colors.white60),
                          hintText: 'Contoh: B 9123 GF',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _driverName,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Nama Sopir / Driver *',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _company,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Perusahaan Ekspedisi / Transporter *',
                          labelStyle: const TextStyle(color: Colors.white60),
                          hintText: 'Contoh: PT Sumber Logistik Sentosa',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '2. Data Muatan & Surat Jalan',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _loadType,
                              dropdownColor: const Color(0xFF0F1A2E),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Kategori Muatan',
                                labelStyle: const TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Bahan Baku', child: Text('Bahan Baku')),
                                DropdownMenuItem(value: 'Bahan Kemas', child: Text('Bahan Kemas')),
                                DropdownMenuItem(value: 'Produk Jadi (Finished Goods)', child: Text('Produk Jadi')),
                                DropdownMenuItem(value: 'Sparepart / Mesin', child: Text('Sparepart / Mesin')),
                                DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _loadType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _doNumber,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Nomor Surat Jalan / DO',
                                labelStyle: const TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _loadDescription,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Rincian Muatan (Tonase / Koli / Barang)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
                        '3. Pengesahan Petugas Satpam',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Petugas Pemeriksa: ${widget.session.email}',
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
                          labelText: 'Catatan Khusus Gerbang (Opsional)',
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
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            _busy ? 'Menyimpan...' : 'Simpan Konfirmasi Masuk',
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
