import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/auth/presentation/bloc/nickname_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/nickname_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/nickname_state.dart';
import 'package:co_workfit/core/di/injection.dart';

/// 첫 로그인 시 닉네임 설정 페이지
class SetupNicknamePage extends StatefulWidget {
  final String userId;
  final String currentNickname;

  const SetupNicknamePage({
    super.key,
    required this.userId,
    required this.currentNickname,
  });

  @override
  State<SetupNicknamePage> createState() => _SetupNicknamePageState();
}

class _SetupNicknamePageState extends State<SetupNicknamePage> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nicknameBloc = sl<NicknameBloc>();
  String? _lastCheckedNickname;

  @override
  void initState() {
    super.initState();
    // 임시 닉네임을 기본값으로 설정
    _nicknameController.text = widget.currentNickname.replaceAll('_temp', '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameBloc.close();
    super.dispose();
  }

  void _checkNickname() {
    // 폼 유효성 검사를 먼저 실행하여 빨간색 테두리 표시
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nickname = _nicknameController.text.trim();
    _nicknameBloc.add(CheckNicknameAvailabilityRequested(nickname));
    _lastCheckedNickname = nickname;
  }

  void _submitNickname(bool? isAvailable) {
    if (_formKey.currentState!.validate()) {
      final nickname = _nicknameController.text.trim();

      if (isAvailable != true || _lastCheckedNickname != nickname) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임 중복 확인을 먼저 해주세요')),
        );
        return;
      }

      context.read<AuthBloc>().add(UpdateNicknameRequested(
        userId: widget.userId,
        nickname: nickname,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('닉네임 설정'),
        automaticallyImplyLeading: false,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                // 닉네임 설정 완료 후에만 메인 페이지로 이동
                if (state.user.isNicknameSet) {
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                }
              } else if (state is AuthError) {
                // 에러 발생 시에만 토스트 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
          BlocListener<NicknameBloc, NicknameState>(
            bloc: _nicknameBloc,
            listener: (context, state) {
              if (state is NicknameCheckError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<NicknameBloc, NicknameState>(
          bloc: _nicknameBloc,
          builder: (context, nicknameState) {
            bool isChecking = nicknameState is NicknameCheckingAvailability;
            bool? isAvailable;

            if (nicknameState is NicknameAvailabilityChecked) {
              isAvailable = nicknameState.isAvailable;
            }

            return _buildBody(isChecking, isAvailable);
          },
        ),
      ),
    );
  }

  Widget _buildBody(bool isChecking, bool? isAvailable) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              '환영합니다!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '사용하실 닉네임을 설정해주세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                hintText: '2-20자 (한글, 영문, 숫자, _, - 사용 가능)',
                border: const OutlineInputBorder(),
                suffixIcon: _buildSuffixIcon(isChecking, isAvailable),
              ),
              maxLength: 20,
              onChanged: (value) {
                // 입력이 변경되면 중복 확인 상태 초기화
                if (_lastCheckedNickname != value.trim()) {
                  _nicknameBloc.add(const ResetNicknameCheck());
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '닉네임을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '닉네임은 2자 이상이어야 합니다';
                }
                if (value.trim().length > 20) {
                  return '닉네임은 20자 이하여야 합니다';
                }
                final RegExp validCharacters = RegExp(r'^[가-힣a-zA-Z0-9_-]+$');
                if (!validCharacters.hasMatch(value.trim())) {
                  return '한글, 영문, 숫자, _, - 만 사용 가능합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isChecking ? null : _checkNickname,
              child: isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('중복 확인'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isAvailable == true ? () => _submitNickname(isAvailable) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '* 닉네임은 나중에 프로필에서 변경할 수 있습니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isChecking, bool? isAvailable) {
    if (isChecking) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (isAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (isAvailable == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }

    return null;
  }
}
