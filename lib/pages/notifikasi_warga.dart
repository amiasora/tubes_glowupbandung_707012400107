import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/notifikasi_laporan.dart';
import '../widgets/kerangka_warga.dart';
import 'riwayat_laporan.dart';

class NotifikasiWarga extends StatefulWidget {
  const NotifikasiWarga({super.key, this.idWarga = 1});
  final int idWarga;

  @override
  State<NotifikasiWarga> createState() => _NotifikasiWargaState();
}

class _NotifikasiWargaState extends State<NotifikasiWarga> {
  List<NotifikasiLaporan> _daftar = [];
  bool _memuat = true;
  bool _membuka = false;
  bool _hanyaBelumDibaca = false;
  String? _galat;
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
      final daftar = await DatabaseHelper.instance.ambilNotifikasiWarga(
        widget.idWarga,
      );
      if (!mounted || nomor != _nomorMuat) return;
      setState(() {
        _daftar = daftar;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted || nomor != _nomorMuat) return;
      setState(() {
        _memuat = false;
        _galat = 'Notifikasi belum dapat dimuat. Coba muat ulang.';
      });
    }
  }

  Future<void> _buka(NotifikasiLaporan item) async {
    if (_membuka) return;
    setState(() => _membuka = true);
    try {
      final db = DatabaseHelper.instance;
      final laporan = await db.ambilDetailLaporan(
        idLaporan: item.idLaporan,
        idWarga: widget.idWarga,
      );
      if (laporan == null) throw StateError('Laporan tidak ditemukan.');
      await db.tandaiNotifikasiDibaca(
        idNotifikasi: item.idNotifikasi,
        idWarga: widget.idWarga,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => DetailLaporanTersimpan(
            idLaporan: item.idLaporan,
            idWarga: widget.idWarga,
            bukaAktivitas: item.jenis == 'tanggapan',
          ),
        ),
      );
      if (mounted) await _muat();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemberitahuan belum dapat dibuka. Coba lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _membuka = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final belumDibaca = _daftar.where((item) => !item.sudahDibaca).toList();
    final terlihat = _hanyaBelumDibaca ? belumDibaca : _daftar;
    return KerangkaWarga(
      menuAktif: MenuWarga.notifikasi,
      navigasiAktif: !_membuka,
      onKembali: _muat,
      child: KontenWarga(
        maxLebar: 960,
        children: [
          const JudulHalamanWarga(
            judul: 'Notifikasi',
            deskripsi:
                'Pembaruan verifikasi, jadwal, dan aktivitas laporan Anda.',
          ),
          if (_memuat || _membuka) const LinearProgressIndicator(),
          if (_galat case final galat?)
            KeadaanGlow(
              judul: 'Notifikasi tidak tersedia',
              pesan: galat,
              icon: Icons.error_outline,
              aksi: OutlinedButton(
                onPressed: _muat,
                child: const Text('Muat ulang'),
              ),
            )
          else if (!_memuat) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: !_hanyaBelumDibaca,
                  onSelected: (_) => setState(() => _hanyaBelumDibaca = false),
                ),
                ChoiceChip(
                  label: Text('Belum dibaca (${belumDibaca.length})'),
                  selected: _hanyaBelumDibaca,
                  onSelected: (_) => setState(() => _hanyaBelumDibaca = true),
                ),
                IconButton(
                  tooltip: 'Muat ulang notifikasi',
                  onPressed: _membuka ? null : _muat,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (terlihat.isEmpty)
              KeadaanGlow(
                judul: _hanyaBelumDibaca
                    ? 'Semua sudah dibaca'
                    : 'Belum ada notifikasi',
                pesan: _hanyaBelumDibaca
                    ? 'Pemberitahuan sebelumnya tersedia di tab Semua.'
                    : 'Pembaruan untuk laporan Anda akan muncul di sini.',
                icon: Icons.notifications_none,
              ),
            for (final item in terlihat)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: item.sudahDibaca
                      ? null
                      : tema.colorScheme.surfaceContainerLow,
                  child: InkWell(
                    onTap: _membuka ? null : () => _buka(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Icon(
                            item.jenis == 'tanggapan'
                                ? Icons.chat_bubble_outline
                                : Icons.notifications_outlined,
                            color: tema.colorScheme.primary,
                          ),
                          Expanded(
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
                                      item.judul,
                                      style: tema.textTheme.titleMedium,
                                    ),
                                    if (!item.sudahDibaca)
                                      const LabelGlow('Belum dibaca'),
                                  ],
                                ),
                                Text(
                                  '${item.kodeLaporan} · ${waktuWibWarga(item.dibuatAtUtc)}',
                                  style: tema.textTheme.bodySmall,
                                ),
                                Text(item.ringkasan),
                                Text(
                                  item.jenis == 'tanggapan'
                                      ? 'Buka tanggapan'
                                      : 'Buka detail',
                                  style: TextStyle(
                                    color: tema.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}