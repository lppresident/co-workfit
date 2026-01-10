import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/nickname_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/nickname_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/nickname_state.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_event.dart';
import 'package:co_workfit/core/di/injection.dart' as di;

/// 닉네임 변경 다이얼로그
class EditNicknameDialog extends StatefulWidget {
  final String currentNickname;

  const EditNicknameDialog({
    super.key,
    required this.currentNickname,
  });

  @override
  State<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<EditNicknameDialog> {
  late final TextEditingController _controller;
  late final NicknameBloc _nicknameBloc;
  String? _lastCheckedNickname;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNickname);
    _nicknameBloc = di.sl<NicknameBloc>();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nicknameBloc.close();
    super.dispose();
  }

  void _checkNickname() {
    final nickname = _controller.text.trim();

    // 현재 닉네임과 동일한 경우
    if (nickname == widget.currentNickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 닉네임과 동일합니다')),
      );
      return;
    }

    // 빈 값 체크
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요')),
      );
      return;
    }

    // 길이 체크
    if (nickname.length < 2 || nickname.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임은 2~12자로 입력해주세요')),
      );
      return;
    }

    _nicknameBloc.add(CheckNicknameAvailabilityRequested(nickname));
    _lastCheckedNickname = nickname;
  }

  void _submitNickname(bool? isAvailable) {
    final nickname = _controller.text.trim();

    if (nickname == widget.currentNickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 닉네임과 동일합니다')),
      );
      return;
    }

    if (isAvailable != true || _lastCheckedNickname != nickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 중복 확인을 먼저 해주세요')),
      );
      return;
    }

    context.read<ProfileBloc>().add(UpdateDisplayName(nickname));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NicknameBloc>.value(
      value: _nicknameBloc,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('닉네임 변경'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '새 닉네임을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                autofocus: true,
                onChanged: (_) {
                  // 입력이 변경되면 중복 확인 초기화
                  _nicknameBloc.add(ResetNicknameCheck());
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<NicknameBloc, NicknameState>(
                builder: (context, state) {
                  if (state is NicknameCheckingAvailability) {
                    return const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('중복 확인 중...', style: TextStyle(fontSize: 12)),
                      ],
                    );
                  } else if (state is NicknameAvailabilityChecked) {
                    return Row(
                      children: [
                        Icon(
                          state.isAvailable ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: state.isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.isAvailable
                              ? '사용 가능한 닉네임입니다'
                              : '이미 사용 중인 닉네임입니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: state.isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _checkNickname,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('중복 확인'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          BlocBuilder<NicknameBloc, NicknameState>(
            builder: (context, state) {
              final isAvailable = state is NicknameAvailabilityChecked && state.isAvailable;
              return ElevatedButton(
                onPressed: () => _submitNickname(isAvailable),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('저장'),
              );
            },
          ),
        ],
      ),
    );
  }
}
