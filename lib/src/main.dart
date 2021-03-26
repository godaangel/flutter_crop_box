library crop_box;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'box_border.dart';
import 'grid_line.dart';

enum CropBoxType {
  Square,
  Circle
}

/// 回调函数的类型定义
typedef _CropRectUpdate = void Function(Rect rect);

class CropBox extends StatefulWidget {

  /// 初始裁剪区域（LTRB均是 0 到 1 的double类型）
  /// 
  /// 如果不填，默认会填充并居中，表现形式类似cover
  final Rect cropRect;
  /// 待裁剪素材的尺寸
  final Size clipSize;
  /// 子组件
  /// 
  /// 一般是待裁剪素材
  final Widget child;
  /// 裁剪框比例
  /// 
  /// 默认 16:9
  final Size cropRatio;
  /// 裁剪框当前比例下最大宽高
  /// 
  /// 主要是用于需要主动调整裁剪框大小时使用 如果没有特殊需求，不需要配置
  final Size maxCropSize;
  /// 最大放大尺寸
  /// 
  /// 允许放大的最大尺寸，默认10.0
  final double maxScale;
  /// 裁剪区域开始变化时的回调
  final Function cropRectUpdateStart;
  /// 裁剪区域变化时的回调
  /// 
  /// 可用于初始生成裁剪区域，以及手势触发的回调
  final _CropRectUpdate cropRectUpdate;
  /// 裁剪区域停止变化时的回调函数，可以获得最终裁剪区域
  /// 
  /// 返回值 `Rect rect` 为裁剪区域在素材上的比例
  /// 
  /// `rect`的LTRB值均为0到1的`double`值，代表在本轴上的百分比位置
  /// 
  /// 这个百分比只是LTRB分别相对于原素材宽高的百分比，各个LTRB之间这个**百分比值没有联系**
  /// 
  /// LTRB的绝对值有比例关系，比例等于裁剪比例
  final _CropRectUpdate cropRectUpdateEnd;

  /// 裁剪框类型
  /// 
  /// [cropBoxType] 有两种类型
  /// 
  /// [CropBoxType.Square] 表示方形框
  /// [CropBoxType.Circle] 表示圆形框，圆形裁剪框模式下[cropRatio]会强制为`1:1`，且`needInnerBorder`和`borderRadius`不生效
  /// 
  /// [cropBoxType] 默认值为 [CropBoxType.Square]
  final CropBoxType cropBoxType;

  /// 是否需要内边框
  /// 
  /// default [false]
  final bool needInnerBorder;

  /// 网格线
  final GridLine gridLine;

  /// 裁剪框边框样式
  /// 
  /// 包含颜色、宽度、圆角等信息
  final CropBoxBorder cropBoxBorder;

  /// 裁剪框背景颜色
  /// 
  /// default [Color(0xff141414)]
  final Color backgroundColor;
  
  /// ### 裁剪素材组件 
  /// 
  /// 通过传入裁剪素材宽高[clipSize]，裁剪区域比例[cropRatio]以及待裁剪的内容[child]，就可以生成裁剪器，支持手势移动、放大缩小操作
  /// 
  /// 再通过[cropRectUpdateEnd]回调拿到裁剪区域的值，对应到素材进行裁剪操作
  /// 
  /// {@tool dartpad --template=stateless_widget_material}
  ///
  /// 代码示例
  /// ```dart
  /// CropBox(
  ///   // cropRect: Rect.fromLTRB(1 - 0.4083, 0.162, 1, 0.3078), // 2.4倍 随机位置
  ///   // cropRect: Rect.fromLTRB(0, 0, 0.4083, 0.1457), //2.4倍，都是0,0
  ///   cropRect: Rect.fromLTRB(0, 0, 1, 0.3572), // 1倍
  ///   clipSize: Size(200, 315),
  ///   cropRatio: Size(16, 9),
  ///   cropRectUpdateEnd: (rect) {
  ///     print("裁剪区域移动 $rect");
  ///   },
  ///   child: Image.network(
  ///     "https://img1.maka.im/materialStore/beijingshejia/tupianbeijinga/9/M_7TNT6NIM/M_7TNT6NIM_v1.jpg",
  ///     width: double.infinity,
  ///     height: double.infinity,
  ///     fit: BoxFit.cover,
  ///     loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
  ///       if (loadingProgress == null)
  ///         return child;
  ///       return Center(
  ///         child: CircularProgressIndicator(
  ///           value: loadingProgress.expectedTotalBytes != null
  ///               ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
  ///               : null,
  ///         ),
  ///       );
  ///     },
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  CropBox({this.cropRect, @required this.clipSize, @required this.child, @required this.cropRectUpdateEnd, this.cropRectUpdateStart, this.cropRectUpdate, this.cropRatio, this.maxCropSize, this.maxScale = 10.0, this.cropBoxType = CropBoxType.Square, this.needInnerBorder = false, this.gridLine, this.cropBoxBorder, this.backgroundColor});

