import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/home/home_screen.dart';
import 'core/app_colors.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation rapide non-bloquante pour affichage instantané
  SupabaseService.instance.init();

  runApp(const BmGoldApp());
}
class BmGoldApp extends StatelessWidget {
  const BmGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BM GOLD - Menu Café Lounge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.appBackground,
        primaryColor: AppColors.gold,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.goldLight,
          surface: AppColors.surfaceDark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
