import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';

/// 인증 레포지토리 인터페이스
abstract class AuthRepository {
  /// 현재 로그인된 사용자 가져오기
  Future<Either<String, UserEntity?>> getCurrentUser();

  /// Google 로그인
  Future<Either<String, UserEntity>> signInWithGoogle();

  /// Apple 로그인
  Future<Either<String, UserEntity>> signInWithApple();

  /// 닉네임 사용 가능 여부 확인
  Future<Either<String, bool>> checkNicknameAvailability(String nickname);

  /// 로그아웃
  Future<Either<String, void>> signOut();

  /// 사용자 프로필 업데이트
  Future<Either<String, UserEntity>> updateProfile({
    required String userId,
    String? displayName,
    String? nickname,
    String? photoUrl,
  });

  /// 인증 상태 변경 스트림
  Stream<firebase_auth.User?> get authStateChanges;
}
