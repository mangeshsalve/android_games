import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_services.dart';
import 'utils/app_colors.dart';

class PerfectStackApp extends StatelessWidget {
  const PerfectStackApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfect Stack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundBottom,
      ),
      home: HomeScreen(services: services),
    );
  }
}
