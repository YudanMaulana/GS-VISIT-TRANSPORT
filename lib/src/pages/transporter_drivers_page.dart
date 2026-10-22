import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import '../theme.dart';

const Color statusRed = Color(0xFFDC2626);
const Color statusGreen = Color(0xFF16A34A);
const Color brandYellowDark = Color(0xFFD97706);
const Color brandYellowSoft = Color(0xFFFEF3C7);
const Color surfaceMuted = Color(0xFFF8FAFC);
const Color textSecondary = Color(0xFF475569);

enum DriverStatusFilter { all, active, inactive, simExpired }

class TransporterDriversPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;

  const TransporterDriversPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
  });

  @override
  State<TransporterDriversPage> createState() => _TransporterDriversPageState();
}

class _TransporterDriversPageState extends State<TransporterDriversPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = false;
  List<TransporterDriver> _drivers = [];
  String? _error;
  DriverStatusFilter _selectedFilter = DriverStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.client.fetchTransporterDrivers();
      if (mounted) {
        setState(() => _drivers = list);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TransporterDriver> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _drivers.where((d) {
      if (_selectedFilter == DriverStatusFilter.active && !d.isActive) {
        return false;
      }
      if (_selectedFilter == DriverStatusFilter.inactive && d.isActive) {
        return false;
      }
      if (_selectedFilter == DriverStatusFilter.simExpired && !d.isSimExpired) {
        return false;
      }
      if (q.isEmpty) return true;
      return d.matches(q);
    }).toList();
  }

  int get _countActive => _drivers.where((d) => d.isActive).length;
  int get _countInactive => _drivers.where((d) => !d.isActive).length;
  int get _countSimExpired => _drivers.where((d) => d.isSimExpired).length;

  Future<void> _toggleActive(TransporterDriver driver) async {
    final newStatus = !driver.isActive;
    final actionWord = newStatus ? 'mengaktifkan' : 'menonaktifkan';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: newStatus
                    ? const Color(0x1F16A34A)
                    : const Color(0x1FDC2626),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                newStatus ? Icons.check_circle_rounded : Icons.block_rounded,
                color: newStatus ? const Color(0xFF16A34A) : statusRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${newStatus ? "Aktifkan" : "Nonaktifkan"} Akun Sopir?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin $actionWord akun sopir "${driver.fullName}" (${driver.company.isNotEmpty ? driver.company : "Transporter"})?',
              style: const TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: newStatus
                    ? const Color(0x0F16A34A)
                    : const Color(0x0FDC2626),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: newStatus
                      ? const Color(0x3316A34A)
                      : const Color(0x33DC2626),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: newStatus ? const Color(0xFF16A34A) : statusRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      newStatus
                          ? 'Setelah diaktifkan, sopir dapat kembali melakukan proses konfirmasi masuk dan verifikasi gerbang.'
                          : 'Sopir yang dinonaktifkan akan langsung DITOLAK saat mencoba check-in di seluruh gerbang pabrik (GF, DC, MBR).',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: newStatus ? const Color(0xFF16A34A) : statusRed,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: newStatus ? const Color(0xFF16A34A) : statusRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              newStatus ? 'Ya, Aktifkan' : 'Ya, Nonaktifkan',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await widget.client.toggleTransporterDriverActive(
        visitorId: driver.id,
        isActive: newStatus,
      );

      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ??
                  'Status akun sopir berhasil diperbarui.'),
              backgroundColor: newStatus ? const Color(0xFF16A34A) : statusRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _load();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Gagal memperbarui status.'),
              backgroundColor: statusRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: statusRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: brandBlueSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: brandBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manajemen Akun Sopir & Profil Transporter',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Kelola status aktif/non-aktif akun sopir, verifikasi masa berlaku SIM, dan ekspedisi logistik.',
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
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Muat Ulang'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandBlue,
                      side: const BorderSide(color: brandBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // KPI Metric Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Sopir Terdaftar',
                  value: '${_drivers.length}',
                  subtitle: 'Akun terdaftar di database',
                  icon: Icons.groups_rounded,
                  color: brandBlue,
                  bgColor: brandBlueSoft,
                  onTap: () => setState(() => _selectedFilter = DriverStatusFilter.all),
                  isSelected: _selectedFilter == DriverStatusFilter.all,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Akun Aktif (Dizinkan)',
                  value: '$_countActive',
                  subtitle: 'Dapat check-in di 3 area',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0x1F16A34A),
                  onTap: () => setState(() => _selectedFilter = DriverStatusFilter.active),
                  isSelected: _selectedFilter == DriverStatusFilter.active,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Akun Nonaktif (Blokir)',
                  value: '$_countInactive',
                  subtitle: 'Ditolak saat gerbang masuk',
                  icon: Icons.block_rounded,
                  color: statusRed,
                  bgColor: const Color(0x1FDC2626),
                  onTap: () => setState(() => _selectedFilter = DriverStatusFilter.inactive),
                  isSelected: _selectedFilter == DriverStatusFilter.inactive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'SIM Kedaluwarsa',
                  value: '$_countSimExpired',
                  subtitle: 'Masa berlaku SIM telah habis',
                  icon: Icons.warning_amber_rounded,
                  color: brandYellowDark,
                  bgColor: brandYellowSoft,
                  onTap: () => setState(() => _selectedFilter = DriverStatusFilter.simExpired),
                  isSelected: _selectedFilter == DriverStatusFilter.simExpired,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filter Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            hintText: 'Cari nama sopir, perusahaan ekspedisi, no. SIM, atau ID sopir...',
                            hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                            filled: true,
                            fillColor: surfaceMuted,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Semua Sopir (${_drivers.length})',
                        filter: DriverStatusFilter.all,
                        icon: Icons.people_outline_rounded,
                      ),
                      _buildFilterChip(
                        label: 'Akun Aktif ($_countActive)',
                        filter: DriverStatusFilter.active,
                        icon: Icons.check_circle_outline_rounded,
                        activeColor: const Color(0xFF16A34A),
                      ),
                      _buildFilterChip(
                        label: 'Akun Nonaktif ($_countInactive)',
                        filter: DriverStatusFilter.inactive,
                        icon: Icons.block_rounded,
                        activeColor: statusRed,
                      ),
                      _buildFilterChip(
                        label: 'SIM Kedaluwarsa ($_countSimExpired)',
                        filter: DriverStatusFilter.simExpired,
                        icon: Icons.badge_outlined,
                        activeColor: brandYellowDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Driver List
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat profil akun sopir transporter...',
                          style: TextStyle(color: textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            )
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: statusRed),
                      const SizedBox(height: 12),
                      Text('Gagal memuat profil sopir: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: statusRed, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filtered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_off_rounded, size: 48, color: textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 14),
                      const Text(
                        'Tidak Ada Akun Sopir Sesuai Kriteria',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Coba sesuaikan kata kunci pencarian atau ubah filter status di atas.',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final driver = filtered[idx];
                return _buildDriverCard(driver);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required DriverStatusFilter filter,
    required IconData icon,
    Color activeColor = brandBlue,
  }) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeColor : textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(TransporterDriver driver) {
    final isSimExp = driver.isSimExpired;
    final isSimSoon = driver.isSimExpiringSoon;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: driver.isActive ? borderColor : statusRed.withValues(alpha: 0.35),
          width: driver.isActive ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDriverProfile(driver),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Foto Profil Sopir Transporter
              _buildDriverAvatar(
                driver,
                size: 52,
                showStatusBadge: true,
                onPhotoTap: () {
                  final photoUrl = widget.client.resolvePhotoUrl(driver.photoUrl);
                  if (photoUrl.isNotEmpty) {
                    _showPhotoPreviewDialog(photoUrl, driver.fullName);
                  } else {
                    _showDriverProfile(driver);
                  }
                },
              ),
              const SizedBox(width: 16),

              // Driver Identity & Info
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driver.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Visitor Code Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            driver.visitorCode.isNotEmpty ? driver.visitorCode : '#${driver.id}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          driver.company.isNotEmpty ? driver.company : 'Perusahaan Logistik',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (driver.phone.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.phone_rounded, size: 13, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            driver.phone,
                            style: const TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // SIM Card Details
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSimExp
                        ? statusRed.withValues(alpha: 0.08)
                        : (isSimSoon ? brandYellowSoft : surfaceMuted),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSimExp
                          ? statusRed.withValues(alpha: 0.3)
                          : (isSimSoon ? brandYellowDark.withValues(alpha: 0.3) : borderColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 14,
                            color: isSimExp
                                ? statusRed
                                : (isSimSoon ? brandYellowDark : brandBlue),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            driver.simNumber.isNotEmpty ? driver.simNumber : 'SIM Tidak Tercatat',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSimExp ? statusRed : textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            driver.simExpiresAt != null
                                ? 'Exp: ${_formatDate(driver.simExpiresAt)}'
                                : 'Exp: Tidak Ditentukan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSimExp
                                  ? statusRed
                                  : (isSimSoon ? brandYellowDark : textMuted),
                            ),
                          ),
                          if (isSimExp) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: statusRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'KEDALUWARSA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ] else if (isSimSoon) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: brandYellowDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SEGERA HABIS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Trips / Activity Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.totalTrips} Kali Masuk',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.lastVisit != null
                          ? 'Terakhir: ${_formatDate(driver.lastVisit)}'
                          : 'Belum ada kunjungan',
                      style: const TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Buttons / Status Action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandBlue,
                      side: const BorderSide(color: brandBlue, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showDriverProfile(driver),
                    icon: const Icon(Icons.person_pin_rounded, size: 16),
                    label: const Text('Lihat Profil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: driver.isActive
                              ? const Color(0x1F16A34A)
                              : const Color(0x1FDC2626),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: driver.isActive
                                ? const Color(0x4D16A34A)
                                : const Color(0x4DDC2626),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: driver.isActive ? const Color(0xFF16A34A) : statusRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              driver.isActive ? 'AKTIF' : 'NONAKTIF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: driver.isActive ? const Color(0xFF16A34A) : statusRed,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 28,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: driver.isActive ? statusRed : const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => _toggleActive(driver),
                          icon: Icon(
                            driver.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                            size: 13,
                          ),
                          label: Text(
                            driver.isActive ? 'Nonaktifkan' : 'Aktifkan',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Komponen Avatar Foto Profil Transporter dengan Fallback Inisial & Indikator Status
  Widget _buildDriverAvatar(
    TransporterDriver driver, {
    double size = 52,
    bool showStatusBadge = true,
    VoidCallback? onPhotoTap,
  }) {
    final photoUrl = widget.client.resolvePhotoUrl(driver.photoUrl);

    Widget avatarImage;
    if (photoUrl.isNotEmpty) {
      avatarImage = Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(driver, size),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: const CircularProgressIndicator(strokeWidth: 2, color: brandBlue),
            ),
          );
        },
      );
    } else {
      avatarImage = _buildInitialsFallback(driver, size);
    }

    final avatarBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: driver.isActive ? brandBlueSoft : surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: driver.isActive ? brandBlue.withValues(alpha: 0.3) : borderColor,
          width: 1.5,
        ),
      ),
      child: ClipOval(child: avatarImage),
    );

    return Stack(
      children: [
        if (onPhotoTap != null)
          Tooltip(
            message: photoUrl.isNotEmpty ? 'Klik untuk perbesar foto profil' : 'Foto profil belum tersedia',
            child: InkWell(
              onTap: onPhotoTap,
              customBorder: const CircleBorder(),
              child: avatarBox,
            ),
          )
        else
          avatarBox,
        if (showStatusBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: driver.isActive ? const Color(0xFF16A34A) : statusRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsFallback(TransporterDriver driver, double size) {
    return Container(
      width: size,
      height: size,
      color: driver.isActive ? brandBlueSoft : surfaceMuted,
      child: Center(
        child: Text(
          driver.fullName.isNotEmpty
              ? driver.fullName.substring(0, 1).toUpperCase()
              : 'S',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w900,
            color: driver.isActive ? brandBlue : textMuted,
          ),
        ),
      ),
    );
  }

  /// Dialog Rincian Profil Sopir Transporter Lengkap
  Future<void> _showDriverProfile(TransporterDriver driver) async {
    final photoUrl = widget.client.resolvePhotoUrl(driver.photoUrl);
    final isSimExp = driver.isSimExpired;
    final isSimSoon = driver.isSimExpiringSoon;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 620,
            constraints: const BoxConstraints(maxHeight: 720),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Banner Garudafood
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: brandBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROFIL RESMI TRANSPORTER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Identitas pengemudi armada logistik rekanan Garudafood',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                ),

                // Isi Konten Profil
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Profil (Foto Besar & Nama)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surfaceMuted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              // Foto Profil Utama (Diameter 100px)
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (photoUrl.isNotEmpty) {
                                        _showPhotoPreviewDialog(photoUrl, driver.fullName);
                                      }
                                    },
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(color: brandBlue, width: 3),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1F000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: photoUrl.isNotEmpty
                                            ? Image.network(
                                                photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    _buildInitialsFallback(driver, 100),
                                              )
                                            : _buildInitialsFallback(driver, 100),
                                      ),
                                    ),
                                  ),
                                  if (photoUrl.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: brandBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 20),

                              // Info Utama
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            driver.fullName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: driver.isActive
                                                ? const Color(0x1F16A34A)
                                                : const Color(0x1FDC2626),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: driver.isActive
                                                  ? const Color(0xFF16A34A)
                                                  : statusRed,
                                            ),
                                          ),
                                          child: Text(
                                            driver.isActive ? 'AKUN AKTIF' : 'DINONAKTIFKAN',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: driver.isActive
                                                  ? const Color(0xFF16A34A)
                                                  : statusRed,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: brandBlueSoft,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            driver.visitorCode.isNotEmpty
                                                ? driver.visitorCode
                                                : 'ID #${driver.id}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: brandBlue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            driver.company.isNotEmpty ? driver.company : 'Perusahaan Logistik',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (photoUrl.isNotEmpty)
                                      InkWell(
                                        onTap: () => _showPhotoPreviewDialog(photoUrl, driver.fullName),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.image_search_rounded, size: 14, color: brandBlue),
                                            SizedBox(width: 6),
                                            Text(
                                              'Klik untuk melihat foto resolusi penuh',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: brandBlue,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.info_outline_rounded, size: 14, color: textMuted),
                                          SizedBox(width: 6),
                                          Text(
                                            'Foto profil fisik belum direkam di database',
                                            style: TextStyle(fontSize: 12, color: textMuted),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Informasi Kontak & Lisensi Mengemudi (SIM)
                        const Text(
                          'DATA LISENSI & KONTAK RESMI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              _buildProfileRow(
                                icon: Icons.badge_outlined,
                                label: 'Nomor SIM Sopir',
                                value: driver.simNumber.isNotEmpty ? driver.simNumber : 'Belum Tercatat',
                              ),
                              const Divider(height: 20, color: borderColor),
                              _buildProfileRow(
                                icon: Icons.event_available_outlined,
                                label: 'Masa Berlaku SIM',
                                value: driver.simExpiresAt != null
                                    ? _formatDate(driver.simExpiresAt)
                                    : 'Tidak Tercatat',
                                badge: isSimExp
                                    ? _buildBadge('KEDALUWARSA', statusRed)
                                    : (isSimSoon ? _buildBadge('SEGERA HABIS', brandYellowDark) : _buildBadge('BERLAKU VALID', const Color(0xFF16A34A))),
                              ),
                              const Divider(height: 20, color: borderColor),
                              _buildProfileRow(
                                icon: Icons.phone_android_rounded,
                                label: 'Nomor WhatsApp / HP',
                                value: driver.phone.isNotEmpty ? driver.phone : 'Belum Tercatat',
                                action: driver.phone.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16, color: brandBlue),
                                        tooltip: 'Salin nomor HP',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: driver.phone));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Nomor ${driver.phone} disalin ke clipboard.'),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Riwayat Operasional di Pabrik
                        const Text(
                          'RIWAYAT OPERASIONAL & KUNJUNGAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              _buildProfileRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'Total Kunjungan Armada',
                                value: '${driver.totalTrips} Kali Check-in di Pabrik',
                              ),
                              const Divider(height: 20, color: borderColor),
                              _buildProfileRow(
                                icon: Icons.history_rounded,
                                label: 'Kunjungan Terakhir',
                                value: driver.lastVisit != null
                                    ? _formatDate(driver.lastVisit)
                                    : 'Belum pernah check-in',
                              ),
                              if (driver.createdAt != null) ...[
                                const Divider(height: 20, color: borderColor),
                                _buildProfileRow(
                                  icon: Icons.app_registration_rounded,
                                  label: 'Tanggal Terdaftar',
                                  value: _formatDate(driver.createdAt),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: surfaceMuted,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Toggle Aktif/Nonaktif di Modal
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: driver.isActive ? statusRed : const Color(0xFF16A34A),
                          side: BorderSide(
                            color: driver.isActive ? statusRed : const Color(0xFF16A34A),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _toggleActive(driver);
                        },
                        icon: Icon(
                          driver.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                          size: 16,
                        ),
                        label: Text(
                          driver.isActive ? 'Nonaktifkan Akun Sopir' : 'Aktifkan Akun Sopir',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),

                      // Tombol Tutup
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: brandBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? badge,
    Widget? action,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: brandBlue),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                badge,
              ],
              if (action != null) ...[action],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  /// Dialog Lightbox Tampilan Foto Penuh
  void _showPhotoPreviewDialog(String fullUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 540,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: brandBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FOTO PROFIL - $title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                    width: 480,
                    height: 380,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 240,
                      color: surfaceMuted,
                      child: const Center(
                        child: Text(
                          'Gagal memuat foto dari server.',
                          style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: brandBlue),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: brandBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup'),
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
