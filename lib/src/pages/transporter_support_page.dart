import 'package:flutter/material.dart';
import '../admin_auth.dart';
import '../api_client.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class TransporterSupportPage extends StatefulWidget {
  final TransportApiClient client;
  final AppConfig config;
  final AdminSession session;

  const TransporterSupportPage({
    super.key,
    required this.client,
    required this.config,
    required this.session,
  });

  @override
  State<TransporterSupportPage> createState() => _TransporterSupportPageState();
}

class _TransporterSupportPageState extends State<TransporterSupportPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      setState(() => _error = 'Judul dan rincian kendala wajib diisi.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    try {
      final res = await widget.client.submitSupportReport(
        title: title,
        description: desc,
        category: 'transporter',
      );
      if (res['success'] == false) {
        throw Exception(res['message'] ?? 'Gagal mengirim laporan kendala.');
      }

      setState(() {
        _success =
            'Laporan kendala berhasil dikirimkan ke IT Administrator & Tim Logistik!';
        _title.clear();
        _desc.clear();
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
              // Kolom form pengaduan
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: brandBlueSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: brandBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Formulir Pelaporan Kendala Gerbang',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        InputField(
                          label: 'Judul Kendala / Topik Masalah *',
                          controller: _title,
                          hintText:
                              'Contoh: Surat Jalan no 8821 tidak bisa disimpan',
                          prefixIcon: Icons.title_rounded,
                        ),
                        const SizedBox(height: 18),
                        InputField(
                          label: 'Deskripsi Rinci Kendala *',
                          controller: _desc,
                          maxLines: 5,
                          hintText:
                              'Jelaskan kronologi kendala, pesan error yang muncul, atau nomor plat armada terkait...',
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _busy ? null : _submitReport,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _busy ? 'Mengirim...' : 'Kirim Laporan Kendala',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
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
              ),
              const SizedBox(width: 20),

              // Kolom info bantuan operasional
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: brandBlueSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.contact_support_rounded,
                                color: brandBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Informasi Dukungan IT',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DetailLine(
                                label: 'UNIT OPERASIONAL',
                                value:
                                    'Logistik & Keamanan Pabrik Garudafood',
                              ),
                              DetailLine(
                                label: 'JAM LAYANAN DISPATCHER',
                                value: '24 Jam / 7 Hari Kerja',
                              ),
                              DetailLine(
                                label: 'SERVER KONEKSI',
                                value: 'Garuda Shield Main Backend Gateway',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: brandBlueSoft.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: brandBlue,
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Pastikan koneksi jaringan lokal atau VPN pabrik stabil saat melakukan konfirmasi check-in dan check-out armada.',
                                  style: TextStyle(
                                    color: brandBlueDeep,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
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
            ],
          ),
        ],
      ),
    );
  }
}
