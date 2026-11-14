import 'laporan_sampah.dart';

class TitikLaporan {
  const TitikLaporan._({
    required this.latitude,
    required this.longitude,
    required this.kecamatan,
    this.alamatPeta,
    required this.metodeLokasi,
    required this.dikonfirmasiAtUtc,
  });

  final double latitude;
  final double longitude;
  final String kecamatan;
  final String? alamatPeta;
  final MetodeLokasi metodeLokasi;
  final DateTime dikonfirmasiAtUtc;

  // Dipanggil setelah pengguna menekan Konfirmasi Titik Lokasi.
  factory TitikLaporan.konfirmasi({
    required double latitude,
    required double longitude,
    required String kecamatan,
    String? alamatPeta,
    required MetodeLokasi metodeLokasi,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw const FormatException('Latitude tidak valid.');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw const FormatException('Longitude tidak valid.');
    }

    final wilayah = kecamatan.trim();
    if (wilayah.isEmpty || wilayah.runes.length > 50) {
      throw const FormatException(
        'Kecamatan lokasi kejadian belum terdeteksi.',
      );
    }

    return TitikLaporan._(
      latitude: double.parse(latitude.toStringAsFixed(6)),
      longitude: double.parse(longitude.toStringAsFixed(6)),
      kecamatan: wilayah,
      alamatPeta: alamatPeta,
      metodeLokasi: metodeLokasi,
      dikonfirmasiAtUtc: DateTime.now().toUtc(),
    );
  }
}