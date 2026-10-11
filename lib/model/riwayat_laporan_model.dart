import 'package:flutter/foundation.dart';

class RiwayatLaporanModel extends ChangeNotifier {
  final List<Map<String, String>> _daftarLaporan = [];

  List<Map<String, String>> get daftarLaporan {
    return List<Map<String, String>>.unmodifiable(
      _daftarLaporan.map(
        (laporan) => Map<String, String>.unmodifiable(laporan),
      ),
    );
  }

  int get totalLaporan => _daftarLaporan.length;

  int get totalSelesai {
    return _daftarLaporan
        .where((laporan) => laporan['status'] == 'Selesai')
        .length;
  }

  int get totalBelumSelesai => totalLaporan - totalSelesai;

  bool sudahTersimpan(Map<String, String> laporan) {
    return _daftarLaporan.any(
      (item) =>
          item['judul'] == laporan['judul'] &&
          item['lokasi'] == laporan['lokasi'],
    );
  }

  void tambahLaporan(Map<String, String> laporan) {
    if (sudahTersimpan(laporan)) {
      return;
    }

    final dataBaru = Map<String, String>.from(laporan);

    dataBaru['status'] = dataBaru['status'] ?? 'Dikonfirmasi';

    _daftarLaporan.add(dataBaru);
    notifyListeners();
  }

  bool tandaiSelesai(Map<String, String> laporan) {
    final indeks = _daftarLaporan.indexWhere(
      (item) =>
          item['judul'] == laporan['judul'] &&
          item['lokasi'] == laporan['lokasi'],
    );

    if (indeks == -1 ||
        _daftarLaporan[indeks]['status'] == 'Selesai') {
      return false;
    }

    _daftarLaporan[indeks]['status'] = 'Selesai';
    notifyListeners();

    return true;
  }

  void hapusLaporan(Map<String, String> laporan) {
    final jumlahAwal = _daftarLaporan.length;

    _daftarLaporan.removeWhere(
      (item) =>
          item['judul'] == laporan['judul'] &&
          item['lokasi'] == laporan['lokasi'],
    );

    if (_daftarLaporan.length != jumlahAwal) {
      notifyListeners();
    }
  }

  void kosongkan() {
    if (_daftarLaporan.isEmpty) {
      return;
    }

    _daftarLaporan.clear();
    notifyListeners();
  }
}