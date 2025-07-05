// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogAdapter extends TypeAdapter<DailyLog> {
  @override
  final int typeId = 1;

  @override
  DailyLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLog()
      ..date = fields[0] as String
      ..morningQuestionsCompleted = fields[1] as bool
      ..afternoonQuestionsCompleted = fields[2] as bool
      ..eveningQuestionsCompleted = fields[3] as bool
      ..tasksCompleted = fields[4] as bool
      ..questionAnswers = (fields[5] as Map?)?.cast<String, String>()
      ..taskStatus = (fields[6] as Map?)?.cast<String, bool>()
      ..taskComments = (fields[7] as Map?)?.cast<String, String>()
      ..questCompleted = fields[8] as bool
      ..questId = fields[9] as String?
      ..questResult = (fields[10] as Map?)?.cast<String, dynamic>()
      ..ritualStatus = (fields[11] as Map?)?.cast<String, bool>()
      ..morningQuestionIds = (fields[12] as List?)?.cast<String>()
      ..afternoonQuestionIds = (fields[13] as List?)?.cast<String>()
      ..eveningQuestionIds = (fields[14] as List?)?.cast<String>()
      ..dailyPoints = fields[15] as int?
      ..dailyGameId = fields[16] as String?
      ..gameCompleted = fields[17] as bool
      ..nBackLevel = fields[18] as int
      ..memoryGameLevel = fields[19] as int;
  }

  @override
  void write(BinaryWriter writer, DailyLog obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.morningQuestionsCompleted)
      ..writeByte(2)
      ..write(obj.afternoonQuestionsCompleted)
      ..writeByte(3)
      ..write(obj.eveningQuestionsCompleted)
      ..writeByte(4)
      ..write(obj.tasksCompleted)
      ..writeByte(5)
      ..write(obj.questionAnswers)
      ..writeByte(6)
      ..write(obj.taskStatus)
      ..writeByte(7)
      ..write(obj.taskComments)
      ..writeByte(8)
      ..write(obj.questCompleted)
      ..writeByte(9)
      ..write(obj.questId)
      ..writeByte(10)
      ..write(obj.questResult)
      ..writeByte(11)
      ..write(obj.ritualStatus)
      ..writeByte(12)
      ..write(obj.morningQuestionIds)
      ..writeByte(13)
      ..write(obj.afternoonQuestionIds)
      ..writeByte(14)
      ..write(obj.eveningQuestionIds)
      ..writeByte(15)
      ..write(obj.dailyPoints)
      ..writeByte(16)
      ..write(obj.dailyGameId)
      ..writeByte(17)
      ..write(obj.gameCompleted)
      ..writeByte(18)
      ..write(obj.nBackLevel)
      ..writeByte(19)
      ..write(obj.memoryGameLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
