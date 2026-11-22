import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadQr(Uint8List bytes, String filename) {
  final link = web.HTMLAnchorElement()
    ..href = 'data:image/png;base64,${base64Encode(bytes)}'
    ..download = filename;
  link.click();
}
