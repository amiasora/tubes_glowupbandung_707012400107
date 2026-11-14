class JadwalPengangkutan {
  const JadwalPengangkutan({
    required this.id,
    required this.mulaiUtc,
    required this.selesaiUtc,
    required this.status,
  });

  factory JadwalPengangkutan.fromMap(Map<String, Object?> row) =>
      JadwalPengangkutan(
        id: row['id_jadwal'] as int,
        mulaiUtc: DateTime.parse(row['mulai_at_utc'] as String),
        selesaiUtc: DateTime.parse(row['estimasi_selesai_at_utc'] as String),
        status: row['status_jadwal'] as String,
      );

  final int id;
  final DateTime mulaiUtc;
  final DateTime selesaiUtc;
  final String status;
}

class PenugasanPetugas {
  const PenugasanPetugas({
    required this.jadwal,
    required this.kodeLaporan,
    required this.peranTugas,
    required this.kecamatan,
    required this.lokasi,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
    required this.catatan,
    required this.belumDibaca,
  });

  factory PenugasanPetugas.fromMap(Map<String, Object?> row) =>
      PenugasanPetugas(
        jadwal: JadwalPengangkutan.fromMap(row),
        kodeLaporan: row['kode_laporan'] as String,
        peranTugas: row['peran_tugas'] as String,
        kecamatan: row['kecamatan'] as String,
        lokasi: row['deskripsi_lokasi'] as String,
        deskripsi: row['deskripsi_laporan'] as String,
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        catatan: row['catatan'] as String,
        belumDibaca: row['belum_dibaca'] == 1,
      );

  final JadwalPengangkutan jadwal;
  final String kodeLaporan;
  final String peranTugas;
  final String kecamatan;
  final String lokasi;
  final String deskripsi;
  final double latitude;
  final double longitude;
  final String catatan;
  final bool belumDibaca;
}

class GalatJadwal implements Exception {
  const GalatJadwal(this.pesan);
  final String pesan;
}