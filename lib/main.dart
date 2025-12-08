import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/shared/theme/app_theme.dart';
import 'package:co_workfit/features/workout/presentation/pages/dashboard_page.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await di.initializeDependencies();

  runApp(const CoWorkFitApp());
}

class CoWorkFitApp extends StatelessWidget {
  const CoWorkFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkoutBloc>(
          create: (_) => di.sl<WorkoutBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Co-WorkFit',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const DashboardPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
