import 'dart:typed_data';

enum TahapPengangkutan {
  mulai('Mulai', 'Check-in'),
  perkembangan('Perkembangan', 'Catat perkembangan'),
  selesai('Selesai', 'Selesaikan tugas'),
  tanggapan('Tanggapan', 'Kirim Foto Progres');

  const TahapPengangkutan(this.label, this.aksi);
  final String label;
  final String aksi;
}

typedef FotoAktivitasPengangkutan = ({String nama, Uint8List bytes});

class AktivitasPengangkutan {
  AktivitasPengangkutan.fromMap(Map<String, Object?> data, this.foto)
    : tahap = data['tahap'] as String,
      catatan = data['catatan'] as String,
      petugas = data['nama_petugas'] as String,
      waktuUtc = DateTime.parse(data['waktu_utc'] as String);

  final String tahap;
  final String catatan;
  final String petugas;
  final DateTime waktuUtc;
  final List<FotoAktivitasPengangkutan> foto;

  bool get fotoProgres =>
      tahap == TahapPengangkutan.tanggapan.label && foto.isNotEmpty;
}