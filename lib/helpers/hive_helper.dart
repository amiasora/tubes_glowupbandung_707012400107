import 'package:hive/hive.dart';

import '../models/catatan_admin.dart';

class HiveHelper {
  HiveHelper._();

  static final HiveHelper instance = HiveHelper._();

  static const String namaBoxCatatan = 'catatan_admin_box';

  Box<CatatanAdmin>? _box;
  Future<void>? _pembukaan;

  Future<void> init() {
    if (_box?.isOpen ?? false) {
      return Future<void>.value();
    }

    return _pembukaan ??= _buka();
  }

  Future<void> _buka() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CatatanAdminAdapter());
      }

      _box = await Hive.openBox<CatatanAdmin>(namaBoxCatatan);
    } finally {
      _pembukaan = null;
    }
  }

  Box<CatatanAdmin> get box {
    final data = _box;

    if (data == null || !data.isOpen) {
      throw StateError('Box catatan admin belum dibuka.');
    }

    return data;
  }

  String _kunciCatatan({required int idAdmin, required String idCatatan}) {
    if (idCatatan.trim().isEmpty) {
      throw ArgumentError.value(
        idCatatan,
        'idCatatan',
        'ID catatan tidak boleh kosong.',
      );
    }

    return '$idAdmin:$idCatatan';
  }

  Future<void> simpanCatatan(CatatanAdmin catatan) async {
    final kunci = _kunciCatatan(
      idAdmin: catatan.idAdmin,
      idCatatan: catatan.idCatatan,
    );

    await box.put(kunci, catatan);
  }

  List<CatatanAdmin> bacaCatatanAdmin(int idAdmin) {
    final hasil = box.values
        .where((catatan) => catatan.idAdmin == idAdmin)
        .toList();

    hasil.sort((a, b) {
      final perbandinganWaktu = b.diubahAtUtc.compareTo(a.diubahAtUtc);

      if (perbandinganWaktu != 0) {
        return perbandinganWaktu;
      }

      return a.idCatatan.compareTo(b.idCatatan);
    });

    return hasil;
  }

  CatatanAdmin? bacaCatatan({required int idAdmin, required String idCatatan}) {
    final kunci = _kunciCatatan(idAdmin: idAdmin, idCatatan: idCatatan);

    return box.get(kunci);
  }

  Future<void> hapusCatatan({
    required int idAdmin,
    required String idCatatan,
  }) async {
    final kunci = _kunciCatatan(idAdmin: idAdmin, idCatatan: idCatatan);

    await box.delete(kunci);
  }
}
