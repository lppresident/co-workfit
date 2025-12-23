/// Garmin OAuth Credentials
class GarminCredentials {
  final String accessToken;
  final String tokenSecret;
  final String userId;
  final DateTime expiresAt;

  const GarminCredentials({
    required this.accessToken,
    required this.tokenSecret,
    required this.userId,
    required this.expiresAt,
  });

  /// 토큰이 만료되었는지 확인
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenSecret': tokenSecret,
      'userId': userId,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// JSON에서 생성
  factory GarminCredentials.fromJson(Map<String, dynamic> json) {
    return GarminCredentials(
      accessToken: json['accessToken'] as String,
      tokenSecret: json['tokenSecret'] as String,
      userId: json['userId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  String toString() {
    return 'GarminCredentials(userId: $userId, expired: $isExpired)';
  }
}
