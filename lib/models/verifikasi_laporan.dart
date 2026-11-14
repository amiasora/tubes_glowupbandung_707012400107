import 'foto_laporan.dart';
import 'klarifikasi_laporan.dart';
import 'laporan_sampah.dart';
import 'penanganan_laporan.dart';
import 'referensi_laporan.dart';

enum HasilVerifikasi {
  sesuai('Sesuai', 'Diterima', 'Valid'),
  tidakSesuai('Tidak sesuai', 'Ditolak', 'Tidak valid'),
  belumDapatDipastikan(
    'Belum dapat dipastikan',
    'Menunggu klarifikasi',
    'Perlu verifikasi',
  );

  const HasilVerifikasi(this.label, this.statusBaru, this.nilaiLama);

  final String label;
  final String statusBaru;
  final String nilaiLama;

  bool cocok(Object? nilai) => nilai == label || nilai == nilaiLama;
}

enum IndikatorVerifikasi {
  foto('Foto', 'Bandingkan objek dan kondisi sampah pada foto dengan laporan.'),
  deskripsi(
    'Deskripsi',
    'Periksa apakah deskripsi menjelaskan kejadian dan jenis sampah.',
  ),
  lokasi('Lokasi', 'Bandingkan pin, kecamatan, patokan dan bukti foto.'),
  waktu('Waktu', 'Pisahkan waktu pengiriman dari waktu pengambilan foto.'),
  duplikasi(
    'Duplikasi kejadian',
    'Bandingkan lokasi, waktu dan konteks laporan sebelumnya.',
  ),
  sumber(
    'Sumber foto',
    'Catat ciri atau sumber pembanding yang bisa ditunjukkan.',
  );

  const IndikatorVerifikasi(this.label, this.petunjuk);

  final String label;
  final String petunjuk;
}

typedef BahanPemeriksaan = ({
  LaporanSampah laporan,
  int versi,
  String kategori,
  List<({FotoLaporan foto, DateTime diunggah})> foto,
  List<JenisSampah> jenis,
  List<Map<String, Object?>> riwayatStatus,
  List<Map<String, Object?>> keputusan,
  List<Map<String, Object?>> checklist,
  List<KlarifikasiLaporan> klarifikasi,
  List<AktivitasPengangkutan> aktivitas,
});

class GalatVerifikasi implements Exception {
  const GalatVerifikasi(this.pesan, {this.muatUlang = false});

  final String pesan;
  final bool muatUlang;
}