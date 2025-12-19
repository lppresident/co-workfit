import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:co_workfit/core/config/firebase_config.dart';
import 'package:co_workfit/features/auth/data/models/user_model.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Firebase Auth 데이터소스
class FirebaseAuthDataSource {
  late final FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;
  late final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) {
    try {
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
      _firestore = firestore ?? FirebaseFirestore.instance;
      _googleSignIn = googleSignIn ?? GoogleSignIn();
      _initialized = true;
    } catch (e) {
      AppLogger.warning('FirebaseAuthDataSource', 'Firebase not initialized: $e');
      _initialized = false;
    }
  }

  /// Firebase 초기화 여부 확인
  bool get isInitialized => _initialized;

  /// 닉네임 사용 가능 여부 확인
  Future<Either<String, bool>> checkNicknameAvailability(String nickname) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      final nicknameDoc = await _firestore
          .collection(FirebaseConfig.nicknamesCollection)
          .doc(nickname)
          .get();

      // 문서가 존재하지 않으면 사용 가능
      return Right(!nicknameDoc.exists);
    } catch (e) {
      return Left('닉네임 확인에 실패했습니다: $e');
    }
  }

  /// 현재 로그인된 사용자 가져오기
  Future<Either<String, UserModel?>> getCurrentUser() async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Right(null);
      }

      // Firestore에서 사용자 데이터 가져오기
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Firestore에 사용자 데이터가 없으면 생성
        final temporaryNickname = _generateTemporaryNickname(firebaseUser.email!);
        final newUser = UserModel.fromFirebaseUser(
          firebaseUser.uid,
          firebaseUser.email!,
          firebaseUser.displayName,
          temporaryNickname,
          firebaseUser.photoURL,
        );
        await _createUserInFirestore(newUser);
        return Right(newUser);
      }

      return Right(UserModel.fromFirestore(userDoc));
    } catch (e) {
      return Left('현재 사용자 정보를 가져오는데 실패했습니다: $e');
    }
  }

  /// Google 로그인
  Future<Either<String, UserModel>> signInWithGoogle() async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return const Left('Google 로그인이 취소되었습니다.');
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return const Left('Google 로그인에 실패했습니다.');
      }

      // Firestore에서 사용자 데이터 가져오기 또는 생성
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      UserModel userModel;
      if (!userDoc.exists) {
        // 새 사용자 생성
        final temporaryNickname = _generateTemporaryNickname(userCredential.user!.email!);
        userModel = UserModel.fromFirebaseUser(
          userCredential.user!.uid,
          userCredential.user!.email!,
          userCredential.user!.displayName,
          temporaryNickname,
          userCredential.user!.photoURL,
        );
        await _createUserInFirestore(userModel);
      } else {
        userModel = UserModel.fromFirestore(userDoc);
        await _updateLastActive(userCredential.user!.uid);
      }

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left('Google 로그인에 실패했습니다: $e');
    }
  }

  /// Apple 로그인
  Future<Either<String, UserModel>> signInWithApple() async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      // Apple 로그인 플로우 시작
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase OAuthProvider 생성
      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase에 로그인
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return const Left('Apple 로그인에 실패했습니다.');
      }

      // Firestore에서 사용자 데이터 가져오기 또는 생성
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      UserModel userModel;
      if (!userDoc.exists) {
        // Apple은 처음 로그인 시에만 이름을 제공
        String? displayName = userCredential.user!.displayName;
        if (displayName == null && appleCredential.givenName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          if (displayName.isEmpty) {
            displayName = userCredential.user!.email?.split('@')[0];
          }
        }

        final email = userCredential.user!.email ?? 'apple_user_${userCredential.user!.uid}@privaterelay.appleid.com';
        final temporaryNickname = _generateTemporaryNickname(email);

        // 새 사용자 생성
        userModel = UserModel.fromFirebaseUser(
          userCredential.user!.uid,
          email,
          displayName,
          temporaryNickname,
          userCredential.user!.photoURL,
        );
        await _createUserInFirestore(userModel);
      } else {
        userModel = UserModel.fromFirestore(userDoc);
        await _updateLastActive(userCredential.user!.uid);
      }

      return Right(userModel);
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return const Left('Apple 로그인이 취소되었습니다.');
        case AuthorizationErrorCode.failed:
          return const Left('Apple 로그인에 실패했습니다.');
        case AuthorizationErrorCode.invalidResponse:
          return const Left('Apple 로그인 응답이 유효하지 않습니다.');
        case AuthorizationErrorCode.notHandled:
          return const Left('Apple 로그인 요청을 처리할 수 없습니다.');
        case AuthorizationErrorCode.unknown:
          return const Left('알 수 없는 Apple 로그인 오류가 발생했습니다.');
        default:
          return Left('Apple 로그인 오류: ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left('Apple 로그인에 실패했습니다: $e');
    }
  }

  /// 로그아웃
  Future<Either<String, void>> signOut() async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left('로그아웃에 실패했습니다: $e');
    }
  }

  /// 사용자 프로필 업데이트
  Future<Either<String, UserModel>> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? nickname,
  }) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left('로그인된 사용자가 없습니다.');
      }

      // 현재 사용자 데이터 가져오기
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return const Left('사용자 정보를 찾을 수 없습니다.');
      }

      final currentUser = UserModel.fromFirestore(userDoc);
      final currentNickname = currentUser.nickname;

      // Firebase Auth 프로필 업데이트
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // 닉네임이 제공되고 현재 닉네임과 다른 경우, 트랜잭션으로 업데이트
      if (nickname != null && nickname != currentNickname) {
        try {
          await _firestore.runTransaction((transaction) async {
            // 새 닉네임 문서 참조
            final newNicknameRef = _firestore
                .collection(FirebaseConfig.nicknamesCollection)
                .doc(nickname);

            // 이전 닉네임 문서 참조
            final oldNicknameRef = _firestore
                .collection(FirebaseConfig.nicknamesCollection)
                .doc(currentNickname);

            // 사용자 문서 참조
            final userRef = _firestore
                .collection(FirebaseConfig.usersCollection)
                .doc(userId);

            // 새 닉네임 중복 확인
            final newNicknameDoc = await transaction.get(newNicknameRef);
            if (newNicknameDoc.exists) {
              throw Exception('이미 사용 중인 닉네임입니다.');
            }

            // 이전 닉네임 문서 삭제
            transaction.delete(oldNicknameRef);

            // 새 닉네임 문서 생성
            transaction.set(newNicknameRef, {
              'userId': userId,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // 사용자 문서 업데이트
            final updates = <String, dynamic>{
              'nickname': nickname,
              'isNicknameSet': true,
            };
            if (displayName != null) updates['displayName'] = displayName;
            if (photoUrl != null) updates['photoUrl'] = photoUrl;

            transaction.update(userRef, updates);
          });
        } catch (e) {
          AppLogger.error('FirebaseAuthDataSource', 'Failed to update nickname: $e');
          return Left('닉네임 업데이트에 실패했습니다: $e');
        }
      } else {
        // 닉네임 변경이 없는 경우, 일반 업데이트
        final updates = <String, dynamic>{};
        if (displayName != null) updates['displayName'] = displayName;
        if (photoUrl != null) updates['photoUrl'] = photoUrl;

        if (updates.isNotEmpty) {
          await _firestore
              .collection(FirebaseConfig.usersCollection)
              .doc(userId)
              .update(updates);
        }
      }

      // 업데이트된 사용자 데이터 가져오기
      final updatedUserDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .get();

      return Right(UserModel.fromFirestore(updatedUserDoc));
    } catch (e) {
      AppLogger.error('FirebaseAuthDataSource', 'Failed to update profile: $e');
      return Left('프로필 업데이트에 실패했습니다: $e');
    }
  }

  /// Firestore에 사용자 생성 (트랜잭션 사용)
  Future<void> _createUserInFirestore(UserModel user) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 닉네임 문서 참조
        final nicknameRef = _firestore
            .collection(FirebaseConfig.nicknamesCollection)
            .doc(user.nickname);

        // 사용자 문서 참조
        final userRef = _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(user.id);

        // 닉네임 중복 확인
        final nicknameDoc = await transaction.get(nicknameRef);
        if (nicknameDoc.exists) {
          throw Exception('이미 사용 중인 닉네임입니다.');
        }

        // 사용자 문서 생성
        transaction.set(userRef, user.toFirestore());

        // 닉네임 문서 생성
        transaction.set(nicknameRef, {
          'userId': user.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      AppLogger.error('FirebaseAuthDataSource', 'Failed to create user in Firestore: $e');
      rethrow;
    }
  }

  /// 마지막 활동 시간 업데이트
  Future<void> _updateLastActive(String userId) async {
    await _firestore
        .collection(FirebaseConfig.usersCollection)
        .doc(userId)
        .update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  /// FirebaseAuthException 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'operation-not-allowed':
        return '이 인증 방식은 현재 사용할 수 없습니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 최소 6자 이상 입력해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
        return '존재하지 않는 사용자입니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }

  /// 임시 닉네임 생성 (이메일_4자리랜덤숫자)
  String _generateTemporaryNickname(String email) {
    final emailPrefix = email.split('@')[0];
    final random = Random();
    final randomDigits = random.nextInt(10000).toString().padLeft(4, '0');
    return '${emailPrefix}_$randomDigits';
  }

  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges {
    if (!_initialized) {
      return Stream.value(null);
    }
    return _firebaseAuth.authStateChanges();
  }
}
