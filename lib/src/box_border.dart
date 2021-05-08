import 'package:flutter/material.dart';

class CropBoxBorder {
  /// 方形模式下，边框的圆角
  final Radius? radius;
  Radius get noNullRaidus => radius ?? Radius.circular(0);

  /// 边框宽度
  /// 
  /// 默认 [2]
  final double width;

  /// 边框颜色
  /// 
  /// 默认 [Colors.white]
  final Color color;

  CropBoxBorder({this.radius, this.width = 2, this.color = Colors.white});
}