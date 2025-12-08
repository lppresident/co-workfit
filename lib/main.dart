import 'package:flutter/material.dart';
import 'package:co_workfit/shared/theme/app_theme.dart';
import 'package:co_workfit/features/workout/presentation/pages/dashboard_page.dart';

void main() {
  runApp(const CoWorkFitApp());
}

class CoWorkFitApp extends StatelessWidget {
  const CoWorkFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Co-WorkFit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
