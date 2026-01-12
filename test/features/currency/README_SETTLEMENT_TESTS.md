# 정산 로직 테스트 가이드

## 📋 테스트 파일 위치

```
test/features/currency/settlement_logic_test.dart
```

## 🎯 테스트 범위

### 1. 개인 운동 보상 계산
- **달리기**: 1km = 통나무 1개 (올림 적용)
- **헬스**: 100 kcal = 쇠 1개 (올림 적용)
- **기타 운동**: 100 kcal = 흙 1개 (올림 적용)

### 2. 챌린지 보상 계산
- 기본 완료 보너스 (모든 재화)
- MVP 보너스 (특정 재화 1종)
- 협력 보너스 (참가자 수에 비례)
- 기여 보상

### 3. 통합 챌린지 시나리오
- 여러 운동 타입 혼합 (달리기 + 헬스 + 기타)
- MVP 판정
- 참가했지만 기여 없는 경우
- 챌린지 실패 케이스

### 4. Garmin 운동 처리
- `correctedDistance` 우선 사용
- `distance` fallback

### 5. 경계값 테스트
- 0.1km → 1개 (올림)
- 0.9km → 1개 (올림)
- 1.0km → 1개
- 1 kcal → 1개 (올림)
- 99 kcal → 1개 (올림)
- 100 kcal → 1개
- 101 kcal → 2개 (올림)

## 🚀 테스트 실행 방법

### 모든 정산 테스트 실행
```bash
flutter test test/features/currency/settlement_logic_test.dart
```

### 특정 그룹만 실행
```bash
# 개인 운동 보상 테스트만
flutter test test/features/currency/settlement_logic_test.dart --name "개인 운동 보상 계산"

# 챌린지 보상 테스트만
flutter test test/features/currency/settlement_logic_test.dart --name "챌린지 보상 계산"

# 통합 챌린지 시나리오만
flutter test test/features/currency/settlement_logic_test.dart --name "통합 챌린지 시나리오"
```

### 상세 출력과 함께 실행 (보상 정보 표시)
```bash
flutter test test/features/currency/settlement_logic_test.dart --reporter expanded
```

출력 예시:
```
========== 시나리오 1: A 사용자 (MVP) ==========
챌린지: 10kg 통합 챌린지
목표: 10.0kg / 달성: 10.12kg

[참가자 기여]
  userA: 6.01kg
  userB: 3.90kg
  userC: 0.21kg
  userD: 0.00kg

[A 사용자 보상]
  기여: 6.01kg (달리기)
  MVP: YES (CurrencyType.wood)
  완료 보너스: {CurrencyType.wood: 4, CurrencyType.soil: 4, CurrencyType.iron: 4}
  MVP 보너스: {CurrencyType.wood: 5}
  총 보상: {CurrencyType.wood: 9, CurrencyType.iron: 4, CurrencyType.soil: 4}
```

### 커버리지와 함께 실행
```bash
flutter test --coverage test/features/currency/settlement_logic_test.dart
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📊 테스트 시나리오 상세

### 시나리오 1: 10kg 챌린지 - 여러 운동 타입 혼합

**참가자:**
- A 사용자: 6.01km 달리기 (6.01kg) → **MVP**
- B 사용자: 390 kcal 기타운동 (3.90kg)
- C 사용자: 21 kcal 웨이트 (0.21kg)
- D 사용자: 0kg (참가만)

**총합:** 10.12kg > 10kg → ✅ **성공**

**A 사용자 보상 (MVP):**
```
완료 보너스: {wood: 4, iron: 4, soil: 4}  # 3종 운동 참여 → 각 재화 균등 분배
MVP 보너스: {wood: 5}                      # 달리기 최다 기여
총 보상: {wood: 9, iron: 4, soil: 4}       # 총 17개
```

**B 사용자 보상 (기타 운동):**
```
완료 보너스: {wood: 4, iron: 4, soil: 4}  # 3종 운동 참여
MVP 보너스: {}                             # MVP 아님
총 보상: {wood: 4, iron: 4, soil: 4}       # 총 12개
```

**D 사용자 보상 (기여 없음):**
```
완료 보너스: {wood: 4, iron: 4, soil: 4}  # 기여 없어도 받음!
MVP 보너스: {}
총 보상: {wood: 4, iron: 4, soil: 4}       # 총 12개
💡 챌린지 성공 시 기여 없어도 완료 보너스는 받음!
```

### 시나리오 2: 챌린지 실패 (9.5kg만 달성)

**참가자:**
- A 사용자: 5.0km 달리기 (5.0kg) → **MVP**
- B 사용자: 3.0kg
- C 사용자: 1.5kg

**총합:** 9.5kg < 10kg → ❌ **실패**

**A 사용자 보상 (실패):**
```
완료 보너스: 없음 (실패)
MVP 보너스: 없음 (실패)
총 보상: 없음 (성공 보너스만 계산)
💡 실패 시 완료/MVP 보너스 없음 (기여 보상은 별도 계산)
```

## 🔍 검증 포인트

### 1. 개인 운동 보상
```dart
// 달리기: 5km = 통나무 5개
expect(result.total, 5);

