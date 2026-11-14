import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';

import '../db/database_helper.dart';
import '../models/klarifikasi_laporan.dart';
import '../models/laporan_sampah.dart';
import '../models/verifikasi_laporan.dart';
import '../services/sesi_akun.dart';
import '../services/pemeriksaan_foto.dart';
import '../widgets/kerangka_warga.dart';
import 'jadwal_operasional.dart';
import 'klarifikasi_warga.dart';
import 'pilih_lokasi_laporan.dart';

class PemeriksaanAdmin extends StatefulWidget {
  const PemeriksaanAdmin({
    super.key,
    required this.akun,
    required this.idLaporan,
    required this.onBerubah,
  });

  final AkunAktif akun;
  final int idLaporan;
  final VoidCallback onBerubah;

  @override
  State<PemeriksaanAdmin> createState() => _PemeriksaanAdminState();
}

class _PemeriksaanAdminState extends State<PemeriksaanAdmin> {
  final _db = DatabaseHelper.instance;
  final _form = GlobalKey<FormState>();
  final _kesimpulan = TextEditingController();
  final _kebutuhan = TextEditingController();
  Future<List<PasanganFoto>>? _pasangan;
  late Future<BahanPemeriksaan?> _bahan;
  HasilVerifikasi? _hasil;
  int? _idLokasiPilihan;
  bool _menyimpan = false;
  bool _perluMuatUlang = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _bahan = _ambil();
  }

  Future<BahanPemeriksaan?> _ambil() async {
    final bahan = await _db.ambilBahanPemeriksaan(
      idAdmin: widget.akun.id,
      idLaporan: widget.idLaporan,
    );
    if (bahan != null && mounted) {
      _pasangan =
          PemeriksaanFoto.bandingkan(
            bahan.foto.map((bukti) => bukti.foto).toList(),
          ).then<List<PasanganFoto>>(
            (data) => data,
            onError: (Object _) => const <PasanganFoto>[],
          );
    }
    return bahan;
  }

  @override
  void dispose() {
    _kesimpulan.dispose();
    _kebutuhan.dispose();
    super.dispose();
  }

  void _muatUlang() {
    setState(() {
      _bahan = _ambil();
      _perluMuatUlang = false;
      _idLokasiPilihan = null;
      _galat = null;
    });
  }

  Future<void> _simpan(BahanPemeriksaan bahan) async {
    if (_menyimpan ||
        _perluMuatUlang ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final hasil = _hasil;
    if (hasil == null || !identical(SesiAkun.aktif, widget.akun)) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    try {
      await _db.simpanVerifikasi(
        idAdmin: widget.akun.id,
        idLaporan: widget.idLaporan,
        versi: bahan.versi,
        hasil: hasil,
        kesimpulan: _kesimpulan.text,
        kebutuhanKlarifikasi: _kebutuhan.text,
        idUsulanLokasi: hasil == HasilVerifikasi.sesuai && _idLokasiPilihan != 0
            ? _idLokasiPilihan
            : null,
      );
      if (!mounted) return;
      _muatUlang();
      widget.onBerubah();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keputusan tersimpan · ${hasil.statusBaru}')),
      );
    } on GalatVerifikasi catch (galat) {
      if (!mounted) return;
      setState(() {
        _galat = galat.pesan;
        _perluMuatUlang = galat.muatUlang;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galat = 'Keputusan belum tersimpan. Coba simpan kembali.';
      });
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BahanPemeriksaan?>(
      future: _bahan,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(
            semanticsLabel: 'Memuat detail laporan',
          );
        }
        final bahan = snapshot.data;
        if (snapshot.hasError || bahan == null) {
          return KeadaanGlow(
            judul: 'Detail laporan belum dapat dibuka',
            pesan: 'Muat ulang untuk memeriksa laporan.',
            icon: Icons.error_outline,
            aksi: OutlinedButton(
              onPressed: _muatUlang,
              child: const Text('Muat ulang'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            JudulHalamanWarga(
              judul: 'Detail laporan',
              deskripsi: bahan.laporan.kodeLaporan,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                LabelGlow(bahan.laporan.statusPenanganan.nilaiDatabase),
                if (bahan.keputusan.isNotEmpty)
                  LabelGlow('${bahan.keputusan.first['hasil_tampil']}'),
              ],
            ),
            ..._bukti(bahan),
          ],
        );
      },
    );
  }

  Future<void> _bukaJadwal(BahanPemeriksaan bahan) async {
    final disimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JadwalAdmin(
          akun: widget.akun,
          idLaporan: widget.idLaporan,
          kodeLaporan: bahan.laporan.kodeLaporan ?? 'Laporan',
          versiLaporan: bahan.versi,
        ),
      ),
    );
    if (!mounted) return;
    _muatUlang();
    if (disimpan == true) {
      widget.onBerubah();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal dan penugasan tersimpan.')),
      );
    }
  }

  KlarifikasiLaporan? _usulanLokasi(BahanPemeriksaan bahan) {
    for (final data in bahan.klarifikasi) {
      if (data.idPermintaan == bahan.laporan.idVerifikasiTerakhir &&
          data.idTindakLanjut == null &&
          data.lokasiUsulan != null) {
        return data;
      }
    }
    return null;
  }

  List<Widget> _bukti(BahanPemeriksaan bahan) {
    final laporan = bahan.laporan;
    final titik = LatLng(laporan.latitude, laporan.longitude);
    final status = laporan.statusPenanganan.nilaiDatabase;
    final bisaTinjau =
        status == HasilVerifikasi.belumDapatDipastikan.statusBaru &&
        bahan.klarifikasi.any(
          (data) =>
              data.idPermintaan == laporan.idVerifikasiTerakhir &&
              data.idTindakLanjut == null,
        );
    final usulan = _usulanLokasi(bahan)?.lokasiUsulan;
    final valid =
        bahan.keputusan.isNotEmpty &&
        HasilVerifikasi.sesuai.cocok(bahan.keputusan.first['hasil_tampil']);
    return [
      _Panel(
        judul: 'Deskripsi, kategori, dan jenis sampah',
        children: [
          Text(bahan.kategori),
          SelectableText(laporan.deskripsiLaporan),
          Text(bahan.jenis.map((item) => item.namaJenis).join(', ')),
        ],
      ),
      _Panel(
        judul: 'Foto asli',
        children: [
          if (bahan.foto.isEmpty) const Text('Foto tidak tersedia.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final bukti in bahan.foto)
                _FotoPemeriksaan(
                  nama: bukti.foto.namaBerkas,
                  bytes: Uint8List.fromList(bukti.foto.dataFoto),
                  diunggah: bukti.diunggah,
                ),
            ],
          ),
        ],
      ),
      _Panel(
        judul: 'Lokasi kejadian dan waktu pengiriman',
        children: [
          if (laporan.alamatPeta case final alamat?) SelectableText(alamat),
          SelectableText('${laporan.kecamatan} · ${laporan.deskripsiLokasi}'),
          SelectableText(
            '${laporan.latitude.toStringAsFixed(6)}, '
            '${laporan.longitude.toStringAsFixed(6)}',
          ),
          Text(
            laporan.metodeLokasi == MetodeLokasi.perangkat
                ? 'Sumber pin · Lokasi perangkat'
                : 'Sumber pin · Titik pada peta',
          ),
          Text(
            'Lokasi dikonfirmasi · ${waktuWibWarga(laporan.lokasiDikonfirmasiAtUtc)}',
          ),
          Text('Laporan tersimpan · ${waktuWibWarga(laporan.dibuatAtUtc)}'),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PetaLaporan(pusatAwal: titik, titik: titik),
            ),
          ),
        ],
      ),
      if (bahan.klarifikasi.isNotEmpty) ...[
        for (final data in bahan.klarifikasi)
          KartuRiwayatKlarifikasi(klarifikasi: data),
        if (bisaTinjau && usulan != null)
          _Panel(
            judul: 'Peta usulan lokasi terbaru',
            children: [
              if (usulan.alamatPeta case final alamat?) Text(alamat),
              Text('${usulan.kecamatan} · ${usulan.patokan}'),
              SizedBox(
                height: 260,
                child: PetaLaporan(
                  pusatAwal: LatLng(usulan.latitude, usulan.longitude),
                  titik: LatLng(usulan.latitude, usulan.longitude),
                ),
              ),
            ],
          ),
      ],
      _Panel(
        judul: 'Hasil pemeriksaan foto',
        children: [
          if (bahan.foto.length != 3)
            Text('Laporan ini memiliki ${bahan.foto.length} foto.'),
          FutureBuilder<List<PasanganFoto>>(
            future: _pasangan,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final hasil = snapshot.data;
              if (hasil == null || hasil.isEmpty) {
                return const Text('Perbandingan foto tidak tersedia.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in hasil)
                    Text(
                      'Foto ${item.pertama} dan ${item.kedua} · '
                      '${item.identik ? 'Identik' : 'Berbeda secara piksel'}'
                      ' · Selisih pola ${item.jarakPola}/64',
                    ),
                ],
              );
            },
          ),
        ],
      ),
      if (laporan.statusPenanganan == StatusPenanganan.baru || bisaTinjau)
        ..._keputusan(bahan)
      else if (status == HasilVerifikasi.belumDapatDipastikan.statusBaru)
        const _Panel(
          judul: 'Menunggu jawaban Warga',
          children: [
            Text('Klarifikasi akan muncul pada laporan ini setelah dikirim.'),
          ],
        ),
      if (valid && status == 'Diterima')
        FilledButton.icon(
          onPressed: () => _bukaJadwal(bahan),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Jadwalkan Pengangkutan'),
        ),
      if (valid && status == 'Diproses')
        OutlinedButton.icon(
          onPressed: () => _bukaJadwal(bahan),
          icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Lihat Jadwal Pengangkutan'),
        ),
      if (bahan.keputusan.isNotEmpty) ...[
        for (final item in bahan.keputusan)
          _Panel(
            judul: 'Riwayat keputusan · ${item['hasil_tampil']}',
            children: [
              Text(
                '${item['nama_admin']} · '
                '${waktuWibWarga(DateTime.parse(item['diperiksa_at_utc'] as String))}',
              ),
              Text('Alasan · ${item['alasan']}'),
              if ((item['catatan'] as String).isNotEmpty)
                Text('Catatan · ${item['catatan']}'),
              if (item['kebutuhan_klarifikasi'] != null)
                Text(
                  'Kebutuhan klarifikasi · ${item['kebutuhan_klarifikasi']}',
                ),
              if (item['kode_utama'] != null)
                Text('Laporan utama · ${item['kode_utama']}'),
              for (final baris in bahan.checklist)
                if (baris['id_verifikasi'] == item['id_verifikasi'])
                  Text(
                    '${IndikatorVerifikasi.values.byName(baris['indikator'] as String).label}'
                    ' · ${baris['hasil']}'
                    '${(baris['temuan'] as String).isEmpty ? '' : '\n${baris['temuan']}'}',
                  ),
            ],
          ),
      ],
      for (final aktivitas in bahan.aktivitas)
        KartuAktivitasPengangkutan(aktivitas: aktivitas),
      _Panel(
        judul: 'Perkembangan laporan',
        children: [
          for (final item in bahan.riwayatStatus)
            Text(
              '${item['status_lama'] ?? 'Laporan dikirim'} → ${item['status_baru']}\n'
              '${waktuWibWarga(DateTime.parse(item['diubah_at_utc'] as String))}',
            ),
        ],
      ),
    ];
  }

  List<Widget> _keputusan(BahanPemeriksaan bahan) {
    final usulan = _usulanLokasi(bahan);
    return [
      Form(
        key: _form,
        child: _Panel(
          judul: 'Kesimpulan dan keputusan Admin',
          children: [
            Text('Pemeriksa · ${widget.akun.nama}'),
            _kolom(_kesimpulan, 'Kesimpulan', wajib: true),
            DropdownButtonFormField<HasilVerifikasi>(
              initialValue: _hasil,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hasil verifikasi'),
              items: [
                for (final hasil in HasilVerifikasi.values)
                  DropdownMenuItem(value: hasil, child: Text(hasil.label)),
              ],
              onChanged: _menyimpan
                  ? null
                  : (hasil) => setState(() => _hasil = hasil),
              validator: (hasil) =>
                  hasil == null ? 'Pilih hasil verifikasi.' : null,
            ),
            if (_hasil case final hasil?)
              Text('Status setelah simpan · ${hasil.statusBaru}'),
            if (_hasil == HasilVerifikasi.sesuai && usulan != null)
              DropdownButtonFormField<int>(
                initialValue: _idLokasiPilihan,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Titik yang disetujui',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Titik laporan saat ini'),
                  ),
                  DropdownMenuItem(
                    value: usulan.id,
                    child: const Text('Usulan terbaru dari Warga'),
                  ),
                ],
                onChanged: _menyimpan
                    ? null
                    : (id) => setState(() => _idLokasiPilihan = id),
                validator: (id) => id == null
                    ? 'Pilih titik yang akan dipakai Petugas.'
                    : null,
              ),
            if (_hasil == HasilVerifikasi.belumDapatDipastikan)
              _kolom(
                _kebutuhan,
                'Informasi yang perlu dilengkapi warga',
                wajib: true,
              ),
          ],
        ),
      ),
      if (_galat != null) _pesanGalat(),
      if (_perluMuatUlang)
        OutlinedButton(
          onPressed: _muatUlang,
          child: const Text('Muat laporan terbaru'),
        )
      else
        FilledButton(
          onPressed: _menyimpan ? null : () => _simpan(bahan),
          child: Text(_menyimpan ? 'Menyimpan…' : 'Simpan Keputusan'),
        ),
    ];
  }

  Widget _kolom(
    TextEditingController controller,
    String label, {
    bool wajib = false,
  }) => TextFormField(
    controller: controller,
    enabled: !_menyimpan,
    maxLines: 3,
    maxLength: 2000,
    decoration: InputDecoration(labelText: label),
    validator: (teks) => wajib && (teks?.trim().isEmpty ?? true)
        ? 'Bagian ini wajib diisi.'
        : null,
  );

  Widget _pesanGalat() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      _galat!,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.judul, required this.children});

  final String judul;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(judul, style: Theme.of(context).textTheme.titleMedium),
          ...children,
        ],
      ),
    ),
  );
}

