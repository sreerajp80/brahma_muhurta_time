// File Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/calculation_service.dart';
import 'providers/brahma_muhurta_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data through CalculationService
  CalculationService.initializeTimezones();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const BrahmaMuhurtaApp());
}

class BrahmaMuhurtaApp extends StatelessWidget {
  const BrahmaMuhurtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrahmaMuhurtaProvider()),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'Brahma Muhurta',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B4E71),
            brightness: Brightness.light,
            primary: const Color(0xFF6B4E71),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFF3E5F5),
            onPrimaryContainer: const Color(0xFF4A148C),
            secondary: const Color(0xFF8BC34A),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFDCEDC8),
            onSecondaryContainer: const Color(0xFF33691E),
            tertiary: const Color(0xFFFF9800),
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFFFE0B2),
            onTertiaryContainer: const Color(0xFFE65100),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
