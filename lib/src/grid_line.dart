import 'package:flutter/material.dart';

class GridLine {
  /// 网格线颜色
  /// 默认 `Colors.white`
  Color color;
  /// 网格线宽度
  double width;
  /// 网格线padding
  EdgeInsets padding;

  /// 网格线
  GridLine({this.color = Colors.white, this.width = 0.5, this.padding});
}