class _FotoPemeriksaan extends StatelessWidget {
  const _FotoPemeriksaan({
    required this.nama,
    required this.bytes,
    required this.diunggah,
  });

  final String nama;
  final Uint8List bytes;
  final DateTime diunggah;

  void _buka(BuildContext context) {
    final metadata = _bacaExif(bytes);
    final waktuFoto = metadata?.exifIfd[0x9003]?.toString().trim();
    final zona = metadata?.exifIfd[0x9011]?.toString().trim();
    final gps = metadata?.gpsIfd;
    final latitude = _derajat(gps?[2], gps?[1]?.toString(), 'N', 'S', 90);
    final longitude = _derajat(gps?[4], gps?[3]?.toString(), 'E', 'W', 180);
    final koordinat = latitude == null || longitude == null
        ? 'Belum dapat dinilai'
        : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    final waktu = waktuFoto == null || waktuFoto.isEmpty
        ? 'Belum dapat dinilai'
        : '$waktuFoto · ${zona == null || zona.isEmpty ? 'zona tidak tercatat' : zona}';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto asli dan metadata'),
        scrollable: true,
        content: SizedBox(
          width: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              SizedBox(
                height: 280,
                child: InteractiveViewer(
                  child: Center(child: _gambar(BoxFit.contain)),
                ),
              ),
              SelectableText(nama),
              Text('Foto tersimpan · ${waktuWibWarga(diunggah)}'),
              Text('Waktu pengambilan (EXIF) · $waktu'),
              Text('Koordinat kamera (EXIF) · $koordinat'),
              const Text(
                'Metadata foto dibaca sebagai bukti pendukung. '
                'Bandingkan dengan titik kejadian dan keterangan warga.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  static img.ExifData? _bacaExif(Uint8List bytes) {
    try {
      if (bytes.length < 8) return null;
      if (bytes[0] == 0xff && bytes[1] == 0xd8) return img.decodeJpgExif(bytes);
      const tandaPng = [137, 80, 78, 71, 13, 10, 26, 10];
      for (var indeks = 0; indeks < tandaPng.length; indeks++) {
        if (bytes[indeks] != tandaPng[indeks]) return null;
      }
      final data = ByteData.sublistView(bytes);
      var posisi = 8;
      while (posisi + 12 <= bytes.length) {
        final panjang = data.getUint32(posisi);
        final awal = posisi + 8;
        final akhir = awal + panjang;
        if (akhir + 4 > bytes.length) return null;
        final tipe = data.getUint32(posisi + 4);
        if (tipe == 0x65584966) {
          // eXIf
          return img.ExifData.fromInputBuffer(
            img.InputBuffer(Uint8List.sublistView(bytes, awal, akhir)),
          );
        }
        if (tipe == 0x49454e44) return null; // IEND
        posisi = akhir + 4;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static double? _derajat(
    img.IfdValue? data,
    String? arah,
    String positif,
    String negatif,
    int batas,
  ) {
    final referensi = arah?.trim().toUpperCase();
    if (data == null ||
        data.length != 3 ||
        (referensi != positif && referensi != negatif)) {
      return null;
    }
    try {
      final derajat = data.toDouble(0);
      final menit = data.toDouble(1);
      final detik = data.toDouble(2);
      if (derajat < 0 || menit < 0 || menit >= 60 || detik < 0 || detik >= 60) {
        return null;
      }
      final nilai = derajat + menit / 60 + detik / 3600;
      if (!nilai.isFinite || nilai > batas) return null;
      return referensi == negatif ? -nilai : nilai;
    } catch (_) {
      return null;
    }
  }

  Widget _gambar(BoxFit fit) => Image.memory(
    bytes,
    fit: fit,
    errorBuilder: (_, error, stackTrace) =>
        const Center(child: Text('Pratinjau foto tidak dapat dibuka')),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 145,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _gambar(BoxFit.cover),
          ),
        ),
        Text(nama, overflow: TextOverflow.ellipsis),
        OutlinedButton.icon(
          onPressed: () => _buka(context),
          icon: const Icon(Icons.image_search_outlined, size: 18),
          label: const Text('Buka Foto dan EXIF'),
        ),
      ],
    ),
  );
}