import 'package:image/image.dart' as img; void main() { final i = img.Image(width: 10, height: 10); i.setPixelRgb(0,0,255,128,64); print(i.getPixel(0,0).r); }
