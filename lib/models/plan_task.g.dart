// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanTaskAdapter extends TypeAdapter<PlanTask> {
  @override
  final int typeId = 2;

  @override
  PlanTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanTask(
      id: fields[0] as String,
      text: fields[1] as String,
      isCompleted: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlanTask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
