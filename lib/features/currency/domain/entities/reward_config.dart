import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';

/// 재화별 보상 설정 인터페이스
/// 
/// 새로운 재화 추가 시 이 인터페이스를 구현하여 보상 로직 정의
abstract class RewardConfig {
  /// 재화 타입
  CurrencyType get currencyType;
  
  /// 지원하는 운동 타입 목록
  List<ChallengeType> get supportedChallengeTypes;
  
  // ========== 개인 운동 보상 ==========
  
  /// 기본 보상
  int get personalBase;
  
  /// 단위당 보상 (거리 km 또는 점수당)
  double get personalPerUnit;
  
  // ========== 챌린지 기여 보상 ==========
  
  /// 기여 단위당 보상
  double get contributionPerUnit;
  
  /// 첫 기여 보너스
  int get firstContributionBonus;
  
  // ========== 챌린지 성공 보상 ==========
  
  /// 완료 보너스
  int get completionBonus;
  
  /// MVP 보너스
  int get mvpBonus;
  
  /// 참가자당 협력 보너스
  int get cooperationPerParticipant;
  
  /// 협력 보너스 최대값
  int get maxCooperationBonus;
  
  // ========== 개인 운동 기본 보상 (챌린지 없을 때) ==========
  
  /// 개인 운동 기본 보상
  int get soloWorkoutBase;
  
  /// 개인 운동 단위당 보상
  double get soloWorkoutPerUnit;
  
  /// 개인 운동 최대 보상
  int get soloWorkoutMaxReward;
  
  // ========== 정산 관련 ==========
  
  /// 보상 수령 가능 기간 (일)
  int get settlementExpirationDays;
  
  // ========== 마일스톤 ==========
  
  /// 마일스톤 보상 계산
  /// [value] 거리(km) 또는 점수
  /// Returns: 마일스톤 보너스 (없으면 0)
  int calculateMilestoneBonus(double value);
  
  /// 마일스톤 이름 반환
  String? getMilestoneName(double value);
  
  /// 해당 운동 타입을 지원하는지 확인
  bool supportsChallengeType(ChallengeType type);
}

/// 통나무(Wood) 보상 설정
class WoodRewardConfig implements RewardConfig {
  const WoodRewardConfig();
  
  @override
  CurrencyType get currencyType => CurrencyType.wood;
  
  @override
  List<ChallengeType> get supportedChallengeTypes => [ChallengeType.running];
  
  // 개인 운동 보상
  @override
  int get personalBase => 5;
  @override
  double get personalPerUnit => 2.0; // km당
  
  // 챌린지 기여 보상
  @override
  double get contributionPerUnit => 1.0; // km당
  @override
  int get firstContributionBonus => 5;
  
  // 챌린지 성공 보상
  @override
  int get completionBonus => 30;
  @override
  int get mvpBonus => 20;
  @override
  int get cooperationPerParticipant => 3;
  @override
  int get maxCooperationBonus => 30;
  
  // 개인 운동 기본 보상
  @override
  int get soloWorkoutBase => 3;
  @override
  double get soloWorkoutPerUnit => 1.0; // km당
  @override
  int get soloWorkoutMaxReward => 20;
  
  // 정산 관련
  @override
  int get settlementExpirationDays => 7;
  
  @override
  bool supportsChallengeType(ChallengeType type) {
    return supportedChallengeTypes.contains(type);
  }
  
  @override
  int calculateMilestoneBonus(double distanceKm) {
    if (distanceKm >= 42.195) return 50; // 풀마라톤
    if (distanceKm >= 21.0975) return 30; // 하프마라톤
    if (distanceKm >= 10) return 10; // 10km
    return 0;
  }
  
  @override
  String? getMilestoneName(double distanceKm) {
    if (distanceKm >= 42.195) return '풀마라톤';
    if (distanceKm >= 21.0975) return '하프마라톤';
    if (distanceKm >= 10) return '10km';
    return null;
  }
}

/// 쇠(Iron) 보상 설정
class IronRewardConfig implements RewardConfig {
  const IronRewardConfig();
  
  @override
  CurrencyType get currencyType => CurrencyType.iron;
  
  @override
  List<ChallengeType> get supportedChallengeTypes => [ChallengeType.strengthTraining];
  
  // 개인 운동 보상
  @override
  int get personalBase => 5;
  @override
  double get personalPerUnit => 0.2; // 점수당
  
