import 'dart:convert';
import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
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
  final _vehicleType = TextEditingController(text: 'Tronton Wingbox');
  final _company = TextEditingController();
  final _doNumber = TextEditingController();
  final _loadDescription = TextEditingController();
  final _notes = TextEditingController();

  PlantAreaCategory _selectedArea = PlantAreaCategory.garudafood;
  List<PlantArea> _areas = [];
  int? _selectedAreaId;

  String _activityType = 'bongkar'; // 'bongkar' | 'muat'
  String _commodityCategory = 'Bahan Baku';
  bool _hasSignature = false;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final list = await widget.client.fetchAreas(
        branchId: widget.session.branchId ?? widget.config.branchId,
      );
      if (mounted && list.isNotEmpty) {
        setState(() {
          _areas = list;
          final matched = list.firstWhere(
            (a) => a.category == _selectedArea,
            orElse: () => list.first,
          );
          _selectedArea = matched.category;
          _selectedAreaId = matched.id;
        });
      }
    } catch (_) {
      // transient network error, keep default
    }
  }

  void _onAreaSelected(PlantAreaCategory cat) {
    setState(() {
      _selectedArea = cat;
      final matched = _areas.where((a) => a.category == cat).firstOrNull;
      _selectedAreaId = matched?.id;
    });
  }

  @override
  void dispose() {
    _driverName.dispose();
    _plateNumber.dispose();
    _vehicleType.dispose();
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
      setState(() => _error =
          'Nama Sopir, Plat Nomor, dan Perusahaan Transporter wajib diisi.');
      return;
    }

    if (!_hasSignature) {
      setState(() =>
          _error = 'Tanda tangan digital satpam pemeriksa wajib dibubuhkan.');
      return;
    }

    final pngBytes = await _padKey.currentState?.toPng();
    if (pngBytes == null) {
      setState(() => _error = 'Tanda tangan tidak valid atau kosong.');
      return;
    }

    if (_activityType == 'bongkar' && _loadDescription.text.trim().isEmpty && _doNumber.text.trim().isEmpty) {
      setState(() => _error =
          'Untuk alur bongkar, nomor surat jalan (DO) atau rincian muatan wajib diisi sebelum konfirmasi masuk.');
      return;
    }

    final signatureB64 = base64Encode(pngBytes);

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    try {
      final rawDesc = _loadDescription.text.trim();
      final fullDesc = [
        if (_commodityCategory.isNotEmpty) '[]',
        if (rawDesc.isNotEmpty) rawDesc,
      ].join(' ');

      final payload = {
        'driver_name': driver,
        'plate_number': plate,
        'vehicle_type': _vehicleType.text.trim(),
        'transporter_company': company,
        'do_number': _doNumber.text.trim(),
        'load_type': _activityType,
        'load_description': fullDesc,
        'notes': _notes.text.trim(),
        'officer_name': widget.session.email,
        'officer_signature_b64': signatureB64,
        'branch_id': widget.session.branchId ?? widget.config.branchId,
        'area_id': _selectedAreaId,
        'area_code': _selectedArea.code,
        'area_name': _selectedArea == PlantAreaCategory.garudafood
            ? 'Garudafood'
            : _selectedArea == PlantAreaCategory.dc
                ? 'DC'
                : 'MBR',
      };

      final res = await widget.client.confirmCheckin(payload);
      if (res['success'] == false) {
        throw Exception(
            res['message'] ?? 'Gagal menyimpan check-in transporter.');
      }

      setState(() {
        _success =
            'Konfirmasi masuk transporter $plate di area ${_selectedArea.label} berhasil dicatat!';
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
              // Kolom kiri: Data Kendaraan, Pengemudi & Muatan
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Identitas Kendaraan & Pengemudi
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
                              'Identitas Kendaraan & Pengemudi',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Area Tujuan Pabrik Selector
                        const Text(
                          'Pilih Area Tujuan Pabrik (Sumedang) *',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAreaSelectorCard(
                                category: PlantAreaCategory.garudafood,
                                title: 'Garudafood (GF)',
                                subtitle: 'Plant Produksi Utama',
                                isSelected: _selectedArea ==
                                    PlantAreaCategory.garudafood,
                                onTap: () => _onAreaSelected(
                                    PlantAreaCategory.garudafood),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildAreaSelectorCard(
                                category: PlantAreaCategory.dc,
                                title: 'Distribution Center (DC)',
                                subtitle: 'Gudang Logistik & DC',
                                isSelected:
                                    _selectedArea == PlantAreaCategory.dc,
                                onTap: () =>
                                    _onAreaSelected(PlantAreaCategory.dc),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildAreaSelectorCard(
                                category: PlantAreaCategory.mbr,
                                title: 'Area MBR',
                                subtitle: 'Logistik MBR',
                                isSelected:
                                    _selectedArea == PlantAreaCategory.mbr,
                                onTap: () =>
                                    _onAreaSelected(PlantAreaCategory.mbr),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: InputField(
                                label: 'Nomor Polisi / Plat Kendaraan *',
                                controller: _plateNumber,
                                hintText: 'Contoh: B 9123 GF',
                                prefixIcon: Icons.pin_rounded,
                                onChanged: (v) {
                                  final up = v.toUpperCase();
                                  if (up != v) {
                                    _plateNumber.value = _plateNumber.value.copyWith(
                                      text: up,
                                      selection: TextSelection.collapsed(
                                          offset: up.length),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: DropdownField(
                                label: 'Jenis Truk / Armada *',
                                value: _vehicleType.text.isNotEmpty ? _vehicleType.text : 'Tronton Wingbox',
                                items: const [
                                  'Tronton Wingbox',
                                  'Fuso Box / Bak',
                                  'CDD Double',
                                  'CDE Engkel',
                                  'Trailer / Kontainer',
                                  'Blind Van / Pickup',
                                  'Lainnya',
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _vehicleType.text = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Nama Sopir / Driver *',
                          controller: _driverName,
                          hintText: 'Nama lengkap sopir sesuai KTP / SIM',
                          prefixIcon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Perusahaan Ekspedisi / Transporter *',
                          controller: _company,
                          hintText: 'Contoh: PT Sumber Logistik Sentosa',
                          prefixIcon: Icons.business_rounded,
                        ),
                        const SizedBox(height: 28),

                        // Section 2: Data Muatan & Surat Jalan
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
                              'Aktivitas Armada & Data Muatan',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Selector Aktivitas: Bongkar vs Muat
                        const Text(
                          'Jenis Aktivitas Logistik *',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _activityType = 'bongkar'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _activityType == 'bongkar'
                                        ? const Color(0xFF1E88E5).withValues(alpha: 0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _activityType == 'bongkar'
                                          ? const Color(0xFF1E88E5)
                                          : borderColor,
                                      width: _activityType == 'bongkar' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.download_rounded,
                                          color: Color(0xFF1E88E5),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bongkar Muatan',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Bawa bahan baku / logistik masuk',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _activityType = 'muat'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _activityType == 'muat'
                                        ? const Color(0xFFF57C00).withValues(alpha: 0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _activityType == 'muat'
                                          ? const Color(0xFFF57C00)
                                          : borderColor,
                                      width: _activityType == 'muat' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF57C00).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.upload_rounded,
                                          color: Color(0xFFF57C00),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Muat Barang',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Ambil produk jadi (Finished Goods)',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
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
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownField(
                                label: 'Kategori Komoditas Barang',
                                value: _commodityCategory,
                                items: const [
                                  'Bahan Baku',
                                  'Bahan Kemas',
                                  'Produk Jadi (Finished Goods)',
                                  'Sparepart / Mesin',
                                  'Lainnya',
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _commodityCategory = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InputField(
                                label: 'Nomor Surat Jalan / DO',
                                controller: _doNumber,
                                hintText: 'Contoh: SJ-2026/06/1029',
                                prefixIcon: Icons.description_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Rincian Muatan (Tonase / Koli / Keterangan)',
                          controller: _loadDescription,
                          maxLines: 2,
                          hintText: _activityType == 'bongkar'
                              ? 'Contoh: 8 Pallet Kacang Garuda, total 4.2 Ton'
                              : 'Contoh: Bak kosong siap muat 12 Pallet Biskuit Gery',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Kolom kanan: Tanda Tangan Satpam & Konfirmasi
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
                              'Pengesahan Petugas Satpam',
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedArea.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedArea.color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedArea.icon,
                                size: 14,
                                color: _selectedArea.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Area Masuk: ${_selectedArea.label}',
                                style: TextStyle(
                                  color: _selectedArea.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tanda Tangan Digital Pemeriksa:',
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
                          label: 'Catatan Khusus Gerbang (Opsional)',
                          controller: _notes,
                          maxLines: 2,
                          hintText:
                              'Misal: Kondisi terpal aman, supir membawa masker',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _submit,
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
                                  ? 'Menyimpan...'
                                  : 'Simpan Konfirmasi Masuk',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: brandBlue,
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

  Widget _buildAreaSelectorCard({
    required PlantAreaCategory category,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? category.color.withValues(alpha: 0.08)
                : panelColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? category.color : borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(category.icon, size: 16, color: category.color),
                  const SizedBox(width: 6),
                  Text(
                    category.code,
                    style: TextStyle(
                      color: category.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: category.color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
