import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../helpers/pengaturan_helper.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({
    ThemeMode temaAwal = ThemeMode.light,
    PengaturanHelper? pengaturan,
  }) : _pengaturan = pengaturan ?? PengaturanHelper.instance,
       super(temaAwal);

  final PengaturanHelper _pengaturan;

  Future<void> ubahModeGelap(bool aktif) async {
    final temaBaru = aktif ? ThemeMode.dark : ThemeMode.light;

    if (isClosed || state == temaBaru) return;

    await _pengaturan.simpanTemaGelap(aktif);

    if (!isClosed) {
      emit(temaBaru);
    }
  }
}
