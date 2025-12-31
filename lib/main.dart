import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:co_workfit/shared/theme/app_theme.dart';
import 'package:co_workfit/features/workout/presentation/pages/dashboard_page.dart';
import 'package:co_workfit/features/auth/presentation/pages/login_page.dart';
import 'package:co_workfit/features/auth/presentation/pages/setup_nickname_page.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_bloc.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_event.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_state.dart';
import 'package:co_workfit/features/wood/presentation/widgets/settlement_dialog.dart';
import 'package:co_workfit/features/craft/presentation/bloc/craft_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/core/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Korean locale for date formatting
  await initializeDateFormatting('ko', null);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase', 'Firebase initialized successfully');
  } catch (e) {
    AppLogger.error('Firebase', 'Firebase initialization failed', e);
    AppLogger.warning('Firebase', '앱은 Firebase 없이 실행되지만 인증/소셜 기능은 작동하지 않습니다.');
  }

  // Initialize dependencies
  await di.initializeDependencies();

  // Initialize deep link service
  await DeepLinkService().initialize();

  runApp(const CoWorkFitApp());
}

class CoWorkFitApp extends StatefulWidget {
  const CoWorkFitApp({super.key});

  @override
  State<CoWorkFitApp> createState() => _CoWorkFitAppState();
}

class _CoWorkFitAppState extends State<CoWorkFitApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<DeepLinkData>? _deepLinkSubscription;
  StreamSubscription<LogRunState>? _logRunStateSubscription;
  DeepLinkData? _pendingDeepLink;
  bool _isJoiningFromDeepLink = false;

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    _deepLinkSubscription = DeepLinkService().deepLinkStream.listen((data) {
      AppLogger.info('CoWorkFitApp', 'Received deep link: ${data.type}');
      _handleDeepLink(data);
    });
  }

  void _setupLogRunStateListener(BuildContext context) {
    _logRunStateSubscription?.cancel();
    _logRunStateSubscription = context.read<LogRunBloc>().stream.listen((state) {
      if (!_isJoiningFromDeepLink) return;

      if (state is ChallengeJoined) {
        _isJoiningFromDeepLink = false;
        _showResultSnackBar(context, '챌린지에 참가했습니다! 🎉', Colors.green);
        // 통나무런 탭으로 이동하도록 새로고침
        context.read<LogRunBloc>().add(LoadChallenges(
          (context.read<AuthBloc>().state as Authenticated).user.id,
        ));
      } else if (state is LogRunError) {
        _isJoiningFromDeepLink = false;
        _showResultSnackBar(context, state.message, Colors.red);
      }
    });
  }

  void _showResultSnackBar(BuildContext context, String message, Color color) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleDeepLink(DeepLinkData data) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      // 아직 앱이 준비되지 않은 경우 대기
      _pendingDeepLink = data;
      return;
    }

    switch (data.type) {
      case DeepLinkType.logRunJoin:
        final inviteCode = data.data['inviteCode'] as String;
        _showJoinChallengeDialog(context, inviteCode);
        break;
    }
  }

  void _showJoinChallengeDialog(BuildContext context, String inviteCode) {
    // 인증 상태 확인
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('챌린지에 참가하려면 먼저 로그인해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // LogRunBloc 상태 리스너 설정
    _setupLogRunStateListener(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🏃 통나무런 초대'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('초대 코드: $inviteCode'),
            const SizedBox(height: 12),
            const Text('이 챌린지에 참가하시겠습니까?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _isJoiningFromDeepLink = true;
              context.read<LogRunBloc>().add(
                    JoinChallengeByCode(
                      inviteCode: inviteCode,
                      userId: authState.user.id,
                      userNickname: authState.user.nickname,
                    ),
                  );
            },
            child: const Text('참가하기'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _logRunStateSubscription?.cancel();
    super.dispose();
  }

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
        BlocProvider<SocialBloc>(
          create: (_) => di.sl<SocialBloc>(),
        ),
        BlocProvider<LeaderboardBloc>(
          create: (_) => di.sl<LeaderboardBloc>(),
        ),
        BlocProvider<LogRunBloc>(
          create: (_) => di.sl<LogRunBloc>(),
        ),
        BlocProvider<WoodBloc>(
          create: (_) => di.sl<WoodBloc>(),
        ),
        BlocProvider<CraftBloc>(
          create: (_) => di.sl<CraftBloc>(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Co-WorkFit',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                // 인증 완료 후 대기 중인 딥링크 처리
                if (state is Authenticated && _pendingDeepLink != null) {
                  final pending = _pendingDeepLink!;
                  _pendingDeepLink = null;
                  // 약간의 딜레이 후 딥링크 처리 (UI 준비 대기)
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _handleDeepLink(pending);
                  });
                }

                // 인증 완료 시 WoodBloc 초기화 및 정산 체크
                if (state is Authenticated) {
                  final woodBloc = context.read<WoodBloc>();
                  woodBloc.setUserId(state.user.id);
                  woodBloc.add(const LoadWoodSummary());
                  woodBloc.add(const CheckPendingSettlementsEvent());
                }
              },
            ),
            BlocListener<WoodBloc, WoodState>(
              listener: (context, state) {
                // 정산 결과가 있으면 다이얼로그 표시
                if (state.shouldShowSettlementDialog &&
                    state.pendingSettlementResult != null) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => SettlementDialog(
                      summary: state.pendingSettlementResult!,
                      onDismiss: () {
                        Navigator.of(context).pop();
                        context.read<WoodBloc>().add(const DismissSettlementDialog());
                      },
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                // 닉네임을 설정하지 않았으면 닉네임 설정 페이지로
                if (!state.user.isNicknameSet) {
                  return SetupNicknamePage(
                    userId: state.user.id,
                    currentNickname: state.user.nickname,
                  );
                }
                // 닉네임을 설정한 사용자는 메인 화면으로
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
