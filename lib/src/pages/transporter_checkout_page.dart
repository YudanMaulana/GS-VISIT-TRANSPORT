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

  Future<void> _openManageLoadsModal(ActiveGuestRow target) async {
    final goodsCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final doCtrl = TextEditingController(text: target.firstShipmentNo);
    final containerCtrl = TextEditingController();
    final sealCtrl = TextEditingController();
    bool loadingLoads = true;
    bool savingLoad = false;
    List<Map<String, dynamic>> loads = [];
    String? modalError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void fetchCurrentLoads() async {
            try {
              final res = await widget.client.fetchLoads(target.planId);
              if (ctx.mounted) {
                setModalState(() {
                  loads = res;
                  loadingLoads = false;
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                setModalState(() {
                  modalError = 'Gagal mengambil muatan: $e';
                  loadingLoads = false;
                });
              }
            }
          }

          if (loadingLoads) {
            fetchCurrentLoads();
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: brandBlueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: brandBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Rincian Muatan - ${target.vehiclePlate}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                      ),
                      Text(
                        'Antrean #${target.queueNumber ?? target.planId} • ${target.name}',
                        style: const TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (modalError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(modalError!, style: const TextStyle(color: Color(0xFFD64045), fontSize: 12)),
                      ),

                    // Daftar muatan saat ini
                    const Text(
                      'Daftar Barang Tercatat:',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    if (loadingLoads)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (loads.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Text(
                          'Belum ada rincian barang muatan untuk rencana ini. Silakan input di bawah.',
                          style: TextStyle(fontSize: 12, color: textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < loads.length; i++)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  border: i > 0 ? const Border(top: BorderSide(color: borderColor)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loads[i]['goods_name']?.toString() ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                          ),
                                          Text(
                                            'Jumlah: ${loads[i]["quantity"] ?? "-"} • SJ/DO: ${loads[i]["shipment_no"] ?? "-"}',
                                            style: const TextStyle(fontSize: 11, color: textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (loads[i]['container_no'] != null && loads[i]['container_no'].toString().isNotEmpty)
                                      StatusPill(text: 'Kontainer: ${loads[i]["container_no"]}', color: brandBlue),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Form Tambah Baris Muatan Baru
                    const Text(
                      'Tambah Baris Muatan Baru:',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InputField(
                            label: 'Nama Barang *',
                            controller: goodsCtrl,
                            hintText: 'Contoh: Kacang Garuda Roster 100g',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: InputField(
                            label: 'Jumlah / Satuan *',
                            controller: qtyCtrl,
                            hintText: 'Contoh: 120 Karton / 3.5 Ton',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: 'Nomor Surat Jalan / DO',
                            controller: doCtrl,
                            hintText: 'Contoh: SJ-2026/06/1029',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputField(
                            label: 'Nomor Segel (Seal No)',
                            controller: sealCtrl,
                            hintText: 'Contoh: SEAL-88912',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: savingLoad
                            ? null
                            : () async {
                                final gName = goodsCtrl.text.trim();
                                if (gName.isEmpty) {
                                  setModalState(() => modalError = 'Nama barang wajib diisi.');
                                  return;
                                }
                                setModalState(() {
                                  savingLoad = true;
                                  modalError = null;
                                });
                                try {
                                  final res = await widget.client.addLoad(target.planId, {
                                    'goods_name': gName,
                                    'quantity': qtyCtrl.text.trim(),
                                    'shipment_no': doCtrl.text.trim(),
                                    'seal_no': sealCtrl.text.trim(),
                                    'container_no': containerCtrl.text.trim(),
                                  });
                                  if (res['success'] == false) {
                                    throw Exception(res['message'] ?? 'Gagal menambah muatan.');
                                  }
                                  goodsCtrl.clear();
                                  qtyCtrl.clear();
                                  sealCtrl.clear();
                                  setModalState(() {
                                    savingLoad = false;
                                    loadingLoads = true;
                                  });
                                  fetchCurrentLoads();
                                  _loadActive();
                                } catch (err) {
                                  setModalState(() {
                                    modalError = err.toString().replaceFirst('Exception: ', '');
                                    savingLoad = false;
                                  });
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: brandBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: savingLoad
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Simpan Baris Muatan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
    _loadActive();
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
      final proceedWithoutLoads = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
              SizedBox(width: 10),
              Text('Muatan Belum Tercatat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: Text(
            'Armada ${_selected!.vehiclePlate} belum memiliki rincian barang muatan terpisah di sistem.\n\n'
            'Apakah Anda ingin mencatat rincian barang sekarang, atau melanjutkan check-out dengan armada kosong / dokumen fisik terlampir?',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(ctx).pop(false);
                _openManageLoadsModal(_selected!);
              },
              child: const Text('Input Muatan Dulu'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: brandBlue),
              child: const Text('Lanjutkan Keluar'),
            ),
          ],
        ),
      );

      if (proceedWithoutLoads != true) {
        return;
      }
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
                                      if (widget.client.resolvePhotoUrl(_selected!.photoUrl).isNotEmpty) ...[
                                        Container(
                                          width: 44,
                                          height: 44,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: brandBlue, width: 2),
                                          ),
                                          child: ClipOval(
                                            child: Image.network(
                                              widget.client.resolvePhotoUrl(_selected!.photoUrl),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: brandBlue),
                                            ),
                                          ),
                                        ),
                                      ],
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
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _selected!.loadCount > 0
                                          ? successColor.withValues(alpha: 0.08)
                                          : brandYellow.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selected!.loadCount > 0
                                            ? successColor.withValues(alpha: 0.3)
                                            : brandYellow.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _selected!.loadCount > 0
                                                  ? Icons.inventory_2_rounded
                                                  : Icons.warning_amber_rounded,
                                              size: 18,
                                              color: _selected!.loadCount > 0 ? successColor : warningColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selected!.loadCount > 0
                                                  ? '${_selected!.loadCount} Baris Muatan Tercatat'
                                                  : 'Belum Ada Rincian Muatan Terpisah',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: _selected!.loadCount > 0 ? successColor : warningColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => _openManageLoadsModal(_selected!),
                                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                                          label: Text(
                                            _selected!.loadCount > 0 ? 'Lihat / Tambah' : '+ Input Muatan',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
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

