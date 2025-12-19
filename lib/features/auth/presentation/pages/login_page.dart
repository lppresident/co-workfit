import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/auth/presentation/widgets/auth_button.dart';
import 'package:co_workfit/features/auth/presentation/pages/setup_nickname_page.dart';

/// 로그인 화면
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(const SignInWithGoogleRequested());
  }

  void _handleAppleSignIn() {
    context.read<AuthBloc>().add(const SignInWithAppleRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Authenticated) {
            // 첫 로그인 확인: 닉네임을 설정하지 않았으면 닉네임 설정 페이지로
            if (!state.user.isNicknameSet) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SetupNicknamePage(
                    userId: state.user.id,
                    currentNickname: state.user.nickname,
                  ),
                ),
              );
            } else {
              // 닉네임을 설정한 사용자는 메인 화면으로 이동
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 앱 로고 또는 타이틀
                    const Icon(
                      Icons.fitness_center,
                      size: 100,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Co-WorkFit',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '함께하는 운동, 더 즐겁게',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),

                    // Google 로그인 버튼
                    AuthButton(
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.login, size: 24);
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text('Google로 계속하기'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Apple 로그인 버튼
                    AuthButton(
                      onPressed: isLoading ? null : _handleAppleSignIn,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apple, size: 24),
                          const SizedBox(width: 12),
                          const Text('Apple로 계속하기'),
                        ],
                      ),
                    ),

                    if (isLoading) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
