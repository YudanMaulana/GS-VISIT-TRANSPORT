import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

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
  State<TransporterDashboardPage> createState() =>
      _TransporterDashboardPageState();
}

class _TransporterDashboardPageState extends State<TransporterDashboardPage> {
  bool _loading = false;
  List<ActiveGuestRow> _transporters = [];
  String? _error;
  PlantAreaCategory _selectedFilter = PlantAreaCategory.all;

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

  List<ActiveGuestRow> get _validTransporters =>
      _transporters.where((r) => r.isTransporter || r.loadType.isNotEmpty || r.vehiclePlate.isNotEmpty).toList();

  List<ActiveGuestRow> get _filteredTransporters {
    final list = _validTransporters;
    if (_selectedFilter == PlantAreaCategory.all) return list;
    return list.where((r) => r.areaCategory == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _validTransporters;
    final totalCount = list.length;
    final gfCount = list
        .where((r) => r.areaCategory == PlantAreaCategory.garudafood)
        .length;
    final dcCount =
        list.where((r) => r.areaCategory == PlantAreaCategory.dc).length;
    final mbrCount =
        list.where((r) => r.areaCategory == PlantAreaCategory.mbr).length;
    final filtered = _filteredTransporters;

    return ListView(
      children: [
        // Quick Action Toolbar
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => widget.onNavigate(1),
                        style: FilledButton.styleFrom(
                          backgroundColor: brandBlueSoft,
                          foregroundColor: brandBlueDeep,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.airport_shuttle_rounded, size: 18),
                        label: const Text('Buka Papan Penuh'),
                      ),
                      FilledButton.icon(
                        onPressed: () => widget.onNavigate(2),
                        style: FilledButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Konfirmasi Masuk'),
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
                            horizontal: 18,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: successColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.session.email.isNotEmpty
                            ? widget.session.email
                            : 'Petugas Gerbang',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Section Title: Pengelompokan 3 Area Pabrik
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Icon(Icons.layers_rounded, size: 18, color: brandBlueDeep),
              SizedBox(width: 8),
              Text(
                'Pengelompokan Area Pabrik (Sumedang)',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4 Area Summary Cards Row
        Row(
          children: [
            Expanded(
              child: _buildAreaCard(
                category: PlantAreaCategory.all,
                count: totalCount,
                subtitle: 'Semua armada di area',
                isSelected: _selectedFilter == PlantAreaCategory.all,
                onTap: () => setState(() => _selectedFilter = PlantAreaCategory.all),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildAreaCard(
                category: PlantAreaCategory.garudafood,
                count: gfCount,
                subtitle: 'Plant produksi utama',
                isSelected: _selectedFilter == PlantAreaCategory.garudafood,
                onTap: () => setState(
                    () => _selectedFilter = PlantAreaCategory.garudafood),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildAreaCard(
                category: PlantAreaCategory.dc,
                count: dcCount,
                subtitle: 'Pusat distribusi logistik',
                isSelected: _selectedFilter == PlantAreaCategory.dc,
                onTap: () =>
                    setState(() => _selectedFilter = PlantAreaCategory.dc),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildAreaCard(
                category: PlantAreaCategory.mbr,
                count: mbrCount,
                subtitle: 'Area logistik MBR',
                isSelected: _selectedFilter == PlantAreaCategory.mbr,
                onTap: () =>
                    setState(() => _selectedFilter = PlantAreaCategory.mbr),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Action Nav Cards Row
        Row(
          children: [
            Expanded(
              child: _buildActionNavCard(
                title: 'KONFIRMASI MASUK',
                caption: 'Input armada baru, pilih area & TTD satpam',
                icon: Icons.login_rounded,
                accentColor: brandBlue,
                onTap: () => widget.onNavigate(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionNavCard(
                title: 'KONFIRMASI KELUAR',
                caption: 'Pemeriksaan muatan armada & verifikasi selesai',
                icon: Icons.logout_rounded,
                accentColor: brandCoral,
                onTap: () => widget.onNavigate(3),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionNavCard(
                title: 'AKUN SOPIR',
                caption: 'Kelola status aktif/nonaktif & verifikasi SIM sopir',
                icon: Icons.manage_accounts_rounded,
                accentColor: const Color(0xFF0D9488),
                onTap: () => widget.onNavigate(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Real-time fleet container
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: brandBlueSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: brandBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Armada di Area Pabrik (Real-time)',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brandBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${filtered.length} Armada',
                                    style: const TextStyle(
                                      color: brandBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedFilter == PlantAreaCategory.all
                                  ? 'Daftar semua armada transporter yang telah check-in di seluruh area'
                                  : 'Menampilkan armada transporter khusus di area ${_selectedFilter.label}',
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
                    TextButton.icon(
                      onPressed: () => widget.onNavigate(1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Buka Papan Penuh'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Area Filter Chips Toolbar
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      category: PlantAreaCategory.all,
                      label: 'Semua Area ($totalCount)',
                      isSelected: _selectedFilter == PlantAreaCategory.all,
                      onSelected: () =>
                          setState(() => _selectedFilter = PlantAreaCategory.all),
                    ),
                    _buildFilterChip(
                      category: PlantAreaCategory.garudafood,
                      label: 'Garudafood ($gfCount)',
                      isSelected:
                          _selectedFilter == PlantAreaCategory.garudafood,
                      onSelected: () => setState(
                          () => _selectedFilter = PlantAreaCategory.garudafood),
                    ),
                    _buildFilterChip(
                      category: PlantAreaCategory.dc,
                      label: 'DC ($dcCount)',
                      isSelected: _selectedFilter == PlantAreaCategory.dc,
                      onSelected: () =>
                          setState(() => _selectedFilter = PlantAreaCategory.dc),
                    ),
                    _buildFilterChip(
                      category: PlantAreaCategory.mbr,
                      label: 'MBR ($mbrCount)',
                      isSelected: _selectedFilter == PlantAreaCategory.mbr,
                      onSelected: () =>
                          setState(() => _selectedFilter = PlantAreaCategory.mbr),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFC0C0)),
                    ),
                    child: Text(
                      'Galat memuat armada: $_error',
                      style: const TextStyle(
                        color: Color(0xFFD64045),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (filtered.isEmpty && !_loading)
                  EmptyStateCard(
                    title: _selectedFilter == PlantAreaCategory.all
                        ? 'Tidak Ada Armada di Pabrik'
                        : 'Tidak Ada Armada di ${_selectedFilter.label}',
                    description: _selectedFilter == PlantAreaCategory.all
                        ? 'Saat ini belum ada truk atau armada transporter aktif di dalam seluruh area pabrik.'
                        : 'Saat ini tidak ada armada transporter yang terdaftar di area ${_selectedFilter.label}.',
                    icon: _selectedFilter.icon,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final row = filtered[index];
                      final isBongkar = row.loadType == 'bongkar';
                      final typeColor = isBongkar ? brandBlue : brandCoral;
                      final areaCat = row.areaCategory;

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
                                color: areaCat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                areaCat.icon,
                                color: areaCat.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Badge Area Pabrik
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: areaCat.color
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: areaCat.color
                                                .withValues(alpha: 0.3),
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
                                      // Status Pill Load Type
                                      StatusPill(
                                        text: row.loadType.isNotEmpty
                                            ? row.loadType.toUpperCase()
                                            : 'TRANSPORTER',
                                        color: typeColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Antrean: ${row.queueNumber != null ? "#${row.queueNumber} (${areaCat.code})" : (row.status == "planned" ? "Menunggu Gerbang" : "#${row.planId}")} • Nopol: ${row.vehiclePlate.isNotEmpty ? row.vehiclePlate : "-"} • Ekspedisi: ${row.company.isNotEmpty ? row.company : "-"} • Masuk: ${_formatTime(row.checkinAt)}',
                                    style: const TextStyle(
                                      color: textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () => widget.onNavigate(3),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Konfirmasi Keluar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaCard({
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
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? category.color : borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? category.color.withValues(alpha: 0.15)
                    : const Color(0x06000000),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category.icon, color: category.color, size: 20),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                category.label,
                style: TextStyle(
                  color: isSelected ? category.color : textPrimary,
                  fontSize: 13,
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

  Widget _buildFilterChip({
    required PlantAreaCategory category,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        category.icon,
        size: 16,
        color: isSelected ? Colors.white : category.color,
      ),
      label: Text(label),
      selectedColor: category.color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: panelColor,
      side: BorderSide(
        color: isSelected ? category.color : borderColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildActionNavCard({
    required String title,
    required String caption,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                caption,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Klik untuk membuka alur →',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
