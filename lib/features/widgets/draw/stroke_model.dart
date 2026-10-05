 class StrokeModel {
    final double? x;
    final double? y;
    final int color;
    final double strokeWidth;
    final bool isEraser;
    final int? lineStyle;

    StrokeModel({
      this.x,
      this.y,
      required this.color,
      required this.strokeWidth,
      required this.isEraser,
      this.lineStyle,
    });

    Map<String, dynamic> toMap() => {
      'x': x,
      'y': y,
      'color': color,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'lineStyle': lineStyle,
    };

    factory StrokeModel.fromMap(Map<String, dynamic> map) {
      return StrokeModel(
        x: (map['x'] as num?)?.toDouble(),
        y: (map['y'] as num?)?.toDouble(),
        color: map['color'] as int,
        strokeWidth: (map['strokeWidth'] as num).toDouble(),
        isEraser: map['isEraser'] ?? false,
        lineStyle: map['lineStyle'] as int?,
      );
    }
  }