  @override
  _CropBoxState createState() => _CropBoxState();
}

class _CropBoxState extends State<CropBox> {
  /// 临时比例缩放大小
  double _tmpScale = 1.0;
  /// 最终比例缩放大小
  double _scale = 1.0;

  /// 待裁剪素材上次偏移量
  Offset _lastFocalPoint = Offset(0.0, 0.0);
  /// 待裁剪素材初始偏移量
  Offset _deltaPoint = Offset(0, 0);
  /// 待裁剪的素材本身尺寸 - 由外部传入
  Size _originClipSize;
  /// 待裁剪的素材计算后的初始尺寸
  Size _resizeClipSize = Size(0, 0);

  /// 组件自身宽
  double _containerWidth = 0;
  /// 组件自身高
  double _containerHeight = 0;
  /// 头部padding高度
  double _containerPaddingTop = 0;
  /// 底部padding高度
  double _containerPaddingBottom = 10;
  /// 左右两边padding高度
  double _containerPaddingRL = 10;
  /// 裁剪框最大尺寸
  Size _cropBoxMaxSize = Size(0, 0);
  /// 裁剪框实际尺寸
  Size _cropBoxRealSize = Size(0, 0);
  /// 裁剪框实际坐标
  Rect _cropBoxRealRect = Rect.fromLTWH(0, 0, 0, 0);
  /// 裁剪比例
  Size _cropRatio;
  /// 中心点坐标
  Offset _originPos = Offset(0, 0);

  /// 裁剪结果数据
  /// 
  /// LTRB值均为0到1的double值，代表在本轴上的百分比位置
  /// 
  /// 包含了缩放尺寸，需要自行判断计算
  Rect resultRect;

  // 是否绘制完毕
  bool isReady = false;

  Future<void> _loading;

  @override
  void initState() {
    super.initState();
  }

  /// 初始化裁剪
  /// 
  /// 返回值 bool true表示初始化成功 false表示失败
  bool initCrop() {
    caculateCropBoxSize();
    caculateInitClipSize();
    caculateInitClipPosition();
    return true;
  }

  /// 计算canvas绘制裁剪框的位置
  /// 
  /// 计算裁剪框位置
  /// 
  /// 计算中心点位置
  void caculateCropBoxSize() {
    // 中心坐标点用组件的中心点
    _originPos = Offset(_containerWidth / 2, (_containerHeight) / 2);
    // 计算裁剪框尺寸
    _cropBoxRealSize = canculateInnerBoxRealSize(_cropBoxMaxSize, _cropRatio);
    // 计算裁剪框坐标信息(坐标轴在 0, 0 处)，用于裁剪框在canvas的坐标绘制
    _cropBoxRealRect = Rect.fromLTWH((_containerWidth - _cropBoxRealSize.width) / 2, (_containerHeight - _cropBoxRealSize.height) / 2, _cropBoxRealSize.width, _cropBoxRealSize.height);
    // print("caculateCropBoxSize Result \n _cropBoxRealSize: $_cropBoxRealSize \n _cropBoxRealRect: $_cropBoxRealRect \n _originPos: $_originPos");
  }

