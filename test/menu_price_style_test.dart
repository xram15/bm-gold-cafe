import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yocca3/data/models/book_model.dart';
import 'package:yocca3/data/models/category_model.dart';
import 'package:yocca3/data/models/page_model.dart';
import 'package:yocca3/data/models/product_model.dart';
import 'package:yocca3/features/book/widgets/vertical_book_page.dart';

void main() {
  testWidgets('prices display one TND badge and preserve other text', (tester) async {
    const book = Book(
      id: 'test', title: 'Menu', iconEmoji: '', color: Colors.black,
      pages: [BookPage(style: PageStyle.sectionsWithBackground, category: MenuCategory(title: 'Café', products: [
        Product(name: 'A', price: '6.500 DT'),
        Product(name: 'B', price: '11 TND'),
        Product(name: 'C', price: '€15'),
      ]))],
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 390, height: 700, child: VerticalBookPage(book: book, pageIndex: 0, totalPages: 1))))));
    await tester.pump();
    expect(find.text('6.500'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('TND'), findsNWidgets(2));
    expect(find.text('€15'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
