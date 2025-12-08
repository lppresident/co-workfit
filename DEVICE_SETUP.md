# 📱 실제 기기에서 테스트하기

## 방법 1: Xcode 사용 (추천)

1. Xcode 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Bundle Identifier 변경:
   - TARGETS > Runner > General
   - Bundle Identifier: `com.yourname.coworkfit`

3. Signing 설정:
   - Signing & Capabilities 탭
   - Team: Personal Team 선택
   - Automatically manage signing ✅

4. iPhone 연결 & 실행:
   - USB로 iPhone 연결
   - 기기 선택
   - Product > Run (⌘R)

5. iPhone에서 신뢰 설정:
   - 설정 > 일반 > VPN 및 기기 관리
   - Apple ID 신뢰

## 방법 2: Flutter CLI 사용

1. 기기 확인:
   ```bash
   flutter devices
   ```

2. 기기에 실행:
   ```bash
   flutter run -d <device-id>
   ```

## ⚠️ 주의사항

- **무료 Apple ID 제한**:
  - 7일마다 재빌드 필요
  - 일부 entitlements 제한 가능

- **HealthKit 권한**:
  - Info.plist에 이미 설정됨
  - Runner.entitlements 자동 생성
  - 실행시 권한 요청 팝업 표시

## 📊 테스트 체크리스트

- [ ] 앱 설치 성공
- [ ] HealthKit 권한 요청 팝업
- [ ] 권한 허용 후 데이터 로드
- [ ] 오늘의 성과 통계 표시
- [ ] 운동 리스트 표시
- [ ] Pull-to-refresh 동작
- [ ] 운동 카드 UI 확인

## 🐛 문제 해결

### "Untrusted Developer" 에러
→ 설정 > 일반 > VPN 및 기기 관리 > 개발자 앱 신뢰

### HealthKit 데이터 없음
→ Health 앱에서 운동 기록 추가하거나 Apple Watch 연동

### 빌드 실패
→ Bundle Identifier가 고유한지 확인
→ Team이 Personal Team으로 설정되었는지 확인
