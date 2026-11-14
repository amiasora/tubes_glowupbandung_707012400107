import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/laporan_sampah.dart';
import '../models/verifikasi_laporan.dart';
import '../services/sesi_akun.dart';
import '../widgets/kerangka_warga.dart';
import 'jadwal_operasional.dart' show JadwalAdmin;
import 'pemeriksaan_admin.dart';

export 'jadwal_operasional.dart' show DashboardPetugas;

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({
    super.key,
    required this.akun,
    this.daftarLengkap = false,
    this.khususJadwal = false,
    this.idLaporanAwal,
  });

  final AkunAktif akun;
  final bool daftarLengkap;
  final bool khususJadwal;
  final int? idLaporanAwal;

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  late Future<List<Map<String, Object?>>> _laporan;
  int _versiFilter = 0;
  int? _laporanDipilih;
  final _gulir = ScrollController();
  StatusPenanganan? _statusPilihan;
  HasilVerifikasi? _hasilPilihan;
  DateTimeRange? _periodePilihan;
  StatusPenanganan? _statusAktif;
  HasilVerifikasi? _hasilAktif;
  DateTimeRange? _periodeAktif;

  @override
  void initState() {
    super.initState();
    _laporanDipilih = widget.idLaporanAwal;
    _laporan = DatabaseHelper.instance.ambilRingkasanLaporanAdmin(
      widget.akun.id,
    );
  }

  @override
  void dispose() {
    _gulir.dispose();
    super.dispose();
  }

  Future<void> _muatUlang() async {
    if (!mounted) return;
    setState(() {
      _laporan = DatabaseHelper.instance.ambilRingkasanLaporanAdmin(
        widget.akun.id,
      );
    });
  }

  Future<void> _bukaLaporan(int id) async {
    if (widget.daftarLengkap) {
      setState(() => _laporanDipilih = id);
      if (_gulir.hasClients) _gulir.jumpTo(0);
      return;
    }
    await Navigator.pushNamed<void>(context, '/admin/laporan', arguments: id);
    if (mounted) await _muatUlang();
  }

  Future<void> _jadwalkan(Map<String, Object?> item) async {
    final disimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JadwalAdmin(
          akun: widget.akun,
          idLaporan: item['id_laporan'] as int,
          kodeLaporan: item['kode_laporan'] as String,
          versiLaporan: item['versi'] as int,
        ),
      ),
    );
    if (!mounted) return;
    await _muatUlang();
    if (mounted && disimpan == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal dan penugasan tersimpan.')),
      );
    }
  }

  bool _siapJadwal(Map<String, Object?> item) =>
      item['status_penanganan'] == HasilVerifikasi.sesuai.statusBaru &&
      HasilVerifikasi.sesuai.cocok(item['hasil_verifikasi']);

  Future<void> _pilihPeriode() async {
    final sekarangWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final pilihan = await showDateRangePicker(
      context: context,
      initialDateRange: _periodePilihan,
      currentDate: DateTime(
        sekarangWib.year,
        sekarangWib.month,
        sekarangWib.day,
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(sekarangWib.year + 10, 12, 31),
      helpText: 'Periode pengiriman (WIB)',
      saveText: 'Pilih periode',
    );
    if (!mounted || pilihan == null) return;
    setState(() => _periodePilihan = pilihan);
  }

  void _terapkanFilter() => setState(() {
    _statusAktif = _statusPilihan;
    _hasilAktif = _hasilPilihan;
    _periodeAktif = _periodePilihan;
  });

  void _resetFilter() {
    setState(() {
      _versiFilter++;
      _statusPilihan = null;
      _hasilPilihan = null;
      _periodePilihan = null;
      _statusAktif = null;
      _hasilAktif = null;
      _periodeAktif = null;
    });
  }

  List<Map<String, Object?>> _saring(List<Map<String, Object?>> semua) {
    final periode = _periodeAktif;
    DateTime? mulai;
    DateTime? sebelum;
    if (periode != null) {
      final awal = periode.start;
      final akhir = periode.end;
      const selisihWib = Duration(hours: 7);
      mulai = DateTime.utc(
        awal.year,
        awal.month,
        awal.day,
      ).subtract(selisihWib);
      sebelum = DateTime.utc(
        akhir.year,
        akhir.month,
        akhir.day + 1,
      ).subtract(selisihWib);
    }
    return semua
        .where((item) {
          if (_statusAktif != null &&
              item['status_penanganan'] != _statusAktif!.nilaiDatabase) {
            return false;
          }
          if (_hasilAktif != null &&
              !_hasilAktif!.cocok(item['hasil_verifikasi'])) {
            return false;
          }
          final waktu = DateTime.parse(item['dibuat_at_utc'] as String);
          return (mulai == null || !waktu.isBefore(mulai)) &&
              (sebelum == null || waktu.isBefore(sebelum));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return KerangkaPeran(
      peran: PeranAkun.admin,
      ruteAktif: widget.khususJadwal
          ? '/admin/jadwal'
          : widget.daftarLengkap
          ? '/admin/laporan'
          : '/',
      menu: const {
        '/': 'Dashboard',
        '/admin/laporan': 'Laporan Masuk',
        '/admin/jadwal': 'Penjadwalan',
      },
      onKembali: _muatUlang,
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _laporan,
        builder: (context, snapshot) {
          return KontenWarga(
            controller: _gulir,
            children: [
              JudulHalamanWarga(
                judul: widget.khususJadwal
                    ? 'Penjadwalan Pengangkutan'
                    : widget.daftarLengkap
                    ? 'Laporan Masuk'
                    : 'Dashboard Admin',
                deskripsi: widget.khususJadwal
                    ? 'Atur tim dan waktu untuk laporan yang diterima.'
                    : widget.daftarLengkap
                    ? 'Telusuri laporan dan riwayat keputusan.'
                    : 'Halo, ${widget.akun.nama}. Tinjau laporan dan kelola penugasan.',
              ),
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(semanticsLabel: 'Memuat laporan')
              else if (snapshot.hasError)
                const KeadaanGlow(
                  judul: 'Daftar laporan belum dapat dimuat',
                  pesan: 'Muat ulang untuk mencoba kembali.',
                  icon: Icons.error_outline,
                )
              else ...[
                if (widget.daftarLengkap && _laporanDipilih != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _laporanDipilih = null),
                      icon: const Icon(Icons.close),
                      label: const Text('Tutup detail'),
                    ),
                  ),
                  PemeriksaanAdmin(
                    key: ValueKey(_laporanDipilih),
                    akun: widget.akun,
                    idLaporan: _laporanDipilih!,
                    onBerubah: _muatUlang,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.daftarLengkap) _panelFilter(),
                if (widget.khususJadwal)
                  ..._isiJadwal(snapshot.data ?? const [])
                else
                  ..._isiLaporan(snapshot.data ?? const []),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : _muatUlang,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Muat ulang laporan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _panelFilter() {
    final periode = _periodePilihan;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: KeyedSubtree(
          key: ValueKey(_versiFilter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                'Filter laporan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              KisiGlow(
                lebarMinimum: 235,
                children: [
                  DropdownButtonFormField<StatusPenanganan>(
                    initialValue: _statusPilihan,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status penanganan',
                    ),
                    hint: const Text('Semua status'),
                    items: [
                      const DropdownMenuItem<StatusPenanganan>(
                        child: Text('Semua status'),
                      ),
                      for (final status in StatusPenanganan.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.nilaiDatabase),
                        ),
                    ],
                    onChanged: (status) =>
                        setState(() => _statusPilihan = status),
                  ),
                  DropdownButtonFormField<HasilVerifikasi>(
                    initialValue: _hasilPilihan,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Hasil verifikasi',
                    ),
                    hint: const Text('Semua hasil'),
                    items: [
                      const DropdownMenuItem<HasilVerifikasi>(
                        child: Text('Semua hasil'),
                      ),
                      for (final hasil in HasilVerifikasi.values)
                        DropdownMenuItem(
                          value: hasil,
                          child: Text(hasil.label),
                        ),
                    ],
                    onChanged: (hasil) => setState(() => _hasilPilihan = hasil),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pilihPeriode,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      periode == null
                          ? 'Pilih periode pengiriman (WIB)'
                          : '${tanggalWarga(periode.start)} – ${tanggalWarga(periode.end)} WIB',
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _terapkanFilter,
                    child: const Text('Terapkan Filter'),
                  ),
                  OutlinedButton(
                    onPressed: _resetFilter,
                    child: const Text('Reset Filter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _isiLaporan(List<Map<String, Object?>> semua) {
    final laporan = _saring(semua);
    final baru = StatusPenanganan.baru.nilaiDatabase;
    final antrean = laporan.where(
      (item) =>
          item['status_penanganan'] == baru ||
          item['klarifikasi_masuk_at_utc'] != null,
    );
    final ditampilkan = widget.daftarLengkap ? laporan : antrean.take(5);
    final siap = laporan.where(_siapJadwal).take(5);

    return [
      if (!widget.daftarLengkap) ...[
        KisiGlow(
          lebarMinimum: 126,
          kolomMaksimal: 5,
          children: [
            _ringkasan(
              'Perlu ditinjau',
              antrean.length,
              Icons.fact_check_outlined,
            ),
            _ringkasan(
              'Diterima',
              _jumlah(laporan, 'Diterima'),
              Icons.check_circle_outline,
            ),
            _ringkasan(
              'Diproses',
              _jumlah(laporan, 'Diproses'),
              Icons.local_shipping_outlined,
            ),
            _ringkasan('Selesai', _jumlah(laporan, 'Selesai'), Icons.task_alt),
            _ringkasan('Ditolak', _jumlah(laporan, 'Ditolak'), Icons.block),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Antrean peninjauan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
      ],
      if (ditampilkan.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.daftarLengkap
                  ? (semua.isEmpty
                        ? 'Belum ada laporan.'
                        : 'Tidak ada laporan yang sesuai filter.')
                  : 'Belum ada laporan baru atau klarifikasi yang perlu ditinjau.',
            ),
          ),
        ),
      if (ditampilkan.isNotEmpty)
        KisiGlow(
          kolomMaksimal: 2,
          lebarMinimum: 405,
          children: [for (final item in ditampilkan) _kartuLaporan(item)],
        ),
      if (!widget.daftarLengkap && siap.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Siap dijadwalkan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        KisiGlow(
          kolomMaksimal: 2,
          lebarMinimum: 405,
          children: [for (final item in siap) _kartuLaporan(item)],
        ),
      ],
      const SizedBox(height: 12),
      if (widget.daftarLengkap)
        Text('${laporan.length} dari ${semua.length} laporan ditampilkan.')
      else
        OutlinedButton(
          onPressed: () async {
            await Navigator.pushNamed<void>(context, '/admin/laporan');
            if (mounted) await _muatUlang();
          },
          child: const Text('Lihat Laporan Masuk'),
        ),
    ];
  }

  List<Widget> _isiJadwal(List<Map<String, Object?>> laporan) {
    final siap = laporan.where(_siapJadwal).toList();
    final berjalan = laporan
        .where((item) => item['status_penanganan'] == 'Diproses')
        .toList();
    return [
      Text('Siap dijadwalkan', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      if (siap.isEmpty)
        const KeadaanGlow(
          judul: 'Belum ada laporan siap dijadwalkan',
          pesan:
              'Laporan yang dinyatakan Sesuai dan diterima akan muncul di sini.',
          icon: Icons.calendar_today_outlined,
        )
      else
        KisiGlow(
          kolomMaksimal: 2,
          lebarMinimum: 405,
          children: [for (final item in siap) _kartuLaporan(item)],
        ),
      const SizedBox(height: 22),
      Text('Penugasan berjalan', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      if (berjalan.isEmpty)
        const KeadaanGlow(
          judul: 'Belum ada penugasan berjalan',
          pesan: 'Simpan jadwal untuk menetapkan tim pengangkutan.',
          icon: Icons.local_shipping_outlined,
        )
      else
        KisiGlow(
          kolomMaksimal: 2,
          lebarMinimum: 405,
          children: [
            for (final item in berjalan)
              _kartuLaporan(item, jadwalBerjalan: true),
          ],
        ),
    ];
  }

  int _jumlah(List<Map<String, Object?>> laporan, String status) =>
      laporan.where((item) => item['status_penanganan'] == status).length;

  Widget _ringkasan(String label, int jumlah, IconData ikon) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text('$jumlah', style: Theme.of(context).textTheme.headlineSmall),
          Text(label),
        ],
      ),
    ),
  );

  Widget _kartuLaporan(
    Map<String, Object?> item, {
    bool jadwalBerjalan = false,
  }) {
    final status = item['status_penanganan'] as String;
    final waktu = waktuWibWarga(
      DateTime.parse(item['dibuat_at_utc'] as String),
    );
    final baru = status == StatusPenanganan.baru.nilaiDatabase;
    final klarifikasiMasuk = item['klarifikasi_masuk_at_utc'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${item['kode_laporan']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                LabelGlow(status),
                if (klarifikasiMasuk != null)
                  const LabelGlow('Klarifikasi masuk'),
              ],
            ),
            Text('${item['nama_kategori']} · ${item['kecamatan']}'),
            Text('${item['deskripsi_lokasi']} · $waktu'),
            if (klarifikasiMasuk != null)
              Text(
                'Masuk antrean · ${waktuWibWarga(DateTime.parse(klarifikasiMasuk))}',
              ),
            Text(
              'Verifikasi · ${item['hasil_verifikasi'] ?? 'Belum ada keputusan'}',
            ),
            if (_siapJadwal(item) || jadwalBerjalan)
              FilledButton.icon(
                onPressed: () => _jadwalkan(item),
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  jadwalBerjalan ? 'Lihat jadwal' : 'Jadwalkan Pengangkutan',
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: () => _bukaLaporan(item['id_laporan'] as int),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                klarifikasiMasuk != null
                    ? 'Tinjau Klarifikasi'
                    : baru
                    ? 'Tinjau laporan'
                    : 'Buka Riwayat Keputusan',
              ),
            ),
          ],
        ),
      ),
    );
  }
}