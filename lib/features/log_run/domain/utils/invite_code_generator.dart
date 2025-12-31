import 'dart:math';

/// 챌린지 초대 코드 생성기
class InviteCodeGenerator {
  // 혼동하기 쉬운 문자 제외: O(오), 0(영), I(아이), 1(일), L(엘)
  static const String _chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const int _codeLength = 6;

  static final Random _random = Random();

  /// 6자리 랜덤 초대 코드 생성
  ///
  /// 예: A3K9M2, B7P4QX
  static String generate() {
    return List.generate(
      _codeLength,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }

  /// 초대 코드 검증
  ///
  /// - 6자리 길이
  /// - 허용된 문자만 포함
  static bool isValid(String code) {
    if (code.length != _codeLength) return false;
    return code.split('').every((char) => _chars.contains(char.toUpperCase()));
  }

  /// 입력된 코드를 표준화 (대문자 변환)
  static String normalize(String code) {
    return code.toUpperCase().trim();
  }
}
