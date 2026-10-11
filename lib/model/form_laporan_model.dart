import 'package:flutter/foundation.dart';

import 'riwayat_laporan_model.dart';

class FormLaporanModel extends ChangeNotifier {
  String _judul = '';
  String _lokasi = '';
  String _deskripsi = '';

  bool _setuju = false;
  bool _sedangMengirim = false;
  bool _sudahDilepas = false;

  String get judul => _judul;
  String get lokasi => _lokasi;
  String get deskripsi => _deskripsi;

  bool get setuju => _setuju;
  bool get sedangMengirim => _sedangMengirim;

  bool get formLengkap {
    return _judul.trim().isNotEmpty &&
        _lokasi.trim().isNotEmpty &&
        _deskripsi.trim().isNotEmpty &&
        _setuju;
  }

  Map<String, String> get dataLaporan {
    return {
      'judul': _judul.trim(),
      'lokasi': _lokasi.trim(),
      'deskripsi': _deskripsi.trim(),
      'status': 'Menunggu',
    };
  }

  void ubahJudul(String nilai) {
    if (_sedangMengirim || nilai == _judul) {
      return;
    }

    _judul = nilai;
    notifyListeners();
  }

  void ubahLokasi(String nilai) {
    if (_sedangMengirim || nilai == _lokasi) {
      return;
    }

    _lokasi = nilai;
    notifyListeners();
  }

  void ubahDeskripsi(String nilai) {
    if (_sedangMengirim || nilai == _deskripsi) {
      return;
    }

    _deskripsi = nilai;
    notifyListeners();
  }

  void ubahPersetujuan(bool nilai) {
    if (_sedangMengirim || nilai == _setuju) {
      return;
    }

    _setuju = nilai;
    notifyListeners();
  }

  void _bersihkanIsian() {
    _judul = '';
    _lokasi = '';
    _deskripsi = '';
    _setuju = false;
  }

  void kosongkanForm() {
    if (_sedangMengirim) {
      return;
    }

    _bersihkanIsian();
    notifyListeners();
  }

  Future<bool> kirimLaporan(
    RiwayatLaporanModel riwayat,
  ) async {
    if (!formLengkap || _sedangMengirim) {
      return false;
    }

    // Menyimpan salinan isian sebelum proses pengiriman.
    final laporan = dataLaporan;

    if (riwayat.sudahTersimpan(laporan)) {
      throw StateError(
        'Laporan dengan judul dan lokasi yang sama '
        'sudah tersimpan.',
      );
    }

    _sedangMengirim = true;
    notifyListeners();

    try {
      // Simulasi pengiriman untuk kebutuhan praktikum.
      await Future<void>.delayed(
        const Duration(seconds: 2),
      );

      if (_sudahDilepas) {
        return false;
      }

      // Memeriksa kembali untuk mencegah laporan ganda.
      if (riwayat.sudahTersimpan(laporan)) {
        throw StateError(
          'Laporan dengan judul dan lokasi yang sama '
          'sudah tersimpan.',
        );
      }

      riwayat.tambahLaporan(laporan);
      _bersihkanIsian();

      return true;
    } finally {
      _sedangMengirim = false;

      if (!_sudahDilepas) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _sudahDilepas = true;
    super.dispose();
  }
}