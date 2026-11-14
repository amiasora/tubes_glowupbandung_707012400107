enum MetodeLokasi { perangkat, peta }

enum StatusPenanganan {
  baru('Baru'),
  diterima('Diterima'),
  diproses('Diproses'),
  menungguKlarifikasi('Menunggu klarifikasi'),
  ditutupSebagaiDuplikat('Ditutup sebagai duplikat'),
  ditolak('Ditolak'),
  selesai('Selesai');

  const StatusPenanganan(this.nilaiDatabase);
  final String nilaiDatabase;
}

class LaporanSampah {
  const LaporanSampah({
    this.idLaporan,
    this.kodeLaporan,
    required this.idWarga,
    required this.idKategori,
    this.namaKategoriSaatKirim,
    required this.deskripsiLaporan,
    required this.deskripsiLokasi,
    required this.kecamatan,
    this.alamatPeta,
    required this.latitude,
    required this.longitude,
    required this.metodeLokasi,
    required this.lokasiDikonfirmasiAtUtc,
    required this.dibuatAtUtc,
    required this.kunciKirim,
    this.statusPenanganan = StatusPenanganan.baru,
    this.diterimaAtUtc,
    this.selesaiAtUtc,
    this.idLaporanUtama,
    this.idVerifikasiTerakhir,
  });

  factory LaporanSampah.fromMap(Map<String, Object?> row) => LaporanSampah(
    idLaporan: row['id_laporan'] as int,
    kodeLaporan: row['kode_laporan'] as String,
    idWarga: row['id_warga'] as int,
    idKategori: row['id_kategori'] as int,
    namaKategoriSaatKirim: row['nama_kategori_saat_kirim'] as String?,
    deskripsiLaporan: row['deskripsi_laporan'] as String,
    deskripsiLokasi: row['deskripsi_lokasi'] as String,
    kecamatan: row['kecamatan'] as String,
    alamatPeta: row['alamat_peta'] as String?,
    latitude: (row['latitude'] as num).toDouble(),
    longitude: (row['longitude'] as num).toDouble(),
    metodeLokasi: MetodeLokasi.values.byName(row['metode_lokasi'] as String),
    lokasiDikonfirmasiAtUtc: DateTime.parse(
      row['lokasi_dikonfirmasi_at_utc'] as String,
    ),
    dibuatAtUtc: DateTime.parse(row['dibuat_at_utc'] as String),
    kunciKirim: row['kunci_kirim'] as String,
    statusPenanganan: StatusPenanganan.values.firstWhere(
      (status) => status.nilaiDatabase == row['status_penanganan'],
    ),
    diterimaAtUtc: DateTime.tryParse(row['diterima_at_utc'] as String? ?? ''),
    selesaiAtUtc: DateTime.tryParse(row['selesai_at_utc'] as String? ?? ''),
    idLaporanUtama: row['id_laporan_utama'] as int?,
    idVerifikasiTerakhir: row['id_verifikasi_terakhir'] as int?,
  );

  Map<String, Object?> toMap() => {
    'id_warga': idWarga,
    'id_kategori': idKategori,
    'deskripsi_laporan': deskripsiLaporan,
    'deskripsi_lokasi': deskripsiLokasi,
    'kecamatan': kecamatan,
    'alamat_peta': alamatPeta,
    'latitude': latitude,
    'longitude': longitude,
    'metode_lokasi': metodeLokasi.name,
    'lokasi_dikonfirmasi_at_utc': lokasiDikonfirmasiAtUtc
        .toUtc()
        .toIso8601String(),
    'kunci_kirim': kunciKirim,
  };

  final int? idLaporan;
  final String? kodeLaporan;
  final int idWarga;
  final int idKategori;
  final String? namaKategoriSaatKirim;
  final String deskripsiLaporan;
  final String deskripsiLokasi;
  final String kecamatan;
  final String? alamatPeta;
  final double latitude;
  final double longitude;
  final MetodeLokasi metodeLokasi;
  final DateTime lokasiDikonfirmasiAtUtc;
  final DateTime dibuatAtUtc;
  final String kunciKirim;
  final StatusPenanganan statusPenanganan;
  final DateTime? diterimaAtUtc;
  final DateTime? selesaiAtUtc;
  final int? idLaporanUtama;
  final int? idVerifikasiTerakhir;
}