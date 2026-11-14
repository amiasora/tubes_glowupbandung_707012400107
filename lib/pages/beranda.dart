import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/laporan_sampah.dart';
import '../models/referensi_laporan.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_warga.dart';
import 'riwayat_laporan.dart';

class Beranda extends StatefulWidget {
  const Beranda({super.key, this.idWarga = 1});
  final int idWarga;

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  List<LaporanSampah> _laporan = [];
  List<KategoriLaporan> _kategori = [];
  bool _memuat = true;
  String? _galat;
  String _nama = '';
  int _belumDibaca = 0;
  int _nomorMuat = 0;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final nomor = ++_nomorMuat;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final db = DatabaseHelper.instance;
      final laporan = await db.ambilLaporanWarga(widget.idWarga);
      final kategori = await db.ambilKategoriAktif();
      final notifikasi = await db.ambilNotifikasiWarga(widget.idWarga);
      final warga = await db.ambilWargaAktif();
      String? nama;
      for (final item in warga) {
        if (item['id_warga'] == widget.idWarga) nama = item['nama'] as String;
      }
      final pemilik = nama;
      if (pemilik == null) throw StateError('Akun warga tidak tersedia.');
      if (!mounted || nomor != _nomorMuat) return;
      setState(() {
        _laporan = laporan;
        _kategori = kategori;
        _nama = pemilik;
        _belumDibaca = notifikasi.where((item) => !item.sudahDibaca).length;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted || nomor != _nomorMuat) return;
      setState(() {
        _memuat = false;
        _galat = 'Laporan belum dapat dimuat. Coba muat ulang.';
      });
    }
  }

  Future<void> _buka(String route) async {
    await Navigator.pushNamed<Object?>(context, route);
    if (mounted) await _muat();
  }

  String _namaKategori(int id) {
    for (final item in _kategori) {
      if (item.idKategori == id) return item.namaKategori;
    }
    return 'Kategori tidak aktif';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final perluKlarifikasi = _laporan
        .where(
          (item) =>
              item.statusPenanganan == StatusPenanganan.menungguKlarifikasi,
        )
        .length;
    final selesai = _laporan
        .where((item) => item.statusPenanganan.nilaiDatabase == 'Selesai')
        .length;
    return KerangkaWarga(
      menuAktif: MenuWarga.dashboard,
      onKembali: _muat,
      child: KontenWarga(
        children: [
          _sambutan(context),
          const SizedBox(height: 20),
          if (_memuat)
            const LinearProgressIndicator(semanticsLabel: 'Memuat laporan')
          else if (_galat case final pesan?)
            KeadaanGlow(
              judul: 'Laporan belum dapat dimuat',
              pesan: pesan,
              icon: Icons.error_outline,
              aksi: OutlinedButton(
                onPressed: _muat,
                child: const Text('Muat ulang'),
              ),
            )
          else ...[
            KisiGlow(
              lebarMinimum: 148,
              kolomMaksimal: 4,
              children: [
                _ringkasan(
                  context,
                  'Total laporan',
                  _laporan.length,
                  Icons.receipt_long_outlined,
                  MenuWarga.riwayat,
                ),
                _ringkasan(
                  context,
                  'Klarifikasi',
                  perluKlarifikasi,
                  Icons.chat_bubble_outline,
                  MenuWarga.riwayat,
                ),
                _ringkasan(
                  context,
                  'Selesai',
                  selesai,
                  Icons.task_alt,
                  MenuWarga.riwayat,
                ),
                _ringkasan(
                  context,
                  'Belum dibaca',
                  _belumDibaca,
                  Icons.notifications_outlined,
                  MenuWarga.notifikasi,
                ),
              ],
            ),
            const SizedBox(height: 25),
            LayoutBuilder(
              builder: (context, batas) {
                final terbaru = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Laporan terbaru',
                          style: tema.textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => _buka(MenuWarga.riwayat.route),
                          child: const Text('Lihat semua'),
                        ),
                      ],
                    ),
                    if (_laporan.isEmpty)
                      const KeadaanGlow(
                        judul: 'Belum ada laporan',
                        pesan: 'Laporan yang Anda kirim akan muncul di sini.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    for (final item in _laporan.take(4))
                      _kartuLaporan(context, item),
                  ],
                );
                final notifikasi = PanelGlow(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: tema.colorScheme.primary,
                      ),
                      Text('Notifikasi', style: tema.textTheme.titleLarge),
                      Text(
                        _belumDibaca == 0
                            ? 'Semua pemberitahuan sudah dibaca.'
                            : '$_belumDibaca pemberitahuan belum dibaca.',
                        style: tema.textTheme.bodySmall,
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _buka(MenuWarga.notifikasi.route),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Buka notifikasi'),
                      ),
                    ],
                  ),
                );
                if (batas.maxWidth < 800) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [terbaru, notifikasi],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: terbaru),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: notifikasi),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _muat,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang dashboard'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sambutan(BuildContext context) {
    final tema = Theme.of(context);
    return LayoutBuilder(
      builder: (context, batas) {
        final lebar = batas.maxWidth >= 680;
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.hijauGelap, AppTheme.hijauSedang],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                if (lebar)
                  const Positioned(
                    right: 40,
                    top: 18,
                    bottom: 18,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 138,
                        color: Color(0x55CCEDAD),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(lebar ? 30 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        _nama.isEmpty ? 'Dashboard Warga' : 'Halo, $_nama',
                        style:
                            (lebar
                                    ? tema.textTheme.headlineLarge
                                    : tema.textTheme.headlineSmall)
                                ?.copyWith(color: Colors.white),
                      ),
                      const Text(
                        'Laporkan tumpukan sampah dan pantau penanganannya.',
                        style: TextStyle(
                          color: Color(0xFFE1F4E7),
                          height: 1.45,
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.aksenTerang,
                          foregroundColor: AppTheme.hijauGelap,
                        ),
                        onPressed: _memuat
                            ? null
                            : () => _buka(MenuWarga.buatLaporan.route),
                        icon: const Icon(Icons.add),
                        label: const Text('Buat Laporan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ringkasan(
    BuildContext context,
    String judul,
    int angka,
    IconData icon,
    MenuWarga menu,
  ) {
    final tema = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => _buka(menu.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Icon(icon, color: tema.colorScheme.primary, size: 20),
              Text('$angka', style: tema.textTheme.headlineSmall),
              Text(judul, style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuLaporan(BuildContext context, LaporanSampah laporan) {
    final tema = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLaporanTersimpan(
              idLaporan: laporan.idLaporan!,
              idWarga: widget.idWarga,
              namaWarga: _nama,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    laporan.kodeLaporan ?? 'Laporan',
                    style: tema.textTheme.titleMedium,
                  ),
                  LabelGlow(laporan.statusPenanganan.nilaiDatabase),
                ],
              ),
              Text(
                laporan.namaKategoriSaatKirim ??
                    _namaKategori(laporan.idKategori),
              ),
              Text(
                waktuWibWarga(laporan.dibuatAtUtc),
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}