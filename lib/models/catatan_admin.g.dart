// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catatan_admin.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CatatanAdminAdapter extends TypeAdapter<CatatanAdmin> {
  @override
  final int typeId = 0;

  @override
  CatatanAdmin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CatatanAdmin(
      idCatatan: fields[0] as String,
      idAdmin: fields[1] as int,
      judul: fields[2] as String,
      isi: fields[3] as String,
      kodeLaporan: fields[4] as String,
      dibuatAtUtc: fields[5] as DateTime,
      diubahAtUtc: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CatatanAdmin obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.idCatatan)
      ..writeByte(1)
      ..write(obj.idAdmin)
      ..writeByte(2)
      ..write(obj.judul)
      ..writeByte(3)
      ..write(obj.isi)
      ..writeByte(4)
      ..write(obj.kodeLaporan)
      ..writeByte(5)
      ..write(obj.dibuatAtUtc)
      ..writeByte(6)
      ..write(obj.diubahAtUtc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatatanAdminAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
