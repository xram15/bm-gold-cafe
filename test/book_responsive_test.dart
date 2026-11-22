import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yocca3/data/menus/bm_menu.dart';
import 'package:yocca3/features/book/book_screen.dart';
import 'package:yocca3/features/book/widgets/vertical_book_flip_view.dart';
import 'package:yocca3/features/book/widgets/vertical_book_page.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1280, 800),
  ]) {
    testWidgets('book fits and flips at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: BookScreen(book: bmMenu)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final page = find.byType(VerticalBookPage);
      final pageHeight =
          tester.getBottomRight(page).dy - tester.getTopLeft(page).dy;
      expect(pageHeight, lessThanOrEqualTo(size.height));
      expect(tester.getTopLeft(page).dy, lessThan(75));
      expect(
        (tester.getCenter(find.byTooltip('Page suivante')).dy -
                tester.getCenter(page).dy)
            .abs(),
        lessThan(3),
      );
      if (size == const Size(390, 844)) {
        expect(pageHeight, greaterThan(650));
      }

      final book = tester.state<VerticalBookFlipViewState>(
        find.byType(VerticalBookFlipView),
      );
      book.flipForward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      book.flipForward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text('Page 3 / 7'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
