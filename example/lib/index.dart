import 'dart:typed_data';

import 'package:example/crop_index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_box/crop_box.dart';



class PageIndex extends StatefulWidget {
  PageIndex({Key key}) : super(key: key);

  @override
  _PageIndexState createState() => _PageIndexState();
}

class _PageIndexState extends State<PageIndex> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Box'),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 100,
            ),
            /// NetWork Image
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CropIndex(
                  width: 200,
                  height: 315,
                  imageUrl: "https://img1.maka.im/materialStore/beijingshejia/tupianbeijinga/9/M_7TNT6NIM/M_7TNT6NIM_v1.jpg",
                  clipType: ClipType.networkImage,
                )));
              },
              child: Text('Test NetWork Image'),
            ),
            /// Local Image
            TextButton(
              onPressed: () async {
                PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                Uint8List bytes = await pickedFile.readAsBytes();
                Size imageSize = await ImageCrop.getImageSize(bytes);
                Navigator.push(context, MaterialPageRoute(builder: (context) => CropIndex(
                  width: imageSize.width,
                  height: imageSize.height,
                  localImageData: bytes,
                  clipType: ClipType.localImage,
                )));
              },
              child: Text('Choose Local Image'),
            ),
          ],
        ),
      ),
    );
  }
}
