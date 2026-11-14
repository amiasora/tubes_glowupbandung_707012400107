class KategoriLaporan {
  const KategoriLaporan(this.idKategori, this.namaKategori, this.aktif);

  factory KategoriLaporan.fromMap(Map<String, Object?> row) => KategoriLaporan(
    row['id_kategori'] as int,
    row['nama_kategori'] as String,
    row['aktif'] == 1,
  );

  final int idKategori;
  final String namaKategori;
  final bool aktif;
}

class JenisSampah {
  const JenisSampah(this.idJenis, this.namaJenis, this.aktif);

  factory JenisSampah.fromMap(Map<String, Object?> row) => JenisSampah(
    row['id_jenis'] as int,
    row['nama_jenis'] as String,
    row['aktif'] == 1,
  );

  final int idJenis;
  final String namaJenis;
  final bool aktif;
}