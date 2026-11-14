class NotifikasiLaporan {
  const NotifikasiLaporan({
    required this.idNotifikasi,
    required this.idWarga,
    required this.idLaporan,
    required this.kodeLaporan,
    required this.jenis,
    required this.judul,
    required this.ringkasan,
    required this.dibuatAtUtc,
    this.dibacaAtUtc,
  });

  final int idNotifikasi;
  final int idWarga;
  final int idLaporan;
  final String kodeLaporan;
  final String jenis;
  final String judul;
  final String ringkasan;
  final DateTime dibuatAtUtc;
  final DateTime? dibacaAtUtc;
  bool get sudahDibaca => dibacaAtUtc != null;

  factory NotifikasiLaporan.fromMap(Map<String, Object?> map) =>
      NotifikasiLaporan(
        idNotifikasi: map['id_notifikasi'] as int,
        idWarga: map['id_warga'] as int,
        idLaporan: map['id_laporan'] as int,
        kodeLaporan: map['kode_laporan'] as String,
        jenis: map['jenis'] as String,
        judul: map['judul'] as String,
        ringkasan: map['ringkasan'] as String,
        dibuatAtUtc: DateTime.parse(map['dibuat_at_utc'] as String).toUtc(),
        dibacaAtUtc: map['dibaca_at_utc'] == null
            ? null
            : DateTime.parse(map['dibaca_at_utc'] as String).toUtc(),
      );
}