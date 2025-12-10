import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:co_workfit/shared/theme/app_theme.dart';
import 'package:co_workfit/features/workout/presentation/pages/dashboard_page.dart';
import 'package:co_workfit/features/auth/presentation/pages/login_page.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[Firebase] Firebase initialized successfully');
  } catch (e) {
    print('[Firebase] Firebase initialization failed: $e');
    print('[Firebase] 앱은 Firebase 없이 실행되지만 인증/소셜 기능은 작동하지 않습니다.');
  }

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
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => di.sl<ProfileBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Co-WorkFit',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return const DashboardPage();
            } else if (state is Unauthenticated) {
              return const LoginPage();
            } else if (state is AuthError) {
              return const LoginPage();
            }
            // AuthInitial or AuthLoading
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
        routes: {
          '/dashboard': (context) => const DashboardPage(),
          '/login': (context) => const LoginPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
