import 'package:flutter_test/flutter_test.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/challenge_settlement_data.dart';
import 'package:co_workfit/features/currency/domain/usecases/calculate_reward.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';

/// 정산 로직 테스트
///
/// 테스트 시나리오:
/// 1. 개인 운동 보상 계산
///    - 달리기: 1km = 통나무 1개
///    - 헬스: 100 kcal = 쇠 1개
///    - 기타: 100 kcal = 흙 1개
///
/// 2. 챌린지 보상 계산
///    - 기본 완료 보너스 (모든 재화)
///    - MVP 보너스 (특정 재화 1종)
///    - 협력 보너스 (참가자 수에 비례)
///
/// 3. 통합 챌린지 시나리오
///    - 여러 운동 타입 혼합
///    - MVP 판정
///    - 참가했지만 기여 없는 경우
void main() {
  late RewardCalculator calculateReward;

  setUp(() {
    calculateReward = const RewardCalculator();
  });

  group('개인 운동 보상 계산', () {
    test('달리기: 1km = 통나무 1개', () {
      final workoutData = SoloWorkoutData.running(
        distanceKm: 5.0,
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.currencyType, CurrencyType.wood);
      expect(result.total, 5); // 5km = 5개
    });

    test('달리기: 10.5km = 통나무 11개', () {
      final workoutData = SoloWorkoutData.running(
        distanceKm: 10.5,
        workoutCount: 2,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 11); // ceil(10.5) = 11개
    });

    test('헬스: 300 kcal = 쇠 3개', () {
      final workoutData = SoloWorkoutData.strength(
        score: 3.0, // 300 kcal / 100 = 3.0
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.currencyType, CurrencyType.iron);
      expect(result.total, 3);
    });

    test('기타 운동: 200 kcal = 흙 2개', () {
      final workoutData = SoloWorkoutData.other(
        minutes: 2.0, // 200 kcal / 100 = 2.0
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.currencyType, CurrencyType.soil);
      expect(result.total, 2);
    });

    test('보상이 0개인 경우', () {
      final workoutData = SoloWorkoutData.running(
        distanceKm: 0.0,
        workoutCount: 0,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 0);
    });
  });

  group('챌린지 보상 계산 - 기본', () {
    test('성공한 챌린지 - MVP 아님', () {
      final challengeData = ChallengeSettlementData(
        challengeId: 'test-challenge-1',
        challengeName: '10km 달리기 챌린지',
        challengeType: ChallengeType.running,
        targetValue: 10.0,
        achievedValue: 12.0,
        isSuccess: true,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 3,
        participantContributions: {
          'user1': 5.0,
          'user2': 4.0,
          'user3': 3.0,
        },
        userContribution: 4.0,
        isUserMvp: false,
        userTotalWorkoutValue: 4.0,
        isFirstContribution: true,
        participatedWorkoutTypes: {ChallengeType.running},
        userContributionByType: {ChallengeType.running: 4.0},
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // 기본 완료 보너스 + 협력 보너스 + 기여 보상
      expect(result.isSuccess, true);
      expect(result.isMvp, false);
      expect(result.totalRewards[CurrencyType.wood]! > 0, true);
    });

    test('성공한 챌린지 - MVP', () {
      final challengeData = ChallengeSettlementData(
        challengeId: 'test-challenge-2',
        challengeName: '10km 달리기 챌린지',
        challengeType: ChallengeType.running,
        targetValue: 10.0,
        achievedValue: 12.0,
        isSuccess: true,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 3,
        participantContributions: {
          'user1': 6.0,
          'user2': 4.0,
          'user3': 2.0,
        },
        userContribution: 6.0,
        isUserMvp: true,
        userTotalWorkoutValue: 6.0,
        isFirstContribution: true,
        participatedWorkoutTypes: {ChallengeType.running},
        userContributionByType: {ChallengeType.running: 6.0},
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // MVP 보너스 포함
      expect(result.isSuccess, true);
      expect(result.isMvp, true);
      expect(result.mvpBonus[CurrencyType.wood]! > 0, true);
      expect(result.mvpCurrencyType, CurrencyType.wood);
    });

    test('실패한 챌린지', () {
      final challengeData = ChallengeSettlementData(
        challengeId: 'test-challenge-3',
        challengeName: '10km 달리기 챌린지',
        challengeType: ChallengeType.running,
        targetValue: 10.0,
        achievedValue: 8.0,
        isSuccess: false,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 2,
        participantContributions: {
          'user1': 5.0,
          'user2': 3.0,
        },
        userContribution: 5.0,
        isUserMvp: true,
        userTotalWorkoutValue: 5.0,
        isFirstContribution: true,
        participatedWorkoutTypes: {ChallengeType.running},
        userContributionByType: {ChallengeType.running: 5.0},
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // 실패 시 성공 보너스 없음
      expect(result.isSuccess, false);
      expect(result.completionBonus.values.every((v) => v == 0), true);
      expect(result.mvpBonus.values.every((v) => v == 0), true);
      // calculateChallengeSuccessBonus는 성공 보너스만 계산하므로 실패 시 보상 없음
      // (기여 보상은 별도로 계산됨)
      expect(result.totalRewards.isEmpty, true);
    });
  });

  group('통합 챌린지 시나리오', () {
    test('시나리오 1: 10kg 챌린지 성공 - 여러 운동 타입', () {
      // A: 6.01km 달리기 (6.01kg)
      // B: 390 kcal 기타운동 (3.90kg)
      // C: 21 kcal 웨이트 (0.21kg)
      // D: 0kg (참가만)
      // 총: 10.12kg > 10kg (성공)

      final challengeData = ChallengeSettlementData(
        challengeId: 'test-mixed-1',
        challengeName: '10kg 통합 챌린지',
        challengeType: ChallengeType.running, // deprecated
        targetValue: 10.0,
        achievedValue: 10.12,
        isSuccess: true,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 4,
        participantContributions: {
          'userA': 6.01,
          'userB': 3.90,
          'userC': 0.21,
          'userD': 0.0,
        },
        userContribution: 6.01, // A 사용자
        isUserMvp: true, // 최다 기여
        userTotalWorkoutValue: 6.01,
        isFirstContribution: true,
        participatedWorkoutTypes: {
          ChallengeType.running,
          ChallengeType.other,
          ChallengeType.strengthTraining,
        },
        userContributionByType: {
          ChallengeType.running: 6.01,
        },
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // 출력: 보상 상세 정보
      print('\n========== 시나리오 1: A 사용자 (MVP) ==========');
      print('챌린지: ${challengeData.challengeName}');
      print('목표: ${challengeData.targetValue}kg / 달성: ${challengeData.achievedValue}kg');
      print('\n[참가자 기여]');
      challengeData.participantContributions.forEach((user, contribution) {
        print('  $user: ${contribution.toStringAsFixed(2)}kg');
      });
      print('\n[A 사용자 보상]');
      print('  기여: ${challengeData.userContribution}kg (달리기)');
      print('  MVP: ${result.isMvp ? "YES" : "NO"} (${result.mvpCurrencyType})');
      print('  완료 보너스: ${result.completionBonus}');
      print('  MVP 보너스: ${result.mvpBonus}');
      print('  총 보상: ${result.totalRewards}');

      // 검증
      expect(result.isSuccess, true);
      expect(result.isMvp, true);
      expect(result.mvpCurrencyType, CurrencyType.wood); // 달리기가 최다

      // 협력 보너스 (4명)
      expect(result.totalRewards[CurrencyType.wood]! > 0, true);
      expect(result.totalRewards[CurrencyType.iron]! > 0, true); // 웨이트 참여
      expect(result.totalRewards[CurrencyType.soil]! > 0, true); // 기타 참여
    });

    test('시나리오 2: B 사용자 (기타 운동)', () {
      final challengeData = ChallengeSettlementData(
        challengeId: 'test-mixed-1',
        challengeName: '10kg 통합 챌린지',
        challengeType: ChallengeType.other, // deprecated
        targetValue: 10.0,
        achievedValue: 10.12,
        isSuccess: true,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 4,
        participantContributions: {
          'userA': 6.01,
          'userB': 3.90,
          'userC': 0.21,
          'userD': 0.0,
        },
        userContribution: 3.90, // B 사용자
        isUserMvp: false,
        userTotalWorkoutValue: 3.90,
        isFirstContribution: true,
        participatedWorkoutTypes: {
          ChallengeType.running,
          ChallengeType.other,
          ChallengeType.strengthTraining,
        },
        userContributionByType: {
          ChallengeType.other: 3.90,
        },
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // 출력: 보상 상세 정보
      print('\n========== 시나리오 2: B 사용자 (기타 운동) ==========');
      print('[B 사용자 보상]');
      print('  기여: ${challengeData.userContribution}kg (기타 운동)');
      print('  MVP: ${result.isMvp ? "YES" : "NO"}');
      print('  완료 보너스: ${result.completionBonus}');
      print('  MVP 보너스: ${result.mvpBonus}');
      print('  총 보상: ${result.totalRewards}');

      expect(result.isSuccess, true);
      expect(result.isMvp, false);
      // 기본 완료 보너스 + 협력 보너스 + 기여 보상
      expect(result.totalRewards.values.any((v) => v > 0), true);
    });

    test('시나리오 3: D 사용자 (참가만 하고 기여 없음)', () {
      final challengeData = ChallengeSettlementData(
        challengeId: 'test-mixed-1',
        challengeName: '10kg 통합 챌린지',
        challengeType: ChallengeType.running, // deprecated
        targetValue: 10.0,
        achievedValue: 10.12,
        isSuccess: true,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 4,
        participantContributions: {
          'userA': 6.01,
          'userB': 3.90,
          'userC': 0.21,
          'userD': 0.0,
        },
        userContribution: 0.0, // D 사용자
        isUserMvp: false,
        userTotalWorkoutValue: 0.0,
        isFirstContribution: false,
        participatedWorkoutTypes: {
          ChallengeType.running,
          ChallengeType.other,
          ChallengeType.strengthTraining,
        },
        userContributionByType: {},
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // 출력: 보상 상세 정보
      print('\n========== 시나리오 3: D 사용자 (기여 없음) ==========');
      print('[D 사용자 보상]');
      print('  기여: ${challengeData.userContribution}kg (운동 안함)');
      print('  MVP: ${result.isMvp ? "YES" : "NO"}');
      print('  완료 보너스: ${result.completionBonus}');
      print('  MVP 보너스: ${result.mvpBonus}');
      print('  총 보상: ${result.totalRewards}');
      print('  💡 챌린지 성공 시 기여 없어도 완료 보너스는 받음!');

      // 챌린지 성공 시 기본 완료 보너스는 받음
      expect(result.isSuccess, true);
      expect(result.completionBonus.values.any((v) => v > 0), true);

      // 기여가 없어서 기여 보상 없음
      expect(result.isMvp, false);
      expect(result.mvpBonus.values.every((v) => v == 0), true);
    });

    test('시나리오 4: 챌린지 실패 - 9.5kg만 달성', () {
      final challengeData = ChallengeSettlementData(
        challengeId: 'test-mixed-2',
        challengeName: '10kg 통합 챌린지',
        challengeType: ChallengeType.running,
        targetValue: 10.0,
        achievedValue: 9.5,
        isSuccess: false,
        endDate: DateTime.parse('2026-01-12'),
        participantCount: 3,
        participantContributions: {
          'userA': 5.0,
          'userB': 3.0,
          'userC': 1.5,
        },
        userContribution: 5.0,
        isUserMvp: true,
        userTotalWorkoutValue: 5.0,
        isFirstContribution: true,
        participatedWorkoutTypes: {
          ChallengeType.running,
        },
        userContributionByType: {
          ChallengeType.running: 5.0,
        },
      );

      final result = calculateReward.calculateChallengeSuccessBonus(challengeData: challengeData);

      // 출력: 보상 상세 정보
      print('\n========== 시나리오 4: 챌린지 실패 ==========');
      print('챌린지: ${challengeData.challengeName}');
      print('목표: ${challengeData.targetValue}kg / 달성: ${challengeData.achievedValue}kg ❌');
      print('\n[참가자 기여]');
      challengeData.participantContributions.forEach((user, contribution) {
        print('  $user: ${contribution.toStringAsFixed(2)}kg');
      });
      print('\n[A 사용자 보상]');
      print('  기여: ${challengeData.userContribution}kg (달리기)');
      print('  완료 보너스: ${result.completionBonus.isEmpty ? "없음 (실패)" : result.completionBonus}');
      print('  MVP 보너스: ${result.mvpBonus.isEmpty ? "없음 (실패)" : result.mvpBonus}');
      print('  총 보상: ${result.totalRewards.isEmpty ? "없음 (성공 보너스만 계산)" : result.totalRewards}');
      print('  💡 실패 시 완료/MVP 보너스 없음 (기여 보상은 별도 계산)');

      // 실패 시
      expect(result.isSuccess, false);
      expect(result.completionBonus.values.every((v) => v == 0), true);
      expect(result.mvpBonus.values.every((v) => v == 0), true);

      // calculateChallengeSuccessBonus는 성공 보너스만 계산하므로 실패 시 보상 없음
      expect(result.totalRewards.isEmpty, true);
    });
  });

  group('Garmin 운동 처리', () {
    test('Garmin 달리기: correctedDistance 사용', () {
      // Garmin의 경우 correctedDistance를 사용해야 함
      final workoutData = SoloWorkoutData.running(
        distanceKm: 8.5, // correctedDistance 기준
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.currencyType, CurrencyType.wood);
      expect(result.total, 9); // ceil(8.5) = 9개
    });
  });

  group('경계값 테스트', () {
    test('0.1km 달리기 = 1개', () {
      final workoutData = SoloWorkoutData.running(
        distanceKm: 0.1, // ceil(0.1) = 1
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 1);
    });

    test('0.9km 달리기 = 1개', () {
      final workoutData = SoloWorkoutData.running(
        distanceKm: 0.9, // ceil(0.9) = 1
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 1);
    });

    test('1.0km 달리기 = 1개', () {
      final workoutData = SoloWorkoutData.running(
        distanceKm: 1.0,
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 1);
    });

    test('1 kcal 헬스 = 1개', () {
      final workoutData = SoloWorkoutData.strength(
        score: 0.01, // 1 kcal / 100, ceil(0.01) = 1
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 1);
    });

    test('99 kcal 헬스 = 1개', () {
      final workoutData = SoloWorkoutData.strength(
        score: 0.99, // 99 kcal / 100, ceil(0.99) = 1
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 1);
    });

    test('100 kcal 헬스 = 1개', () {
      final workoutData = SoloWorkoutData.strength(
        score: 1.0, // 100 kcal / 100
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 1);
    });

    test('101 kcal 헬스 = 2개', () {
      final workoutData = SoloWorkoutData.strength(
        score: 1.01, // 101 kcal / 100, ceil(1.01) = 2
        workoutCount: 1,
        date: '2026-01-12',
      );

      final result = calculateReward.calculateSoloWorkoutReward(workoutData: workoutData);

      expect(result.total, 2);
    });
  });
}