  // 챌린지 기여 보상
  @override
  double get contributionPerUnit => 0.1; // 점수당
  @override
  int get firstContributionBonus => 5;
  
  // 챌린지 성공 보상
  @override
  int get completionBonus => 30;
  @override
  int get mvpBonus => 20;
  @override
  int get cooperationPerParticipant => 2;
  @override
  int get maxCooperationBonus => 10;
  
  // 개인 운동 기본 보상
  @override
  int get soloWorkoutBase => 3;
  @override
  double get soloWorkoutPerUnit => 0.1; // 점수당
  @override
  int get soloWorkoutMaxReward => 15;
  
  // 정산 관련
  @override
  int get settlementExpirationDays => 7;
  
  @override
  bool supportsChallengeType(ChallengeType type) {
    return supportedChallengeTypes.contains(type);
  }
  
  @override
  int calculateMilestoneBonus(double score) {
    if (score >= 1200) return 20;
    if (score >= 600) return 10;
    if (score >= 300) return 5;
    return 0;
  }
  
  @override
  String? getMilestoneName(double score) {
    if (score >= 1200) return '1,200점';
    if (score >= 600) return '600점';
    if (score >= 300) return '300점';
    return null;
  }
}

/// 흙(Soil) 보상 설정 - 기타 운동 (걷기, 수영, 요가 등)
class SoilRewardConfig implements RewardConfig {
  const SoilRewardConfig();
  
  @override
  CurrencyType get currencyType => CurrencyType.soil;
  
  @override
  List<ChallengeType> get supportedChallengeTypes => [ChallengeType.other];
  
  // 개인 운동 보상 (시간 기반, 분당)
  @override
  int get personalBase => 3;
  @override
  double get personalPerUnit => 0.1; // 분당
  
  // 챌린지 기여 보상
  @override
  double get contributionPerUnit => 0.05; // 분당
  @override
  int get firstContributionBonus => 3;
  
  // 챌린지 성공 보상
  @override
  int get completionBonus => 20;
  @override
  int get mvpBonus => 15;
  @override
  int get cooperationPerParticipant => 2;
  @override
  int get maxCooperationBonus => 10;
  
  // 개인 운동 기본 보상
  @override
  int get soloWorkoutBase => 2;
  @override
  double get soloWorkoutPerUnit => 0.05; // 분당
  @override
  int get soloWorkoutMaxReward => 10;
  
  // 정산 관련
  @override
  int get settlementExpirationDays => 7;
  
  @override
  bool supportsChallengeType(ChallengeType type) {
    return supportedChallengeTypes.contains(type);
  }
  
  @override
  int calculateMilestoneBonus(double minutes) {
    if (minutes >= 180) return 10; // 3시간
    if (minutes >= 90) return 5;  // 1.5시간
    if (minutes >= 60) return 3;  // 1시간
    return 0;
  }
  
  @override
  String? getMilestoneName(double minutes) {
    if (minutes >= 180) return '3시간';
    if (minutes >= 90) return '1.5시간';
    if (minutes >= 60) return '1시간';
    return null;
  }
}

/// 재화 설정 레지스트리
/// 
/// 모든 재화 설정을 관리하는 중앙 레지스트리
class CurrencyConfigRegistry {
  static final Map<CurrencyType, RewardConfig> _configs = {
    CurrencyType.wood: const WoodRewardConfig(),
    CurrencyType.iron: const IronRewardConfig(),
    CurrencyType.soil: const SoilRewardConfig(),
  };
  
  /// 재화 타입에 해당하는 설정 반환
  static RewardConfig getConfig(CurrencyType type) {
    final config = _configs[type];
    if (config == null) {
      throw ArgumentError('No config found for currency type: $type');
    }
    return config;
  }
  
  /// 챌린지 타입에 해당하는 재화 설정 반환
  static RewardConfig? getConfigForChallengeType(ChallengeType challengeType) {
    for (final config in _configs.values) {
      if (config.supportsChallengeType(challengeType)) {
        return config;
      }
    }
    return null;
  }
  
  /// 모든 재화 설정 반환
  static List<RewardConfig> get allConfigs => _configs.values.toList();
  
  /// 모든 재화 타입 반환
  static List<CurrencyType> get allCurrencyTypes => _configs.keys.toList();
  
  /// 새 재화 설정 등록 (런타임에 추가 가능)
  static void registerConfig(RewardConfig config) {
    _configs[config.currencyType] = config;
  }
}

