import 'package:flutter/foundation.dart';

class RiwayatLaporanModel extends ChangeNotifier {
  final List<Map<String, String>> _daftarLaporan = [];

  List<Map<String, String>> get daftarLaporan {
    return List.unmodifiable(_daftarLaporan);
  }

  int get totalLaporan {
    return _daftarLaporan.length;
  }

  bool sudahTersimpan(Map<String, String> laporan) {
    final judul = laporan['judul'];
    final lokasi = laporan['lokasi'];

    return _daftarLaporan.any(
      (item) =>
          item['judul'] == judul &&
          item['lokasi'] == lokasi,
    );
  }

  void tambahLaporan(Map<String, String> laporan) {
    if (sudahTersimpan(laporan)) {
      return;
    }

    final dataBaru = Map<String, String>.from(laporan);

    dataBaru['status'] =
        dataBaru['status'] ?? 'Dikonfirmasi';

    _daftarLaporan.add(dataBaru);

    notifyListeners();
  }

  void hapusLaporan(Map<String, String> laporan) {
    _daftarLaporan.removeWhere(
      (item) =>
          item['judul'] == laporan['judul'] &&
          item['lokasi'] == laporan['lokasi'],
    );

    notifyListeners();
  }

  void kosongkan() {
    if (_daftarLaporan.isEmpty) {
      return;
    }

    _daftarLaporan.clear();

    notifyListeners();
  }
}