import 'dart:typed_data';

import 'package:example/image_result_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:crop_box/crop_box.dart';
import 'package:image_picker/image_picker.dart';

enum ClipType {
  networkImage,
  localImage
}

class CropIndex extends StatefulWidget {
  final double width;
  final double height;
  final ClipType clipType;
  final Uint8List localImageData;
  final String imageUrl;
  CropIndex({Key key, this.width, this.height, this.clipType, this.localImageData, this.imageUrl}) : super(key: key);

  @override
  _CropIndexState createState() => _CropIndexState();
}

class _CropIndexState extends State<CropIndex> {
  Rect _resultRect = Rect.zero;
  /// 最大裁剪区域 会结合裁剪比例计算实际裁剪框范围
  Size _maxCropSize = Size(300, 300);
  /// 裁剪比例
  Size _cropRatio = Size(16, 9);
  /// 裁剪区域
  Rect _cropRect;

  bool exportLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Detail'),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: CropBox(
                // cropRect: Rect.fromLTRB(1 - 0.4083, 0.162, 1, 0.3078), // 2.4倍 模拟随机位置
                // cropRect: Rect.fromLTRB(0, 0, 0.4083, 0.1457), //2.4倍，都是0,0
                // cropRect: Rect.fromLTRB(0, 0, 1, 0.3572), // 1倍
                // cropBoxType: CropBoxType.Circle,
                // borderColor: Colors.white,
                gridLine: GridLine(),
                cropRect: _cropRect,
                clipSize: Size(widget.width, widget.height),
                maxCropSize: _maxCropSize,
                cropRatio: _cropRatio,
                cropBoxBorder: CropBoxBorder(
                  color: Colors.white,
                  radius: Radius.circular(5),
                ),
                cropRectUpdateEnd: (rect) {
                  _resultRect = rect;
                  print("裁剪区域最终确定 $rect");
                  setState(() {});
                },
                cropRectUpdate: (rect) {
                  _resultRect = rect;
                  print("裁剪区域变化 $rect");
                  setState(() {});
                },
                child: widget.clipType == ClipType.networkImage ? Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
                    if (loadingProgress == null)
                      return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                            : null,
                      ),
                    );
                  },
                ) : Image.memory(
                    widget.localImageData,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
              ),
            ),
            SizedBox(
              height: 36.w,
            ),
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                height: 250.w,
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      flex: 0,
                      child: Container(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "裁剪区域: ",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "left: ${_resultRect.left.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "top: ${_resultRect.top.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "right: ${_resultRect.right.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "bottom: ${_resultRect.bottom.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CupertinoButton(
                            color: Colors.blue,
                            child: Text(
                              "1:1",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _cropRatio = Size(1, 1);
                              });
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          CupertinoButton(
                            color: Colors.blue,
                            child: Text(
                              exportLoading ? "Exporting" : "Export",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 28.sp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: exportLoading ? null : () async {
                              setState(() {
                                exportLoading = true;
                              });

                              /// get origin image uint8List
                              Uint8List bytes;
                              if(widget.clipType == ClipType.networkImage) {
                                bytes = (await NetworkAssetBundle(Uri.parse(widget.imageUrl))
                                .load(widget.imageUrl))
                                .buffer
                                .asUint8List();
                              }else{
                                bytes = widget.localImageData;
                              }
                              /// get result uint8List
                              Uint8List result = await ImageCrop.getResult(
                                clipRect: _resultRect, 
                                image: bytes
                              );
                              
                              setState(() {
                                exportLoading = false;
                              });

                              /// if you need to export to gallery
                              /// you can use this https://pub.dev/packages/image_gallery_saver
                              /// ... your export code ...
                              /// 
                              /// my code is only to show result in other page
                              Navigator.of(context).push(new MaterialPageRoute(builder: (_) {
                                return ImageResultPage(imageBytes: result,);
                              }));
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}