  /// 计算初始素材尺寸
  /// 
  /// 需要计算素材宽高比，判断横向还是纵向拉满
  void caculateInitClipSize() {
    double _realWidth = 0;
    double _realHeight = 0;

    double _cropAspectRatio = _cropBoxRealSize.width / _cropBoxRealSize.height; //裁剪框宽高比
    double _clipAspectRatio = _originClipSize.width / _originClipSize.height; //素材宽高比

    if (_cropAspectRatio > _clipAspectRatio) {
      _realWidth = _cropBoxRealSize.width;
      _realHeight = _realWidth / _clipAspectRatio;
    } else {
      _realHeight = _cropBoxRealSize.height;
      _realWidth = _realHeight * _clipAspectRatio;
    }
    _resizeClipSize = Size(_realWidth, _realHeight);

    print("_resizeClipSize: $_resizeClipSize");
  }

  /// 计算初始素材摆放位置
  /// 
  /// 根据初始素材尺寸以及scale确定初始位置
  void caculateInitClipPosition() {
    // 根据scale和传入的裁剪区域确定具体位置
    Rect _clipRect;
    if(resultRect == null || resultRect == Rect.fromLTRB(0, 0, 1, 1)) {
      // 如果没有传入初始裁剪区域，则默认居中裁剪对应比例的区域，那么scale必然为1
      _scale = 1.0;
      _deltaPoint = Offset(_originPos.dx - _resizeClipSize.width/2, _originPos.dy - _resizeClipSize.height/2);
      double _clipAspectRatio = _resizeClipSize.width / _resizeClipSize.height; //素材宽高比
      double _cropAspectRatio = _cropBoxRealSize.width / _cropBoxRealSize.height; //裁剪区域宽高比
      Rect _tempRect;
      if(_cropAspectRatio > _clipAspectRatio) {
        // 如果裁剪框宽高比大于素材宽高比
        _tempRect = Rect.fromLTWH(0, (_resizeClipSize.height - _cropBoxRealSize.height) / 2, _cropBoxRealSize.width, _cropBoxRealSize.height);
      }else{
        _tempRect = Rect.fromLTWH((_resizeClipSize.width - _cropBoxRealSize.width) / 2, 0, _cropBoxRealSize.width, _cropBoxRealSize.height);
      }
      _clipRect = Rect.fromLTRB(_tempRect.left / _resizeClipSize.width, _tempRect.top / _resizeClipSize.height, _tempRect.right / _resizeClipSize.width, _tempRect.bottom / _resizeClipSize.height);
    }else{
      double _clipAspectRatio = _resizeClipSize.width / _resizeClipSize.height; //素材宽高比
      double _cropAspectRatio = _cropBoxRealSize.width / _cropBoxRealSize.height; //裁剪区域宽高比
      if(_cropAspectRatio > _clipAspectRatio) {
        // 如果裁剪框宽高比大于素材宽高比
        _scale = 1 / resultRect.width;
      }else{
        _scale = 1 / resultRect.height;
      }
      double _scaledWidth = _scale * _resizeClipSize.width;
      double _scaledHeight = _scale * _resizeClipSize.height;

      // 计算偏移和缩放后的位置 - 计算公式画图可得【公式一】 - 一定要注意_scale
      // 至于为啥是除以_scale还没整明白，猜测和缩放有关系，需要再研究 todo
      double _scaledLeft = _originPos.dx - (_cropBoxRealSize.width / 2 + _scaledWidth * resultRect.left) / _scale;
      double _scaledTop = _originPos.dy - (_cropBoxRealSize.height / 2 + _scaledHeight * resultRect.top) / _scale;
      _deltaPoint = Offset(_scaledLeft, _scaledTop);
    }

    print('_clipRect: $_clipRect  _deltaPoint: $_deltaPoint');
  }