// 달리기: 5.1km = 통나무 6개 (올림)
expect(result.total, 6);

// 헬스: 300 kcal = 쇠 3개
expect(result.total, 3);

// 헬스: 301 kcal = 쇠 4개 (올림)
expect(result.total, 4);

// 기타: 200 kcal = 흙 2개
expect(result.total, 2);
```

### 2. 챌린지 성공 여부
```dart
expect(result.isSuccess, true);  // 성공
expect(result.isSuccess, false); // 실패
```

### 3. MVP 판정
```dart
expect(result.isMvp, true);
expect(result.mvpCurrencyType, CurrencyType.wood); // 달리기 최다
```

### 4. 보너스 지급
```dart
// 성공 시 완료 보너스 있음
expect(result.completionBonus.values.any((v) => v > 0), true);

// 실패 시 완료 보너스 없음
expect(result.completionBonus.values.every((v) => v == 0), true);
```

## 🐛 디버깅 팁

### 1. 테스트 실패 시
```bash
# 실패한 테스트만 재실행
flutter test test/features/currency/settlement_logic_test.dart --name "테스트명"

# 상세 출력으로 확인
flutter test test/features/currency/settlement_logic_test.dart --reporter expanded
```

### 2. 보상 계산 로직 확인
```dart
// calculateReward.dart의 로직 확인
print('보상: ${result.totalRewards}');
print('완료 보너스: ${result.completionBonus}');
print('MVP 보너스: ${result.mvpBonus}');
```

### 3. Firestore 데이터 구조 확인
실제 Firestore에 저장된 데이터와 비교:
```
challenges/{id}
  - participants: ['userA', 'userB', 'userC', 'userD']
  - stats:
      userA:
        runningContribution: 6.01
        strengthContribution: 0
        otherContribution: 0
      userB:
        runningContribution: 0
        strengthContribution: 0
        otherContribution: 3.90
```

## 📝 새 테스트 추가 방법

### 1. 테스트 그룹 추가
```dart
group('새로운 테스트 그룹', () {
  test('테스트 케이스 1', () {
    // given
    final challengeData = ChallengeSettlementData(...);

    // when
    final result = calculateReward.calculateChallengeReward(challengeData);

    // then
    expect(result.isSuccess, true);
  });
});
```

### 2. 데이터 생성 헬퍼 활용
```dart
ChallengeSettlementData createTestChallenge({
  required bool isSuccess,
  required double userContribution,
  required bool isUserMvp,
}) {
  return ChallengeSettlementData(
    // ... 필드 설정
  );
}
```

## ⚠️ 주의사항

1. **칼로리 변환**: 100 kcal = 1개 (10 kcal 아님!)
2. **Garmin 운동**: `correctedDistance` 우선, `distance` fallback
3. **올림 규칙**: `ceil()` 사용 - 0.1km도 1개, 1 kcal도 1개
4. **참가만 한 경우**: 성공 시 기본 완료 보너스는 받음
5. **실패 시**: 기여 보상만 받고, 완료/MVP 보너스 없음
6. **통합 챌린지**: 여러 운동 타입 혼합 가능

## 📚 관련 파일

- `lib/features/currency/domain/usecases/calculate_reward.dart` - 보상 계산 로직
- `lib/features/currency/data/datasources/firestore_currency_datasource.dart` - 데이터 조회
- `lib/features/log_run/domain/utils/workout_converter.dart` - 운동 → kg 변환
- `lib/features/currency/domain/entities/reward_config.dart` - 보상 설정

## 🔄 지속적 통합 (CI)

GitHub Actions 등에서 자동 실행:
```yaml
- name: Run settlement tests
  run: flutter test test/features/currency/settlement_logic_test.dart
```

---

_v1.0 | 2026-01-12_
