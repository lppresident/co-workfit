import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_core/firebase_core.dart'; // 임시 주석처리 - 초기 로딩 속도 개선
import 'package:co_workfit/shared/theme/app_theme.dart';
import 'package:co_workfit/features/workout/presentation/pages/dashboard_page.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
// import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart'; // 임시 주석처리 - Firebase 의존성
// import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart'; // 임시 주석처리 - Firebase 의존성

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (임시 주석처리 - 초기 로딩 속도 개선)
  // NOTE: Firebase 설정 파일 필요:
  // - iOS: ios/Runner/GoogleService-Info.plist
  // - Android: android/app/google-services.json
  // FlutterFire CLI로 자동 설정: flutter pub global activate flutterfire_cli && flutterfire configure
  // try {
  //   await Firebase.initializeApp();
  //   print('[Firebase] Firebase initialized successfully');
  // } catch (e) {
  //   print('[Firebase] Firebase initialization failed: $e');
  //   print('[Firebase] 앱은 Firebase 없이 실행되지만 인증/소셜 기능은 작동하지 않습니다.');
  // }

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
        // BlocProvider<AuthBloc>( // 임시 주석처리 - Firebase 의존성
        //   create: (_) => di.sl<AuthBloc>()..add(const AuthCheckRequested()),
        // ),
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
