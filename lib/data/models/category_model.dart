import 'product_model.dart';

class MenuCategory {
  final String title;
  final List<Product> products;

  const MenuCategory({
    required this.title,
    required this.products,
  });
}
