import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yocca3/features/admin/reservations_screen.dart';

void main() {
  testWidgets('table QR dialog opens without a layout error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTableQrDialog(context, {
                'id': 'c79f4fbf-3131-400d-a57d-60e2a2f471ed',
                'name': 'Table 1',
              }),
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('QR code · Table 1'), findsOneWidget);
    expect(find.text('Table'), findsOneWidget);
    expect(find.text('Table 1'), findsOneWidget);
    if (kIsWeb) {
      expect(find.text('Télécharger'), findsOneWidget);
      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