  /// 判断是否超出界限
  /// 
  /// 如果超出界限，则自动修正位置
  void resizeRange() {
    Rect _result = transPointToCropArea();
    double left = _result.left;
    double right = _result.right;
    double top = _result.top;
    double bottom = _result.bottom;

    // print('resizeRange: ${_result.left} ${_result.top} ${_result.bottom} ${_result.right}');

    bool _isOutRange = false;
    // 如果边过大，导致_scale < 1，则进行缩放计算，并且重置 _scale = 1
    if((right - left > 1) || (bottom - top > 1)) {
      double _max = max(right - left, bottom - top);
      left = left / _max;
      right = right / _max;
      top = top / _max;
      bottom = bottom / _max;

      _scale = 1;
      _isOutRange = true;
    }

    if(left < 0) {
      right = right - left;
      left = 0;
      _isOutRange = true;
    }

    if(right > 1) {
      left = 1 - (right - left);
      right = 1;
      _isOutRange = true;
    }

    if(top < 0) {
      bottom = bottom - top;
      top = 0;
      _isOutRange = true;
    }

    if(bottom > 1) {
      top = 1 - (bottom - top);
      bottom = 1;
      _isOutRange = true;
    }

    if(_isOutRange) {
      resultRect = Rect.fromLTRB(left, top, right, bottom);
      try {
        caculateInitClipPosition();
      }catch(e) {
        print(e);
      }
    }
  }

  /// 根据当前的点，反向计算出渲染区域
  Rect transPointToCropArea() {
    double _scaledWidth = _scale * _resizeClipSize.width;
    double _scaledHeight = _scale * _resizeClipSize.height;
    // 由【公式一】反推
    double _left = ((_originPos.dx - _deltaPoint.dx) * _scale - _cropBoxRealSize.width / 2) / _scaledWidth;
    double _top = ((_originPos.dy - _deltaPoint.dy) * _scale - _cropBoxRealSize.height / 2) / _scaledHeight;

    double _clipAspectRatio = _resizeClipSize.width / _resizeClipSize.height; //素材宽高比
    double _cropAspectRatio = _cropBoxRealSize.width / _cropBoxRealSize.height; //裁剪区域宽高比
    if(_cropAspectRatio > _clipAspectRatio) {
      // 如果裁剪框宽高比大于素材宽高比
      // 根据left和top，以及裁剪比例和实际尺寸，计算出裁剪区域相对于素材的长宽百分比LTRB（这个百分比只是Left Top Right Bottom分别相对于原素材宽高的百分比，LTRB之间这个百分比值没有任何关系，LTRB的绝对值有比例关系，比例等于裁剪比例）
      double _width = _resizeClipSize.width / _scale;
      double _right = _left + 1 / _scale;
      double _bottom = _top + _width / _cropAspectRatio / _resizeClipSize.height;
      resultRect = Rect.fromLTRB(_left, _top, _right, _bottom);
    }else{
      double _height = _resizeClipSize.height / _scale;
      double _bottom = _top + 1 / _scale;
      double _right = _left + _height * _cropAspectRatio / _resizeClipSize.width;
      _scale = resultRect != null ? (1 / resultRect.height) : 1;
      resultRect = Rect.fromLTRB(_left, _top, _right, _bottom);
    }

    return resultRect;
  }

  /// 根据填充物最大宽高和填充物比例，计算填充物实际宽高
  /// 
  /// Size [_maxSize] 最大宽高
  /// 
  /// Size [_ratioSize] 宽高比尺寸
  /// 
  Size canculateInnerBoxRealSize(Size _maxSize, Size _ratioSize) {
    double _realWidth = 0;
    double _realHeight = 0;

    double _contentAspectRatio = _maxSize.width / _maxSize.height; //容器宽高比
    double _renderAspectRatio = _ratioSize.width / _ratioSize.height; //渲染区域宽高比

    if (_contentAspectRatio > _renderAspectRatio) {
      //容器宽高比大于渲染区域宽高比，则保证高度统一
      _realHeight = _maxSize.height;
      _realWidth = _realHeight * _renderAspectRatio;
    } else {
      _realWidth = _maxSize.width;
      _realHeight = _realWidth / _renderAspectRatio;
    }

    return Size(_realWidth, _realHeight);
  }

