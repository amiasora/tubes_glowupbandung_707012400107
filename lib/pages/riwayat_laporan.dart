import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../db/database_helper.dart';
import '../models/foto_laporan.dart';
import '../models/jadwal_pengangkutan.dart';
import '../models/klarifikasi_laporan.dart';
import '../models/laporan_sampah.dart';
import '../models/penanganan_laporan.dart';
import '../models/referensi_laporan.dart';
import '../models/titik_laporan.dart';
import '../widgets/kerangka_warga.dart';
import 'buat_laporan.dart';
import 'jadwal_operasional.dart' show KartuAktivitasPengangkutan;
import 'klarifikasi_warga.dart';
import 'pilih_lokasi_laporan.dart';

class RiwayatLaporan extends StatefulWidget {
  const RiwayatLaporan({super.key, this.idWarga = 1});
  final int idWarga;

  @override
  State<RiwayatLaporan> createState() => _RiwayatLaporanState();
}

class _RiwayatLaporanState extends State<RiwayatLaporan> {
  final _database = DatabaseHelper.instance;
  List<LaporanSampah> _semua = [];
  String _nama = '';
  bool _memuat = true;
  String? _galat;
  int _nomorMuat = 0;
  StatusPenanganan? _statusPilihan;
  DateTime? _awalPilihan;
  DateTime? _akhirPilihan;
  StatusPenanganan? _statusAktif;
  DateTime? _awalAktif;
  DateTime? _akhirAktif;
  String? _galatFilter;
  int _versiFilter = 0;

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
      final daftar = await _database.ambilLaporanWarga(widget.idWarga);
      final warga = await _database.ambilWargaAktif();
      String? nama;
      for (final akun in warga) {
        if (akun['id_warga'] == widget.idWarga) nama = akun['nama'] as String;
      }
      final pemilik = nama;
      if (pemilik == null) throw StateError('Akun warga tidak tersedia.');
      if (!mounted || nomor != _nomorMuat) return;
      setState(() {
        _semua = daftar;
        _nama = pemilik;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted || nomor != _nomorMuat) return;
      setState(() {
        _memuat = false;
        _galat = 'Riwayat belum dapat dimuat. Coba muat ulang.';
      });
    }
  }

  Future<void> _buatLaporan() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BuatLaporan(idWarga: widget.idWarga)),
    );
    if (mounted) await _muat();
  }

  Future<void> _pilihTanggal(bool awal) async {
    final sekarang = DateTime.now().toUtc().add(const Duration(hours: 7));
    final pilihan = await showDatePicker(
      context: context,
      initialDate:
          (awal ? _awalPilihan : _akhirPilihan) ??
          DateTime(sekarang.year, sekarang.month, sekarang.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(sekarang.year + 10, 12, 31),
      helpText: awal ? 'Tanggal awal (WIB)' : 'Tanggal akhir (WIB)',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted || pilihan == null) return;
    setState(() {
      if (awal) {
        _awalPilihan = pilihan;
      } else {
        _akhirPilihan = pilihan;
      }
      _galatFilter = null;
    });
  }

  void _terapkanFilter() {
    final awal = _awalPilihan;
    final akhir = _akhirPilihan;
    if (awal != null && akhir != null && akhir.isBefore(awal)) {
      setState(
        () => _galatFilter =
            'Tanggal akhir harus sama atau setelah tanggal awal.',
      );
      return;
    }
    setState(() {
      _statusAktif = _statusPilihan;
      _awalAktif = awal;
      _akhirAktif = akhir;
      _galatFilter = null;
    });
  }

  void _resetFilter() => setState(() {
    _statusPilihan = null;
    _statusAktif = null;
    _awalPilihan = null;
    _akhirPilihan = null;
    _awalAktif = null;
    _akhirAktif = null;
    _galatFilter = null;
    _versiFilter++;
  });

  List<LaporanSampah> get _hasilFilter {
    final awal = _awalAktif;
    final akhir = _akhirAktif;
    final mulaiUtc = awal == null
        ? null
        : DateTime.utc(
            awal.year,
            awal.month,
            awal.day,
          ).subtract(const Duration(hours: 7));
    final sebelumUtc = akhir == null
        ? null
        : DateTime.utc(
            akhir.year,
            akhir.month,
            akhir.day + 1,
          ).subtract(const Duration(hours: 7));
    return _semua
        .where((item) {
          if (_statusAktif != null && item.statusPenanganan != _statusAktif) {
            return false;
          }
          if (mulaiUtc != null && item.dibuatAtUtc.isBefore(mulaiUtc)) {
            return false;
          }
          if (sebelumUtc != null && !item.dibuatAtUtc.isBefore(sebelumUtc)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasilFilter;
    final tema = Theme.of(context);
    return KerangkaWarga(
      menuAktif: MenuWarga.riwayat,
      onKembali: _muat,
      child: KontenWarga(
        children: [
          const JudulHalamanWarga(
            judul: 'Riwayat Laporan',
            deskripsi: 'Telusuri laporan dan perkembangan penanganannya.',
          ),
          if (_memuat)
            const LinearProgressIndicator()
          else if (_galat case final galat?)
            KeadaanGlow(
              judul: 'Riwayat tidak tersedia',
              pesan: galat,
              icon: Icons.error_outline,
              aksi: OutlinedButton(
                onPressed: _muat,
                child: const Text('Muat ulang'),
              ),
            )
          else ...[
            PanelGlow(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Text('Filter laporan', style: tema.textTheme.titleMedium),
                  KisiGlow(
                    lebarMinimum: 210,
                    children: [
                      DropdownButtonFormField<StatusPenanganan>(
                        key: ValueKey(_versiFilter),
                        initialValue: _statusPilihan,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          hintText: 'Semua status',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua status'),
                          ),
                          for (final status in StatusPenanganan.values)
                            DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.nilaiDatabase,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (nilai) =>
                            setState(() => _statusPilihan = nilai),
                      ),
                      _kolomTanggal(
                        'Tanggal awal',
                        _awalPilihan,
                        () => _pilihTanggal(true),
                      ),
                      _kolomTanggal(
                        'Tanggal akhir',
                        _akhirPilihan,
                        () => _pilihTanggal(false),
                      ),
                    ],
                  ),
                  Text(
                    'Tanggal pengiriman dalam WIB, termasuk kedua batas tanggal.',
                    style: tema.textTheme.bodySmall,
                  ),
                  if (_galatFilter case final galat?)
                    Text(
                      galat,
                      style: TextStyle(color: tema.colorScheme.error),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _terapkanFilter,
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Terapkan Filter'),
                      ),
                      TextButton(
                        onPressed: _resetFilter,
                        child: const Text('Reset Filter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${hasil.length} dari ${_semua.length} laporan',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Muat ulang riwayat',
                  onPressed: _muat,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_semua.isEmpty)
              KeadaanGlow(
                judul: 'Belum ada laporan',
                icon: Icons.inbox_outlined,
                pesan: 'Laporan yang Anda kirim akan tampil di sini.',
                aksi: FilledButton(
                  onPressed: _buatLaporan,
                  child: const Text('Buat Laporan'),
                ),
              )
            else if (hasil.isEmpty)
              KeadaanGlow(
                judul: 'Tidak ada hasil',
                icon: Icons.search_off,
                pesan: 'Coba status atau rentang tanggal lain.',
                aksi: OutlinedButton(
                  onPressed: _resetFilter,
                  child: const Text('Reset Filter'),
                ),
              )
            else
              for (final item in hasil)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: InkWell(
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailLaporanTersimpan(
                            idLaporan: item.idLaporan!,
                            idWarga: widget.idWarga,
                            namaWarga: _nama,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          spacing: 12,
                          children: [
                            const Icon(Icons.description_outlined),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 6,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        item.kodeLaporan ?? 'Laporan',
                                        style: tema.textTheme.titleMedium,
                                      ),
                                      LabelGlow(
                                        item.statusPenanganan.nilaiDatabase,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    item.deskripsiLokasi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    waktuWibWarga(item.dibuatAtUtc),
                                    style: tema.textTheme.bodySmall,
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

  Widget _kolomTanggal(String label, DateTime? tanggal, VoidCallback pilih) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: pilih,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size(48, 51),
          ),
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: Text(
            tanggal == null ? label : '$label · ${tanggalWarga(tanggal)}',
          ),
        ),
      );
}
class DetailLaporanTersimpan extends StatefulWidget {
  const DetailLaporanTersimpan({
    super.key,
    required this.idLaporan,
    this.idWarga = 1,
    this.namaWarga = '',
    this.bukaAktivitas = false,
  });

  final int idLaporan;
  final int idWarga;
  final String namaWarga;
  final bool bukaAktivitas;

  @override
  State<DetailLaporanTersimpan> createState() => _DetailLaporanTersimpanState();
}

class _DetailLaporanTersimpanState extends State<DetailLaporanTersimpan> {
  LaporanSampah? _laporan;
  List<FotoLaporan> _foto = [];
  List<JenisSampah> _jenis = [];
  String _kategori = '';
  String _namaWarga = '';
  Map<String, Object?>? _verifikasi;
  ({String kode, String status})? _laporanUtama;
  JadwalPengangkutan? _jadwal;
  List<AktivitasPengangkutan> _aktivitas = const [];
  List<KlarifikasiLaporan> _klarifikasi = const [];
  List<Map<String, Object?>> _riwayatStatus = [];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final db = DatabaseHelper.instance;
      final laporan = await db.ambilDetailLaporan(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      if (laporan == null) throw StateError('Laporan tidak ditemukan.');
      final foto = await db.ambilFotoLaporan(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final jenis = await db.ambilJenisSampahLaporan(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final kategori = await db.ambilKategoriAktif();
      final verifikasi = await db.ambilVerifikasiTerakhir(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final klarifikasi = await db.ambilKlarifikasiWarga(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final jadwal = await db.ambilJadwalAktifWarga(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final aktivitas = await db.ambilAktivitasWarga(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final utama = await db.ambilRingkasanLaporanUtama(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final riwayat = await db.ambilRiwayatStatus(
        idLaporan: widget.idLaporan,
        idWarga: widget.idWarga,
      );
      final warga = await db.ambilWargaAktif();
      String? nama;
      for (final item in warga) {
        if (item['id_warga'] == widget.idWarga) nama = item['nama'] as String;
      }
      final pemilik = nama;
      if (pemilik == null) throw StateError('Akun warga tidak tersedia.');
      if (!mounted) return;
      var namaKategori =
          laporan.namaKategoriSaatKirim ?? 'Kategori tidak aktif';
      for (final item in kategori) {
        if (laporan.namaKategoriSaatKirim == null &&
            item.idKategori == laporan.idKategori) {
          namaKategori = item.namaKategori;
        }
      }
      setState(() {
        _laporan = laporan;
        _foto = foto;
        _jenis = jenis;
        _kategori = namaKategori;
        _namaWarga = pemilik;
        _verifikasi = verifikasi;
        _riwayatStatus = riwayat;
        _memuat = false;
        _laporanUtama = utama;
        _jadwal = jadwal;
        _aktivitas = aktivitas;
        _klarifikasi = klarifikasi;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _galat = 'Rincian belum dapat dibaca. Coba muat ulang.';
      });
    }
  }

  Future<void> _bukaKlarifikasi(
    LaporanSampah laporan,
    int idPermintaan,
    String permintaan,
  ) async {
    final terkirim = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KlarifikasiWarga(
          idLaporan: widget.idLaporan,
          idWarga: widget.idWarga,
          idPermintaan: idPermintaan,
          kode: laporan.kodeLaporan ?? 'Laporan',
          permintaan: permintaan,
          titikAwal: TitikLaporan.konfirmasi(
            latitude: laporan.latitude,
            longitude: laporan.longitude,
            kecamatan: laporan.kecamatan,
            metodeLokasi: laporan.metodeLokasi,
          ),
        ),
      ),
    );
    if (!mounted) return;
    await _muat();
    if (mounted && terkirim == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klarifikasi dikirim untuk diperiksa Admin.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final laporan = _laporan;
    final tema = Theme.of(context);
    final idPermintaan = _verifikasi?['id_verifikasi'] as int?;
    final permintaan = _verifikasi?['kebutuhan_klarifikasi'] as String?;
    return KerangkaWarga(
      menuAktif: MenuWarga.riwayat,
      child: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _galat != null || laporan == null
          ? KontenWarga(
              children: [
                const JudulHalamanWarga(judul: 'Detail Laporan'),
                KeadaanGlow(
                  judul: 'Detail belum tersedia',
                  pesan: _galat ?? 'Laporan tidak ditemukan.',
                  icon: Icons.error_outline,
                  aksi: OutlinedButton(
                    onPressed: _muat,
                    child: const Text('Muat ulang'),
                  ),
                ),
              ],
            )
          : DefaultTabController(
              length: 2,
              initialIndex: widget.bukaAktivitas ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: tema.colorScheme.surface,
                    child: const TabBar(
                      tabs: [
                        Tab(text: 'Ringkasan'),
                        Tab(text: 'Penanganan'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        KontenWarga(
                          key: const PageStorageKey('ringkasan-laporan'),
                          children: [
                            JudulHalamanWarga(
                              judul: 'Detail Laporan',
                              deskripsi: laporan.kodeLaporan,
                            ),
                            if (idPermintaan != null &&
                                permintaan != null &&
                                laporan.idVerifikasiTerakhir == idPermintaan &&
                                laporan.statusPenanganan ==
                                    StatusPenanganan.menungguKlarifikasi) ...[
                              _panel(
                                'Permintaan Klarifikasi',
                                Icons.fact_check_outlined,
                                [
                                  SelectableText(permintaan),
                                  if (_klarifikasi.any(
                                    (data) => data.idPermintaan == idPermintaan,
                                  ))
                                    const LabelGlow('Klarifikasi masuk')
                                  else
                                    FilledButton(
                                      onPressed: () => _bukaKlarifikasi(
                                        laporan,
                                        idPermintaan,
                                        permintaan,
                                      ),
                                      child: const Text('Kirim Klarifikasi'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],
                            KisiGlow(
                              kolomMaksimal: 2,
                              lebarMinimum: 330,
                              children: [
                                _panel(
                                  'Informasi laporan',
                                  Icons.description_outlined,
                                  [
                                    LabelGlow(
                                      laporan.statusPenanganan.nilaiDatabase,
                                    ),
                                    _bagian('Pelapor', _namaWarga),
                                    _bagian(
                                      'Dibuat',
                                      waktuWibWarga(laporan.dibuatAtUtc),
                                    ),
                                    _bagian('Kategori', _kategori),
                                    _bagian(
                                      'Deskripsi laporan',
                                      laporan.deskripsiLaporan,
                                    ),
                                    _bagian(
                                      'Jenis sampah',
                                      _jenis.isEmpty
                                          ? 'Tidak tercatat'
                                          : _jenis
                                                .map((item) => item.namaJenis)
                                                .join(', '),
                                    ),
                                    if (_laporanUtama case final utama?)
                                      _bagian(
                                        'Laporan utama',
                                        '${utama.kode} · ${utama.status}',
                                      ),
                                  ],
                                ),
                                _panel(
                                  'Lokasi kejadian',
                                  Icons.location_on_outlined,
                                  [
                                    _bagian('Kecamatan', laporan.kecamatan),
                                    if (laporan.alamatPeta case final alamat?)
                                      _bagian('Detail lokasi peta', alamat),
                                    _bagian('Patokan', laporan.deskripsiLokasi),
                                    _bagian(
                                      'Koordinat',
                                      '${laporan.latitude.toStringAsFixed(6)}, '
                                          '${laporan.longitude.toStringAsFixed(6)}',
                                    ),
                                    _bagian(
                                      'Sumber titik lokasi',
                                      laporan.metodeLokasi ==
                                              MetodeLokasi.perangkat
                                          ? 'Lokasi perangkat'
                                          : 'Pilihan pada peta',
                                    ),
                                    _bagian(
                                      'Lokasi dikonfirmasi',
                                      waktuWibWarga(
                                        laporan.lokasiDikonfirmasiAtUtc,
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        height: 240,
                                        child: PetaLaporan(
                                          pusatAwal: LatLng(
                                            laporan.latitude,
                                            laporan.longitude,
                                          ),
                                          titik: LatLng(
                                            laporan.latitude,
                                            laporan.longitude,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _panel(
                              'Foto kondisi sampah',
                              Icons.photo_library_outlined,
                              [
                                Text(
                                  '${_foto.length} foto tersimpan',
                                  style: tema.textTheme.bodySmall,
                                ),
                                if (_foto.isNotEmpty)
                                  KisiGlow(
                                    lebarMinimum: 170,
                                    children: [
                                      for (final foto in _foto)
                                        Card(
                                          child: InkWell(
                                            onTap: () => _lihatFoto(foto),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Image.memory(
                                                  Uint8List.fromList(
                                                    foto.dataFoto,
                                                  ),
                                                  height: 142,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 480,
                                                  semanticLabel:
                                                      foto.namaBerkas,
                                                  errorBuilder:
                                                      (
                                                        _,
                                                        error,
                                                        stackTrace,
                                                      ) => const SizedBox(
                                                        height: 142,
                                                        child: Center(
                                                          child: Text(
                                                            'Pratinjau tidak tersedia',
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: Text(
                                                    foto.namaBerkas,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        KontenWarga(
                          key: const PageStorageKey('penanganan-laporan'),
                          children: [
                            JudulHalamanWarga(
                              judul: 'Penanganan Laporan',
                              deskripsi: laporan.kodeLaporan,
                            ),
                            KisiGlow(
                              kolomMaksimal: 2,
                              lebarMinimum: 325,
                              children: [
                                _panel('Verifikasi', Icons.fact_check_outlined, [
                                  if (_verifikasi case final verifikasi?) ...[
                                    LabelGlow('${verifikasi['hasil_tampil']}'),
                                    SelectableText('${verifikasi['alasan']}'),
                                    Text(
                                      'Pemeriksa · ${verifikasi['nama_admin']}',
                                    ),
                                    Text(
                                      waktuWibWarga(
                                        DateTime.parse(
                                          verifikasi['diperiksa_at_utc']
                                              as String,
                                        ),
                                      ),
                                      style: tema.textTheme.bodySmall,
                                    ),
                                  ] else
                                    const Text(
                                      'Laporan menunggu peninjauan admin.',
                                    ),
                                  if (laporan.diterimaAtUtc case final waktu?)
                                    _bagian('Diterima', waktuWibWarga(waktu)),
                                  if (laporan.selesaiAtUtc case final waktu?)
                                    _bagian('Selesai', waktuWibWarga(waktu)),
                                ]),
                                _panel(
                                  'Jadwal Pengangkutan',
                                  Icons.event_outlined,
                                  [
                                    if (_jadwal case final jadwal?) ...[
                                      LabelGlow(jadwal.status),
                                      _bagian(
                                        'Mulai',
                                        waktuWibWarga(jadwal.mulaiUtc),
                                      ),
                                      _bagian(
                                        'Perkiraan selesai',
                                        waktuWibWarga(jadwal.selesaiUtc),
                                      ),
                                    ] else
                                      const Text('Jadwal belum tersedia.'),
                                  ],
                                ),
                              ],
                            ),
                            for (final data in _klarifikasi) ...[
                              const SizedBox(height: 10),
                              KartuRiwayatKlarifikasi(klarifikasi: data),
                            ],
                            const SizedBox(height: 20),
                            Text(
                              'Aktivitas pengangkutan',
                              style: tema.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            if (_aktivitas.isEmpty)
                              const PanelGlow(
                                child: Text(
                                  'Belum ada aktivitas pengangkutan.',
                                ),
                              ),
                            for (final aktivitas in _aktivitas)
                              KartuAktivitasPengangkutan(aktivitas: aktivitas),
                            const SizedBox(height: 20),
                            _panel('Perkembangan laporan', Icons.timeline, [
                              if (_riwayatStatus.isEmpty)
                                const Text('Belum ada perubahan status.'),
                              for (final item in _riwayatStatus)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.adjust),
                                  title: Text(
                                    "${item['status_lama'] ?? 'Laporan dikirim'} → ${item['status_baru']}",
                                  ),
                                  subtitle: Text(
                                    waktuWibWarga(
                                      DateTime.parse(
                                        item['diubah_at_utc'] as String,
                                      ),
                                    ),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _lihatFoto(FotoLaporan foto) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(foto.namaBerkas),
      content: SizedBox(
        width: 660,
        height: (MediaQuery.sizeOf(context).height * .55)
            .clamp(120, 420)
            .toDouble(),
        child: InteractiveViewer(
          child: Image.memory(
            Uint8List.fromList(foto.dataFoto),
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) =>
                const Center(child: Text('Foto tidak tersedia.')),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup foto'),
        ),
      ],
    ),
  );

  Widget _panel(String judul, IconData icon, List<Widget> isi) => PanelGlow(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 11,
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Expanded(
              child: Text(
                judul,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        ...isi,
      ],
    ),
  );

  Widget _bagian(String judul, String isi) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 3,
    children: [
      Text(judul, style: Theme.of(context).textTheme.bodySmall),
      SelectableText(isi),
    ],
  );
}