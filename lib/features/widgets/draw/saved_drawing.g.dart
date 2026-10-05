part of 'saved_drawing.dart';

class SavedDrawingAdapter extends TypeAdapter<SavedDrawing> {
  @override
  final int typeId = 1;

  @override
  SavedDrawing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedDrawing(
      name: fields[0] as String,
      imageBytes: fields[1] as Uint8List,
      format: fields[2] as String,
      strokes: (fields[3] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      texts: (fields[4] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      widgetsData: (fields[5] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      azimuthLayer: fields[6] as bool?,
      shapes: (fields[7] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      circles: (fields[8] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      backgroundImageData: fields[9] as Uint8List?,
      curves: (fields[10] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, SavedDrawing obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.imageBytes)
      ..writeByte(2)
      ..write(obj.format)
      ..writeByte(3)
      ..write(obj.strokes)
      ..writeByte(4)
      ..write(obj.texts)
      ..writeByte(5)
      ..write(obj.widgetsData)
      ..writeByte(6)
      ..write(obj.azimuthLayer)
      ..writeByte(7)
      ..write(obj.shapes)
      ..writeByte(8)
      ..write(obj.circles)
      ..writeByte(9)
      ..write(obj.backgroundImageData)
      ..writeByte(10)
      ..write(obj.curves);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedDrawingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
