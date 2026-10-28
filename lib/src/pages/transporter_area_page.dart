import 'package:flutter/material.dart';

import '../admin_auth.dart';

import '../api_client.dart';

import '../config.dart';

import '../models.dart';

import '../theme.dart';

import '../widgets/common_widgets.dart';

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

  PlantAreaCategory _selectedArea = PlantAreaCategory.all;

  bool _onlyActiveInArea = true;

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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = _monthShort(local.month);
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d $m $y, $h:$min';
  }

  String _monthShort(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  List<ActiveGuestRow> get _filtered {
    final q = _search.text.trim().toLowerCase();

    return _transporters.where((row) {
      if (!row.isTransporter &&
          row.loadType.isEmpty &&
          row.vehiclePlate.isEmpty) {
        return false;
      }

      if (_onlyActiveInArea) {
        if (row.checkoutAt != null || row.status == 'checked_out') {
          return false;
        }
      }

      if (_selectedArea != PlantAreaCategory.all &&
          row.areaCategory != _selectedArea) {
        return false;
      }

      if (q.isEmpty) return true;

      return row.name.toLowerCase().contains(q) ||
          row.company.toLowerCase().contains(q) ||
          row.vehiclePlate.toLowerCase().contains(q) ||
          row.areaName.toLowerCase().contains(q) ||
          row.firstShipmentNo.toLowerCase().contains(q) ||
          row.firstGoodsName.toLowerCase().contains(q) ||
          row.purpose.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pool = _onlyActiveInArea
        ? _transporters
            .where((r) => r.checkoutAt == null && r.status != 'checked_out')
            .toList()
        : _transporters;

    final totalCount = pool.length;

    final gfCount = pool
        .where((r) => r.areaCategory == PlantAreaCategory.garudafood)
        .length;

    final dcCount = pool
        .where((r) => r.areaCategory == PlantAreaCategory.dc)
        .length;

    final mbrCount = pool
        .where((r) => r.areaCategory == PlantAreaCategory.mbr)
        .length;

    final list = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // 4 Area Summary Cards Row
        Row(
          children: [
            Expanded(
              child: _buildAreaTabCard(
                category: PlantAreaCategory.all,

                count: totalCount,

                subtitle: 'Semua armada aktif',

                isSelected: _selectedArea == PlantAreaCategory.all,

                onTap: () =>
                    setState(() => _selectedArea = PlantAreaCategory.all),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildAreaTabCard(
                category: PlantAreaCategory.garudafood,

                count: gfCount,

                subtitle: 'Plant Sumedang',

                isSelected: _selectedArea == PlantAreaCategory.garudafood,

                onTap: () => setState(
                  () => _selectedArea = PlantAreaCategory.garudafood,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildAreaTabCard(
                category: PlantAreaCategory.dc,

                count: dcCount,

                subtitle: 'Distribution Center',

                isSelected: _selectedArea == PlantAreaCategory.dc,

                onTap: () =>
                    setState(() => _selectedArea = PlantAreaCategory.dc),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildAreaTabCard(
                category: PlantAreaCategory.mbr,

                count: mbrCount,

                subtitle: 'Area logistik MBR',

                isSelected: _selectedArea == PlantAreaCategory.mbr,

                onTap: () =>
                    setState(() => _selectedArea = PlantAreaCategory.mbr),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Filter & Search Toolbar
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,

                    onChanged: (_) => setState(() {}),

                    style: const TextStyle(
                      color: textPrimary,

                      fontSize: 14,

                      fontWeight: FontWeight.w600,
                    ),

                    decoration: InputDecoration(
                      hintText:
                          'Cari sopir, nopol, surat jalan, atau ekspedisi...',

                      hintStyle: const TextStyle(
                        color: textMuted,

                        fontSize: 13,

                        fontWeight: FontWeight.normal,
                      ),

                      prefixIcon: const Icon(
                        Icons.search_rounded,

                        color: textMuted,

                        size: 20,
                      ),

                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),

                              onPressed: () => setState(() => _search.clear()),
                            )
                          : null,

                      filled: true,

                      fillColor: panelColor,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,

                        vertical: 12,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),

                        borderSide: const BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Area Chips Filter
                Wrap(
                  spacing: 8,

                  children: [
                    _buildChip(PlantAreaCategory.all, 'Semua ($totalCount)'),

                    _buildChip(PlantAreaCategory.garudafood, 'GF ($gfCount)'),

                    _buildChip(PlantAreaCategory.dc, 'DC ($dcCount)'),

                    _buildChip(PlantAreaCategory.mbr, 'MBR ($mbrCount)'),
                  ],
                ),

                const SizedBox(width: 14),

                FilterChip(
                  label: Text(
                    _onlyActiveInArea ? 'Di Area Saja' : 'Semua (Termasuk Keluar)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _onlyActiveInArea ? brandBlue : textMuted,
                    ),
                  ),
                  avatar: Icon(
                    _onlyActiveInArea ? Icons.local_shipping_rounded : Icons.history_rounded,
                    size: 16,
                    color: _onlyActiveInArea ? brandBlue : textMuted,
                  ),
                  selected: _onlyActiveInArea,
                  onSelected: (val) => setState(() => _onlyActiveInArea = val),
                  backgroundColor: panelColor,
                  selectedColor: brandBlue.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: _onlyActiveInArea ? brandBlue : borderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                const SizedBox(width: 14),

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

        const SizedBox(height: 14),

        // Main content card
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
                : list.isEmpty
                ? EmptyStateCard(
                    title: _selectedArea == PlantAreaCategory.all
                        ? 'Tidak Ada Armada Transporter'
                        : 'Tidak Ada Armada di ${_selectedArea.label}',

                    description: _selectedArea == PlantAreaCategory.all
                        ? 'Tidak ada armada transporter yang cocok dengan kata kunci pencarian atau sedang berada di area pabrik.'
                        : 'Tidak ada armada transporter yang tercatat di area ${_selectedArea.label}.',

                    icon: _selectedArea.icon,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),

                    itemCount: list.length,

                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),

                    itemBuilder: (context, index) {
                      final row = list[index];

                      final isBongkar = row.loadType == 'bongkar';

                      final typeColor = isBongkar ? brandBlue : brandCoral;

                      final areaCat = row.areaCategory;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,

                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          color: panelColor,

                          borderRadius: BorderRadius.circular(20),

                          border: Border.all(color: borderColor),

                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),

                              blurRadius: 10,

                              offset: Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final fullPhoto = widget.client.resolvePhotoUrl(
                                  row.photoUrl,
                                );
                                if (fullPhoto.isNotEmpty) {
                                  _showPhotoDialog(
                                    context,
                                    fullPhoto,
                                    row.name,
                                  );
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: areaCat.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: areaCat.color.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child:
                                      widget.client
                                          .resolvePhotoUrl(row.photoUrl)
                                          .isNotEmpty
                                      ? Image.network(
                                          widget.client.resolvePhotoUrl(
                                            row.photoUrl,
                                          ),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Icon(
                                            areaCat.icon,
                                            color: areaCat.color,
                                            size: 24,
                                          ),
                                        )
                                      : Icon(
                                          areaCat.icon,
                                          color: areaCat.color,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          row.name.isNotEmpty
                                              ? row.name
                                              : 'Pengemudi Transporter',

                                          style: const TextStyle(
                                            color: textPrimary,

                                            fontSize: 15,

                                            fontWeight: FontWeight.w900,
                                          ),

                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // Badge Area
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,

                                          vertical: 3,
                                        ),

                                        decoration: BoxDecoration(
                                          color: areaCat.color.withValues(
                                            alpha: 0.12,
                                          ),

                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),

                                          border: Border.all(
                                            color: areaCat.color.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),

                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,

                                          children: [
                                            Icon(
                                              areaCat.icon,

                                              size: 13,

                                              color: areaCat.color,
                                            ),

                                            const SizedBox(width: 4),

                                            Text(
                                              areaCat.code,

                                              style: TextStyle(
                                                color: areaCat.color,

                                                fontSize: 11,

                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      StatusPill(
                                        text: row.loadType.isNotEmpty
                                            ? row.loadType.toUpperCase()
                                            : 'TRANSPORTER',

                                        color: typeColor,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Wrap(
                                    spacing: 12,

                                    runSpacing: 6,

                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,

                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,

                                          vertical: 3,
                                        ),

                                        decoration: BoxDecoration(
                                          color: Colors.white,

                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),

                                          border: Border.all(
                                            color: borderColor,
                                          ),
                                        ),

                                        child: Text(
                                          row.vehiclePlate.isNotEmpty
                                              ? row.vehiclePlate
                                              : 'Tanpa Plat',

                                          style: const TextStyle(
                                            color: textPrimary,

                                            fontSize: 12,

                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),

                                      Text(
                                        'Ekspedisi: ${row.company.isNotEmpty ? row.company : "-"}',

                                        style: const TextStyle(
                                          color: textMuted,

                                          fontSize: 12.5,

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      if (row.firstShipmentNo.isNotEmpty)
                                        Text(
                                          'SJ: ${row.firstShipmentNo}',

                                          style: const TextStyle(
                                            color: textMuted,

                                            fontSize: 12.5,

                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                      Text(
                                        '• Masuk: ${_formatDateTime(row.checkinAt)}',

                                        style: const TextStyle(
                                          color: textMuted,

                                          fontSize: 12.5,

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      if (row.checkoutAt != null || row.status == 'checked_out')
                                        Text(
                                          '• Keluar: ${_formatDateTime(row.checkoutAt)}',

                                          style: const TextStyle(
                                            color: Color(0xFFE53935),

                                            fontSize: 12.5,

                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),

                                  if (row.goodsSummary.isNotEmpty) ...[
                                    const SizedBox(height: 8),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),

                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E88E5).withValues(alpha: 0.08),

                                        borderRadius: BorderRadius.circular(10),

                                        border: Border.all(
                                          color: const Color(0xFF1E88E5).withValues(alpha: 0.22),
                                        ),
                                      ),

                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,

                                        children: [
                                          const Icon(
                                            Icons.inventory_2_rounded,
                                            size: 14,
                                            color: Color(0xFF1565C0),
                                          ),

                                          const SizedBox(width: 6),

                                          Flexible(
                                            child: Text(
                                              'Barang: ${row.goodsSummary}',
                                              style: const TextStyle(
                                                color: Color(0xFF0D47A1),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          if (row.loadCount > 1) ...[
                                            const SizedBox(width: 6),

                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),

                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1565C0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),

                                              child: Text(
                                                '+${row.loadCount - 1} muatan',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Card Nomor Antrean
                            Container(
                              constraints: const BoxConstraints(minWidth: 124),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    areaCat.color.withValues(alpha: 0.10),
                                    areaCat.color.withValues(alpha: 0.04),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: areaCat.color.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: areaCat.color.withValues(
                                      alpha: 0.06,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        areaCat.icon,
                                        size: 13,
                                        color: areaCat.color,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ANTREAN ${areaCat.code}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: areaCat.color,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    row.queueNumber != null
                                        ? '#${row.queueNumber}'
                                        : (row.status == 'planned'
                                              ? 'MENUNGGU'
                                              : '#${row.planId}'),
                                    style: TextStyle(
                                      fontSize: row.queueNumber != null
                                          ? 24
                                          : 14,
                                      fontWeight: FontWeight.w900,
                                      color: areaCat.color,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildChip(PlantAreaCategory cat, String label) {
    final isSelected = _selectedArea == cat;

    return ChoiceChip(
      selected: isSelected,

      onSelected: (_) => setState(() => _selectedArea = cat),

      label: Text(label),

      selectedColor: cat.color,

      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textPrimary,

        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,

        fontSize: 12,
      ),

      backgroundColor: panelColor,

      side: BorderSide(color: isSelected ? cat.color : borderColor),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildAreaTabCard({
    required PlantAreaCategory category,

    required int count,

    required String subtitle,

    required bool isSelected,

    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: isSelected ? category.color : borderColor,

              width: isSelected ? 2.0 : 1.0,
            ),

            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? category.color.withValues(alpha: 0.12)
                    : const Color(0x06000000),

                blurRadius: isSelected ? 14 : 6,

                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Container(
                    width: 34,

                    height: 34,

                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Icon(category.icon, color: category.color, size: 18),
                  ),

                  Text(
                    '$count',

                    style: TextStyle(
                      color: textPrimary,

                      fontSize: 22,

                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                category.label,

                style: TextStyle(
                  color: isSelected ? category.color : textPrimary,

                  fontSize: 12.5,

                  fontWeight: FontWeight.w800,
                ),

                maxLines: 1,

                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,

                style: const TextStyle(
                  color: textMuted,

                  fontSize: 11,

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

  void _showPhotoDialog(BuildContext context, String fullUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 520,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: brandBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FOTO SOPIR - $title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    fullUrl,
                    width: 460,
                    height: 360,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text('Gagal memuat foto dari server.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
