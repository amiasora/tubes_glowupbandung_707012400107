import 'package:shared_preferences/shared_preferences.dart';

class PengaturanHelper {
  PengaturanHelper._();

  static final PengaturanHelper instance = PengaturanHelper._();

  static const String kunciTemaGelap = 'tema_gelap';

  Future<bool> muatTemaGelap() async {
    final preferensi = await SharedPreferences.getInstance();

    await preferensi.reload();

    return preferensi.getBool(kunciTemaGelap) ?? false;
  }

  Future<void> simpanTemaGelap(bool aktif) async {
    final preferensi = await SharedPreferences.getInstance();

    final berhasil = await preferensi.setBool(kunciTemaGelap, aktif);

    if (!berhasil) {
      throw StateError(
        'Pilihan tema belum berhasil disimpan. Silakan coba kembali.',
      );
    }
  }
}
