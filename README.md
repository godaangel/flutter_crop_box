> Background: why develop this component? At present, video synthesis technology is used in our flitter app, which involves the clipping of video or picture materials. At present, the common components in the market are based on pictures, and basically use canvas for rendering and clipping, which does not meet our business needs, so we need to develop a clipping component ourselves.

[中文文档](https://github.com/godaangel/flutter_crop_box/blob/master/doc/README_ZH.md)

## Demo

![](https://github.com/godaangel/flutter_crop_box/blob/master/gif/5e941f8d-39a2-45da-9c8c-9eb2f6513498.gif)

## Demand analysis

At the beginning of requirement design, considering the habit of gesture and referring to most editing tools, the following requirements are defined:

- The clipping Box **is fixed** in a position on the screen. The position and size of the material can be adjusted by **dragging with one finger and zooming with two fingers** to frame the clipping range

- The minimum edge of the material cannot be less than the corresponding edge of the clipping box, that is, the clipping Box **can only move relatively within the range of the material**

- The types of supporting materials include **pictures and videos**

## Parameter

| name | type | desc | default |
| --- | --- | --- | --- |
| cropRect | Rect | If you do not fill in the initial clipping region, it will be filled and centered by default, which is similar to cover | - |
| clipSize | Size | Size of material to be cut | Required |
| cropRatio | Size | Crop box scale, default`16:9` | `Size(16, 9)` |
| child | Widget | Material to be cut | Required |
| maxCropSize | Size | The maximum width and height of the current scale of the clipping box is mainly used when the size of the clipping box needs to be adjusted actively. If there is no special requirement, it does not need to be configured | Calculate based on parent component |
| maxScale | Double | Maximum size allowed to enlarge | `10.0` |
| borderColor | Color | Crop box border color | `Colors.White` |
| cropRectUpdateStart | Function | Callback when crop region begins to change | - |
| cropRectUpdate | Function(Rect rect) | Callback when clipping region changes | - |
| cropRectUpdateEnd | Function(Rect rect) | Callback when clipping region end | Required |

## Demo code

> Can see `example` in github

#### git
```yaml
  crop_box:
    git:
      url: https://github.com/godaangel/flutter_crop_box.git
```

#### pub.dev
```yaml
  crop_box: ^0.1.0
```

#### Code
```dart
import 'package:crop_box/crop_box.dart';

// ...

CropBox(
  // cropRect: Rect.fromLTRB(1 - 0.4083, 0.162, 1, 0.3078), // 2.4倍 随机位置
  // cropRect: Rect.fromLTRB(0, 0, 0.4083, 0.1457), //2.4倍，都是0,0
  cropRect: Rect.fromLTRB(0, 0, 1, 0.3572), // 1倍
  clipSize: Size(200, 315),
  cropRatio: Size(16, 9),
  cropRectUpdateEnd: (rect) {
    print("rect final $rect");
  },
  cropRectUpdate: (rect) {
    print("rect change $rect");
  },
  child: Image.network(
  "https://img1.maka.im/materialStore/beijingshejia/tupianbeijinga/9/M_7TNT6NIM/M_7TNT6NIM_v1.jpg",
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
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
  ),
)
```

## TODO

* [x] Dynamically transform crop box scale

* [ ] Optimize boundary calculation code

* [ ] Support the drawing of fillet clipping box

* [ ] Support rotation
