import 'dart:ui';
import 'package:flutter/material.dart';
import 'linestyle.dart';


class DrawingArea {
  Offset point;
  Paint areaPaint;
  LineStyle lineStyle;

  DrawingArea({
    required this.areaPaint,
    required this.point,
    this.lineStyle = LineStyle.solid,
  });
}