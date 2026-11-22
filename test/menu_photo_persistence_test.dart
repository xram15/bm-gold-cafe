import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yocca3/data/menus/bm_menu.dart';
import 'package:yocca3/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved menu photo survives a local reload', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SupabaseService.instance;
    service.currentBookNotifier.value = bmMenu;
    const photo = 'data:image/png;base64,aGVsbG8=';
    await service.updatePagePhotos(0, firstAlternatingPhotoPath: photo);
    await service.saveMenuToLocalStorage();
    service.currentBookNotifier.value = bmMenu;
    await service.loadMenuFromLocalStorage();
    expect(service.currentBook.pages.first.firstAlternatingPhotoPath, photo);
    service.currentBookNotifier.value = bmMenu;
  });
}
