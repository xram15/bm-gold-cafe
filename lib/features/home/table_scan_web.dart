import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('BarcodeDetector')
extension type _BarcodeDetector._(JSObject _) implements JSObject {
  external _BarcodeDetector(JSObject options);
  external JSPromise<JSArray<JSObject>> detect(JSObject source);
}

/// Scan caméra d'un QR de table (web). Retourne l'identifiant de table, ou null
/// si annulé / non supporté (l'appelant retombe alors sur le choix de table).
Future<String?> scanTableQr() async {
  if (globalContext['BarcodeDetector'] == null) return null;
  final mediaDevices = web.window.navigator.mediaDevices;

  web.MediaStream? stream;
  web.HTMLDivElement? overlay;
  bool cancelled = false;
  final completer = Completer<String?>();

  void cleanup() {
    try {
      stream?.getTracks().toDart.forEach((t) => t.stop());
    } catch (_) {}
    overlay?.remove();
  }

  void finish(String? value) {
    if (completer.isCompleted) return;
    cleanup();
    completer.complete(value);
  }

  try {
    stream = await mediaDevices
        .getUserMedia({
          'video': {'facingMode': 'environment'},
          'audio': false,
        }.jsify() as web.MediaStreamConstraints)
        .toDart;

    final detector = _BarcodeDetector({'formats': ['qr_code']}.jsify() as JSObject);

    overlay = web.document.createElement('div') as web.HTMLDivElement;
    overlay.style.cssText =
        'position:fixed;inset:0;z-index:99999;background:#000;display:flex;'
        'flex-direction:column;align-items:center;justify-content:center;gap:16px;';

    final video = web.document.createElement('video') as web.HTMLVideoElement;
    video.srcObject = stream;
    video.muted = true;
    video.setAttribute('playsinline', 'true');
    video.style.cssText =
        'width:100%;max-width:480px;object-fit:cover;border-radius:12px;';
    await video.play().toDart;

    final hint = web.document.createElement('div') as web.HTMLDivElement;
    hint.textContent = 'Visez le QR code d\'une autre table…';
    hint.style.cssText =
        'color:#E5C158;font:600 15px sans-serif;text-align:center;padding:0 16px;';

    final cancel = web.document.createElement('button') as web.HTMLButtonElement;
    cancel.textContent = 'Annuler';
    cancel.style.cssText =
        'padding:10px 28px;border-radius:24px;border:1px solid #C59B4B;'
        'background:transparent;color:#E5C158;font:600 14px sans-serif;cursor:pointer;';
    cancel.onClick.listen((_) {
      cancelled = true;
      finish(null);
    });

    overlay.append(video);
    overlay.append(hint);
    overlay.append(cancel);
    web.document.body?.append(overlay);

    while (!cancelled && !completer.isCompleted) {
      try {
        final results = (await detector.detect(video).toDart).toDart;
        if (results.isNotEmpty) {
          final raw = results.first.getProperty<JSString>('rawValue'.toJS).toDart;
          if (raw.isNotEmpty) {
            finish(Uri.tryParse(raw)?.queryParameters['table'] ?? raw);
            break;
          }
        }
      } catch (_) {
        // image pas encore prête : on réessaie
      }
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    finish(null);
  } catch (_) {
    finish(null);
  }
  return completer.future;
}
