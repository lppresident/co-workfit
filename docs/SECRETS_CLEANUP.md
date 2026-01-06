# GitHub Secrets 정리 가이드

Firebase 배포를 제거하고 Play Store로 완전히 전환했으므로, 불필요한 Secrets를 정리할 수 있습니다.

## 제거 가능한 Secrets (Firebase 관련)

다음 Secrets는 더 이상 사용되지 않으므로 **안전하게 삭제** 가능합니다:

| Secret 이름 | 용도 | 삭제 가능 |
|-------------|------|----------|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase App Distribution 서비스 계정 JSON | ✅ 삭제 가능 |
| `FIREBASE_APP_ID` | Firebase 앱 ID | ✅ 삭제 가능 |

## 계속 필요한 Secrets

다음 Secrets는 Play Store 배포와 iOS 배포에 **계속 필요**합니다:

### Android (Play Store)
| Secret 이름 | 용도 |
|-------------|------|
| `PLAY_STORE_CONFIG_JSON` | Play Store 서비스 계정 JSON 키 |
| `RELEASE_KEYSTORE_BASE64` | Release keystore 파일 (Base64) |
| `RELEASE_KEYSTORE_PASSWORD` | Keystore 비밀번호 |
| `RELEASE_KEY_ALIAS` | Key alias |
| `RELEASE_KEY_PASSWORD` | Key 비밀번호 |

### iOS (TestFlight)
| Secret 이름 | 용도 |
|-------------|------|
| `MATCH_GIT_URL` | Fastlane Match 저장소 URL |
| `MATCH_PASSWORD` | Match 암호화 비밀번호 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Match Git 인증 |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API 키 ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | API 키 발급자 ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | API 키 내용 |

## Secrets 삭제 방법

1. GitHub 저장소 이동
2. `Settings` → `Secrets and variables` → `Actions`
3. 삭제할 Secret 옆의 `...` 버튼 클릭
4. `Remove secret` 선택
5. 확인

## 주의사항

Firebase를 완전히 사용하지 않는다면 삭제해도 되지만, **다른 곳에서 Firebase를 사용 중이라면** (예: Firestore, Auth 등) 해당 서비스 계정은 유지해야 할 수 있습니다.

이 문서는 **오직 Firebase App Distribution 배포**를 위한 Secrets만 다룹니다. Firebase의 다른 기능(Firestore, Auth, Analytics 등)은 앱 내부에서 google-services.json을 통해 계속 작동합니다.
