> 背景：为啥要开发这个组件呢？因为目前在我们的flutter app中，用到了视频合成技术，这里就涉及到视频或者图片素材的裁剪，目前市面上普遍的组件都是基于图片的，并且基本上都是使用canvas进行渲染和裁剪，不太符合我们的业务需求，所以要自己开发一个裁剪组件。

## 效果展示
![](https://github.com/godaangel/flutter_crop_box/blob/master/gif/5e941f8d-39a2-45da-9c8c-9eb2f6513498.gif)

## 需求分析 
在移动端，基本都是用手势操作，所以在需求设计之初，就考虑到手势的习惯，以及参考大部分编辑工具，定义出了以下几个需求点：
- 裁剪框**固定**在屏幕上的一个位置，通过**单指拖动，双指缩放**的形式调整素材位置和大小，来框定裁剪范围
- 素材的最小边不能小于裁剪框上与其对应的边，即裁剪框**只能相对在素材范围内移动**
- 支持素材的类型包含**图片和视频**

## 参数设计

| 参数名 | 类型 | 描述 | 默认值 |
| --- | --- | --- | --- |
| cropRect | Rect | 初始裁剪区域，如果不填，默认会填充并居中，表现形式类似cover | - |
| clipSize | Size | 待裁剪素材的尺寸 | 必填 |
| cropRatio | Size | 裁剪框比例，默认`16:9` | `Size(16, 9)` |
| child | Widget | 待裁剪素材 | 必填 |
| maxCropSize | Size | 裁剪框当前比例下最大宽高，主要是用于需要主动调整裁剪框大小时使用 如果没有特殊需求，不需要配置 | 根据父组件计算 |
| maxScale | Double | 允许放大的最大尺寸 | `10.0` |
| needInnerBorder | bool | 方形模式下是否需要内边框修饰（如果有圆角，则不显示） | `false` |
| cropBoxType | CropBoxType | 裁剪框样式，默认方形，可以换成圆形，如果是圆形，则`cropRatio`设置的值将失效，强制变为`1:1` | CropBoxType.Square |
| gridLine | GridLine | 裁剪网格线 | - |
| backgroundColor | Color | 背景色 | `Color(0xff141414)` |
| maskColor | Color | 遮罩颜色 | `Color.fromRGBO(0, 0, 0, 0.5)` |
| cropBoxBorder | CropBoxBorder | 裁剪框样式，包含颜色、宽度和圆角信息 | `cropBoxBorder.width = 2` `cropBoxBorder.color = Colors.white` `cropBoxBorder.radius = Radius.circular(0)` |
| cropRectUpdateStart | Function | 裁剪区域开始变化时的回调 | - |
| cropRectUpdate | Function(Rect rect) | 裁剪区域变化时的回调 | - |
| cropRectUpdateEnd | Function(Rect rect) | 返回 | 必填 |

## 使用Demo
> 可参考 `git` 的 `example`，可以直接运行

#### git引入
```yaml
  crop_box:
    git:
      url: https://github.com/godaangel/flutter_crop_box.git
```

#### pub.dev引入
```yaml
  crop_box: ^0.1.6
```

#### 代码
> 更多属性参考`example`代码
```dart
import 'package:crop_box/crop_box.dart';

// ...

CropBox(
  // cropRect: Rect.fromLTRB(1 - 0.4083, 0.162, 1, 0.3078), // 2.4倍 随机位置
  // cropRect: Rect.fromLTRB(0, 0, 0.4083, 0.1457), //2.4倍，都是0,0
  // cropBoxType: CropBoxType.Circle,
  cropRect: Rect.fromLTRB(0, 0, 1, 0.3572), // 1倍
  clipSize: Size(200, 315),
  cropRatio: Size(16, 9),
  cropRectUpdateEnd: (rect) {
    print("裁剪区域最终确定 $rect");
  },
  cropRectUpdate: (rect) {
    print("裁剪区域变化 $rect");
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

### 导出图片

可以使用 `ImageCrop.getResult` 获取裁剪后图片的数据，并且使用这些数据去展示或导出图片

> more details in `example`

```dart
/// get origin image uint8List
Uint8List bytes = (await NetworkAssetBundle(Uri.parse(imageUrl))
  .load(imageUrl))
  .buffer
  .asUint8List();
/// get result uint8List
Uint8List result = await ImageCrop.getResult(
  clipRect: _resultRect, 
  image: bytes
);
```

## TODO

* [x] 动态变换裁剪框比例
* [x] 支持圆形裁剪框绘制
* [ ] 优化边界计算代码
* [x] 支持圆角裁剪框绘制
* [ ] 支持旋转
* [x] 支持网格线
* [x] 支持导出图片
