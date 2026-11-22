import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yocca3/data/models/book_model.dart';
import 'package:yocca3/data/models/category_model.dart';
import 'package:yocca3/data/models/page_model.dart';
import 'package:yocca3/data/models/product_model.dart';
import 'package:yocca3/features/book/widgets/vertical_book_flip_view.dart';

void main() {
  testWidgets('larger breakfast item names fit next to the price', (
    tester,
  ) async {
    const description = 'Café au choix - viennoiserie - eau 1/2 - jus';
    const book = Book(
      id: 'test',
      title: 'Menu',
      iconEmoji: '',
      color: Colors.black,
      pages: [
        BookPage(
          style: PageStyle.alternatingPhotos,
          category: MenuCategory(
            title: 'Petit déjeuner & brunch',
            products: [
              Product(
                name: 'Buongiorno (1 personne)',
                price: '6.500',
                description: description,
              ),
              Product(
                name: 'BM (2 personnes)',
                price: '25.000',
                description: description,
              ),
            ],
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 500,
              child: VerticalBookFlipView(book: book),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final item = tester.widget<Text>(find.text('BUONGIORNO (1 PERSONNE)'));
    final desc = tester.widgetList<Text>(find.text(description)).first;
    expect(item.style!.fontSize, 21);
    expect(item.maxLines, 2);
    expect(desc.style!.color, const Color(0xFFA9A9A9));
    expect(tester.takeException(), isNull);
  });
}