  @override
  void didUpdateWidget(covariant CropBox oldWidget) {
    if(widget.cropRatio != oldWidget.cropRatio) {
      setState(() {
        isReady = false;
      });
    }

    super.didUpdateWidget(oldWidget);
  }
  

  @override
  Widget build(BuildContext context) {
    if(!isReady) {
      resultRect = widget.cropRect;
      assert(resultRect?.left == null || resultRect.left >= 0 && resultRect.left <=1);
      assert(resultRect?.right == null || resultRect.right >= 0 && resultRect.right <=1);
      assert(resultRect?.top == null || resultRect.top >= 0 && resultRect.top <=1);
      assert(resultRect?.bottom == null || resultRect.bottom >= 0 && resultRect.bottom <=1);

      _originClipSize = widget.clipSize;
      if(widget.cropBoxType == CropBoxType.Circle) {
        _cropRatio = Size(1, 1);
      }else{
        _cropRatio = widget.cropRatio ?? Size(16, 9);
      }

      _loading = Future.delayed(Duration(milliseconds: 10)).then((value) {
        _containerWidth = context.size.width;
        _containerHeight = context.size.height;
        _containerPaddingTop = MediaQuery.of(context).padding.top * 2;
        _cropBoxMaxSize = widget.maxCropSize ?? Size(_containerWidth - _containerPaddingRL*2, _containerHeight - _containerPaddingTop - _containerPaddingBottom);
        print("build init data \n _containerWidth: $_containerWidth _containerHeight: $_containerHeight _containerPaddingTop: $_containerPaddingTop");
        isReady = initCrop();
        if(widget.cropRectUpdate != null) {
          resultRect = transPointToCropArea();
          widget.cropRectUpdate(resultRect);
        }
        setState(() {});
      });
    }
    
    return FutureBuilder(
      future: _loading,
      builder: (_, snapshot) {
        return ClipRect(
          child: Container(
            color: widget.backgroundColor ?? Color(0xff141414),
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: (d) => _handleScaleUpdate(context.size, d),
              onScaleEnd: _handleScaleEnd,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: (isReady && snapshot.connectionState == ConnectionState.done) ? Stack(
                  children: [
                    Transform(
                      transform: Matrix4.identity()
                        ..scale(max(_scale, 1.0), max(_scale, 1.0))
                        ..translate(_deltaPoint.dx, _deltaPoint.dy),
                      origin: _originPos,
                      // overflowBox解决容器尺寸问题，如果不用overflowBox，则子container过大时，会收到父级大小约束变形
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: Container(
                          width: _resizeClipSize.width,
                          height: _resizeClipSize.height,
                          child: widget.child,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(double.infinity, double.infinity),
                      painter: widget.cropBoxType == CropBoxType.Circle ? 
                        DrawCircleLight(clipRect: _cropBoxRealRect, centerPoint: _originPos, cropBoxBorder: widget.cropBoxBorder ?? CropBoxBorder()) 
                        : DrawRectLight(clipRect: _cropBoxRealRect, needInnerBorder: widget.needInnerBorder, gridLine: widget.gridLine, cropBoxBorder: widget.cropBoxBorder ?? CropBoxBorder()),
                    ),
                  ],
                ): Center(
                  child: Container(
                    child: Center(child: CupertinoActivityIndicator(
                      radius: 12,
                    )),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _tmpScale = _scale;
    _lastFocalPoint = details.focalPoint;
    
    if(widget.cropRectUpdateStart != null) {
      widget.cropRectUpdateStart();
    }
  }

  void _handleScaleUpdate(Size size, ScaleUpdateDetails details) {
    setState(() {
      _scale = min(widget.maxScale, max(_tmpScale * details.scale, 1.0));
      if (details.scale == 1) {
        _deltaPoint += (details.focalPoint - _lastFocalPoint); //偏移量
        _lastFocalPoint = details.focalPoint; //保存最有一个Point
      }
      resizeRange();
    });
    if(widget.cropRectUpdate != null) {
      widget.cropRectUpdate(resultRect);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.cropRectUpdateEnd(resultRect);
  }
}


class DrawRectLight extends CustomPainter {
  final Rect clipRect;
  final bool needInnerBorder;
  final GridLine gridLine;
  final CropBoxBorder cropBoxBorder;
  DrawRectLight({@required this.clipRect, this.needInnerBorder, this.gridLine, this.cropBoxBorder});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    double _storkeWidth = cropBoxBorder.width;
    Radius _borderRadius = cropBoxBorder.noNullRaidus;
    RRect _rrect = RRect.fromRectAndRadius(clipRect, _borderRadius);
    RRect _borderRRect = RRect.fromRectAndRadius(Rect.fromLTWH(clipRect.left, clipRect.top - _storkeWidth / 2, clipRect.width, clipRect.height + _storkeWidth), _borderRadius);

    paint
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(20, 20, 20, 0.6);
    canvas.save();

    // 绘制一个圆形反选框和背景遮罩（透明部分）
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height)),
      Path()
        ..addRRect(_rrect)
        ..close(),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    // 绘制主色调边框
    paint
      ..color = cropBoxBorder.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _storkeWidth;
      
    canvas.drawRRect(_borderRRect, paint);

    if(gridLine != null) {
      canvas.save();
      // 绘制主色调边框
      paint
        ..color = gridLine.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = gridLine.width;
      Path gridLinePath = new Path();

      EdgeInsets _padding = gridLine.padding ?? EdgeInsets.all(0);

      for(int i = 1; i < 3; i ++) {
        // 绘制横线
        gridLinePath.moveTo(((clipRect.width / 3) * i + clipRect.left - gridLine.width / 2), clipRect.top + _padding.top);
        gridLinePath.lineTo(((clipRect.width / 3) * i + clipRect.left - gridLine.width / 2), clipRect.top + clipRect.height - _padding.bottom);

        // 绘制竖线
        gridLinePath.moveTo(clipRect.left + _padding.left, ((clipRect.height / 3) * i + clipRect.top - gridLine.width / 2));
        gridLinePath.lineTo(clipRect.left + clipRect.width - _padding.right, ((clipRect.height / 3) * i + clipRect.top - gridLine.width / 2));
      }
      canvas.drawPath(gridLinePath, paint);
      canvas.restore();
    }

    if(needInnerBorder) {
      // 绘制边框内的样式
      paint.style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(clipRect.left - _storkeWidth / 2, clipRect.top - _storkeWidth, 45.44 / 2, 7.57 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left - _storkeWidth / 2, clipRect.top - _storkeWidth, 7.57 / 2, 45.44 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2, clipRect.top - _storkeWidth, -45.44 / 2, 7.57 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2, clipRect.top - _storkeWidth, -7.57 / 2, 45.44 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left - _storkeWidth / 2, clipRect.top + clipRect.height + _storkeWidth, 45.44 / 2, -7.57 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left - _storkeWidth / 2, clipRect.top + clipRect.height + _storkeWidth, 7.57 / 2, -45.44 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2, clipRect.top + clipRect.height + _storkeWidth, -45.44 / 2, -7.57 / 2), paint);
      canvas.drawRect(Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2, clipRect.top + clipRect.height + _storkeWidth, -7.57 / 2, -45.44 / 2), paint);
    }
    
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DrawCircleLight extends CustomPainter {
  final Rect clipRect;
  final Offset centerPoint;
  final CropBoxBorder cropBoxBorder;
  DrawCircleLight({@required this.clipRect, this.centerPoint, this.cropBoxBorder});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    double _storkeWidth = cropBoxBorder.width;
    double _radius = clipRect.width / 2;
    paint
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(20, 20, 20, 0.6);
    canvas.save();
    // 绘制一个圆形反选框和背景遮罩（透明部分）
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height)),
      Path()
        ..addOval(Rect.fromCircle(center: centerPoint, radius: _radius))
        ..close(),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    // 绘制主色调边框
    paint
      ..color = cropBoxBorder.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _storkeWidth;
    canvas.drawCircle(centerPoint, _radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
