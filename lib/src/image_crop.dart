import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';

import 'package:image_size_getter/image_size_getter.dart';

class ImageCrop {
  static Future<Uint8List> getResult({@required Rect clipRect, @required Uint8List image}) async {

    final Size memoryImageSize = ImageSizeGetter.getSize(MemoryInput(image));
    final editorOption = ImageEditorOption();

    editorOption.addOption(ClipOption(
      x: clipRect.left * memoryImageSize.width,
      y: clipRect.top * memoryImageSize.height,
      width: clipRect.width * memoryImageSize.width,
      height: clipRect.height * memoryImageSize.height
    ));

    editorOption.outputFormat = OutputFormat.png(88);
    final result = await ImageEditor.editImage(image: image, imageEditorOption: editorOption);
    return result;
  }
}