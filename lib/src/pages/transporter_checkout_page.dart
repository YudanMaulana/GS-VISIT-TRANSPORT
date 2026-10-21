import 'dart:convert';
import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
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
  State<TransporterCheckoutPage> createState() =>
      _TransporterCheckoutPageState();
}

class _TransporterCheckoutPageState extends State<TransporterCheckoutPage> {
  final _padKey = GlobalKey<SignaturePadState>();
  List<ActiveGuestRow> _activeTransporters = [];
  ActiveGuestRow? _selected;
  PlantAreaCategory _selectedAreaFilter = PlantAreaCategory.all;
  final _notes = TextEditingController();
  bool _loading = false;
  bool _busy = false;
  bool _hasSignature = false;
  String? _error;
  String? _success;

  bool _checkDocs = true;
  bool _checkLoad = true;
  bool _checkSeal = true;

  List<ActiveGuestRow> get _filteredActive {
    if (_selectedAreaFilter == PlantAreaCategory.all) return _activeTransporters;
    return _activeTransporters
        .where((r) => r.areaCategory == _selectedAreaFilter)
        .toList();
  }

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
      setState(() =>
          _error = 'Tanda tangan petugas satpam gerbang wajib dibubuhkan.');
      return;
    }

    if (_selected!.loadCount == 0) {
      setState(() => _error =
          'Data barang muatan armada ini belum tercatat. Lengkapi catatan muatan sebelum konfirmasi keluar.');
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
        throw Exception(
            res['message'] ?? 'Gagal memproses check-out transporter.');
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
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFC0C0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFD64045),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFD64045),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_success != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBE8DC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _success!,
                      style: const TextStyle(
                        color: successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom kiri: Pemilihan armada & Checklist pemeriksaan
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: brandBlueSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        color: brandBlue,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Pilih Kendaraan / Transporter di Area',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: _loading ? null : _loadActive,
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              tooltip: 'Refresh daftar armada aktif',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_activeTransporters.isEmpty && !_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: EmptyStateCard(
                              title: 'Tidak Ada Armada di Area',
                              description:
                                  'Semua armada transporter telah keluar atau belum ada yang check-in.',
                              icon: Icons.local_shipping_outlined,
                            ),
                          )
                        else ...[
                          // Filter Area Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildAreaFilterChip(
                                PlantAreaCategory.all,
                                'Semua (${_activeTransporters.length})',
                              ),
                              _buildAreaFilterChip(
                                PlantAreaCategory.garudafood,
                                'GF (${_activeTransporters.where((r) => r.areaCategory == PlantAreaCategory.garudafood).length})',
                              ),
                              _buildAreaFilterChip(
                                PlantAreaCategory.dc,
                                'DC (${_activeTransporters.where((r) => r.areaCategory == PlantAreaCategory.dc).length})',
                              ),
                              _buildAreaFilterChip(
                                PlantAreaCategory.mbr,
                                'MBR (${_activeTransporters.where((r) => r.areaCategory == PlantAreaCategory.mbr).length})',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<ActiveGuestRow>(
                            key: ValueKey(_selectedAreaFilter),
                            initialValue: _filteredActive.contains(_selected)
                                ? _selected
                                : _filteredActive.firstOrNull,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Pilih Armada Transporter *',
                              labelStyle: const TextStyle(
                                color: textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                              prefixIcon: const Icon(
                                Icons.local_shipping_rounded,
                                color: brandBlue,
                              ),
                            ),
                            items: _filteredActive.map((row) {
                              final cat = row.areaCategory;
                              return DropdownMenuItem<ActiveGuestRow>(
                                value: row,
                                child: Text(
                                  '[${cat.code}] ${row.name} (${row.vehiclePlate.isNotEmpty ? row.vehiclePlate : row.company}) • Antrean #${row.queueNumber ?? row.planId}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selected = val),
                          ),
                          if (_selected != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: panelColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DetailLine(
                                          label: 'NAMA PENGEMUDI',
                                          value: _selected!.name,
                                        ),
                                      ),
                                      Expanded(
                                        child: DetailLine(
                                          label: 'NOMOR POLISI',
                                          value: _selected!.vehiclePlate,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DetailLine(
                                          label: 'AREA PABRIK',
                                          value:
                                              '${_selected!.areaCategory.label} (${_selected!.areaCategory.code})',
                                        ),
                                      ),
                                      Expanded(
                                        child: DetailLine(
                                          label: 'NOMOR ANTREAN',
                                          value:
                                              '#${_selected!.queueNumber ?? _selected!.planId} (${_selected!.areaCategory.code})',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DetailLine(
                                          label: 'PERUSAHAAN EKSPEDISI',
                                          value: _selected!.company,
                                        ),
                                      ),
                                      Expanded(
                                        child: DetailLine(
                                          label: 'WAKTU MASUK',
                                          value:
                                              _formatTime(_selected!.checkinAt),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: brandBlueSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                    color: brandBlue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Checklist Pemeriksaan Akhir Gerbang',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: _checkDocs,
                                onChanged: (val) =>
                                    setState(() => _checkDocs = val ?? true),
                                title: const Text(
                                  'Surat Jalan / Bukti Timbang / DO telah distempel & lengkap',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: brandBlue,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                ),
                              ),
                              const Divider(height: 1, color: borderColor),
                              CheckboxListTile(
                                value: _checkLoad,
                                onChanged: (val) =>
                                    setState(() => _checkLoad = val ?? true),
                                title: const Text(
                                  'Pemeriksaan muatan bak/kontainer telah sesuai fisik & tidak ada barang liar',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: brandBlue,
                              ),
                              const Divider(height: 1, color: borderColor),
                              CheckboxListTile(
                                value: _checkSeal,
                                onChanged: (val) =>
                                    setState(() => _checkSeal = val ?? true),
                                title: const Text(
                                  'Segel pengaman terpasang dengan nomor segel yang sesuai',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: brandBlue,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Kolom kanan: Tanda tangan & Submit
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: brandBlueSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '3',
                                  style: TextStyle(
                                    color: brandBlue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Pengesahan Satpam Gerbang Keluar',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Petugas: ${widget.session.email}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tanda Tangan Digital Petugas:',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _padKey.currentState?.clear();
                                setState(() => _hasSignature = false);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Hapus / Ulangi',
                                style: TextStyle(
                                  color: brandBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SignaturePad(
                            key: _padKey,
                            onChanged: (hasMarks) =>
                                setState(() => _hasSignature = hasMarks),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Catatan Keluar (Opsional)',
                          controller: _notes,
                          maxLines: 2,
                          hintText: 'Misal: Dokumen timbang lengkap, segel utuh',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy || _selected == null
                                ? null
                                : _submitCheckout,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_rounded,
                                    size: 20),
                            label: Text(
                              _busy
                                  ? 'Memproses...'
                                  : 'Konfirmasi Armada Keluar',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: brandCoral,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaFilterChip(PlantAreaCategory cat, String label) {
    final isSelected = _selectedAreaFilter == cat;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedAreaFilter = cat;
        if (!_filteredActive.contains(_selected)) {
          _selected = _filteredActive.firstOrNull;
        }
      }),
      label: Text(label),
      selectedColor: cat.color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: panelColor,
      side: BorderSide(
        color: isSelected ? cat.color : borderColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

