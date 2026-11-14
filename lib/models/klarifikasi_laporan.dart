import 'dart:convert';
import 'dart:typed_data';

import 'laporan_sampah.dart';
import 'titik_laporan.dart';

class LokasiKlarifikasi {
  const LokasiKlarifikasi({
    required this.latitude,
    required this.longitude,
    required this.kecamatan,
    this.alamatPeta,
    required this.patokan,
    required this.metode,
    required this.dikonfirmasiUtc,
  });

  factory LokasiKlarifikasi.usulan(TitikLaporan titik, String patokan) =>
      LokasiKlarifikasi(
        latitude: titik.latitude,
        longitude: titik.longitude,
        kecamatan: titik.kecamatan,
        alamatPeta: titik.alamatPeta,
        patokan: patokan.trim(),
        metode: titik.metodeLokasi == MetodeLokasi.perangkat
            ? 'perangkat'
            : 'peta',
        dikonfirmasiUtc: titik.dikonfirmasiAtUtc.toUtc().toIso8601String(),
      );

  factory LokasiKlarifikasi.fromMap(Map<String, Object?> row) =>
      LokasiKlarifikasi(
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        kecamatan: row['kecamatan'] as String,
        alamatPeta: row['alamat_peta'] as String?,
        patokan: row['deskripsi_lokasi'] as String,
        metode: row['metode_lokasi'] as String,
        dikonfirmasiUtc: row['lokasi_dikonfirmasi_at_utc'] as String,
      );

  static LokasiKlarifikasi? dariJson(Object? teks) {
    if (teks == null) return null;
    return LokasiKlarifikasi.fromMap(
      jsonDecode(teks as String) as Map<String, Object?>,
    );
  }

  Map<String, Object?> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'kecamatan': kecamatan,
    'alamat_peta': alamatPeta,
    'deskripsi_lokasi': patokan,
    'metode_lokasi': metode,
    'lokasi_dikonfirmasi_at_utc': dikonfirmasiUtc,
  };

  final double latitude;
  final double longitude;
  final String kecamatan;
  final String? alamatPeta;
  final String patokan;
  final String metode;
  final String dikonfirmasiUtc;
}

typedef BuktiKlarifikasi = ({String nama, Uint8List bytes});

class KlarifikasiLaporan {
  KlarifikasiLaporan.fromMap(
    Map<String, Object?> row,
    List<BuktiKlarifikasi> bukti,
  ) : id = row['id_klarifikasi'] as int,
      idPermintaan = row['id_verifikasi_permintaan'] as int,
      idTindakLanjut = row['id_verifikasi_tindak_lanjut'] as int?,
      permintaan = row['kebutuhan_klarifikasi'] as String,
      penjelasan = row['penjelasan'] as String,
      dikirimUtc = DateTime.parse(row['dibuat_at_utc'] as String),
      hasilTindakLanjut = row['hasil_tindak_lanjut'] as String?,
      lokasiAwal = LokasiKlarifikasi.dariJson(row['lokasi_awal']),
      lokasiUsulan = LokasiKlarifikasi.dariJson(row['lokasi_usulan']),
      foto = List<BuktiKlarifikasi>.unmodifiable(bukti);

  final int id;
  final int idPermintaan;
  final int? idTindakLanjut;
  final String permintaan;
  final String penjelasan;
  final DateTime dikirimUtc;
  final String? hasilTindakLanjut;
  final LokasiKlarifikasi? lokasiAwal;
  final LokasiKlarifikasi? lokasiUsulan;
  final List<BuktiKlarifikasi> foto;
}

class GalatKlarifikasi implements Exception {
  const GalatKlarifikasi(this.pesan);
  final String pesan;
}