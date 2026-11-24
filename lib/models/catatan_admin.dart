import 'package:hive/hive.dart';

part 'catatan_admin.g.dart';

@HiveType(typeId: 0)
class CatatanAdmin extends HiveObject {
  CatatanAdmin({
    required this.idCatatan,
    required this.idAdmin,
    required this.judul,
    required this.isi,
    required this.kodeLaporan,
    required this.dibuatAtUtc,
    required this.diubahAtUtc,
  });

  @HiveField(0)
  final String idCatatan;

  @HiveField(1)
  final int idAdmin;

  @HiveField(2)
  final String judul;

  @HiveField(3)
  final String isi;

  @HiveField(4)
  final String kodeLaporan;

  @HiveField(5)
  final DateTime dibuatAtUtc;

  @HiveField(6)
  final DateTime diubahAtUtc;
}
