import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';

/// 인증 레포지토리 인터페이스
abstract class AuthRepository {
  /// 현재 로그인된 사용자 가져오기
  Future<Either<String, UserEntity?>> getCurrentUser();

  /// 이메일/비밀번호로 회원가입
  Future<Either<String, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// 이메일/비밀번호로 로그인
  Future<Either<String, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Google 로그인
  Future<Either<String, UserEntity>> signInWithGoogle();

  /// 로그아웃
  Future<Either<String, void>> signOut();

  /// 비밀번호 재설정 이메일 전송
  Future<Either<String, void>> sendPasswordResetEmail(String email);

  /// 사용자 프로필 업데이트
  Future<Either<String, UserEntity>> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  });

  /// 인증 상태 변경 스트림
  Stream<firebase_auth.User?> get authStateChanges;
}
