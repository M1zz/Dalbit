# 사용 통계 — 공용 허브(FeedbackHub) 수집·조회

달빛이 **실제로 재우고 있는지**를 숫자로 확인하기 위한 익명 집계. 피드백과 같은
CloudKit 공개 DB(`iCloud.com.Ysoup.FeedbackHub`)를 쓰고, `appId`(`com.leeo.LullabyRecipe`)로
다른 앱과 구분한다.

| 파일 | 역할 |
|---|---|
| `Manager/ListeningTracker.swift` | 청취 세션 로컬 원장 (길이·시간대·종료 이유) |
| `Manager/UsageReportingService.swift` | 무엇을 보낼지 정하는 정책. 엔진은 LeeoKit `LeeoUsageReporter` |
| `Manager/UsageInsights.swift` | 받아온 표본 → 효용·분포·퍼널·리텐션 (순수 함수) |
| `Views/Settings/UsageStatsView.swift` | 개발자 전용 화면. 설정 → 앱 버전 **7번 탭** |
| `Views/Settings/ListeningRecapView.swift` | **사용자용** 「나의 기록」. 이 기기 원장만 읽고 네트워크를 타지 않는다 |
| `DalbitTests/` | 위 계산들의 유닛 테스트 (`xcodebuild test -scheme Dalbit`) |

### 두 화면을 헷갈리지 말 것

|  | 사용 통계 (개발자) | 나의 기록 (사용자) |
|---|---|---|
| 데이터 | 허브의 **모든 설치** 익명 집계 | **이 기기** ListeningTracker 원장 |
| 네트워크 | CloudKit 조회 필요 | 없음 |
| 진입 | 설정 → 앱 버전 7번 탭 | 설정 → 나의 기록 |
| 지역화 | 안 함(한국어 고정) | **함**(ko/en) |

---

## 왜 재생 시간을 세나

설치 수와 실행 수는 "앱을 열었다"까지만 말해 준다. 열고 3분 만에 껐다면 그 사람에게
맞는 소리를 못 찾아 준 것인데, 실행 수만 보면 그 실패가 성공처럼 보인다.
그래서 **세션의 길이와 끝난 이유**를 센다. 클립키보드의 "아낀 시간"에 해당하는 자리다.

### 잠들었다는 판정 (추정이다)

| 종료 이유 | 잠든 것으로 보나 | 왜 |
|---|---|---|
| 수면 타이머 완주 | ✅ | 끝까지 끄지 않았다 — 가장 믿을 만한 신호 |
| 30분 이상 튼 채 앱이 끝남 | ✅ | 사람이 잠들면 앱을 끄지 않는다 |
| 사용자가 직접 정지 | ❌ | 아무리 길어도 깨어 있었다는 뜻 |
| 타이머 도중 취소·일시정지 | ❌ | 위와 같음 |

⚠️ **수면을 측정한 값이 아니다.** 화면에도 추정이라고 적어 두었다. 이 숫자를 마케팅
문구로 옮길 때 "잠들었습니다"라고 단정하지 말 것.

### 재생 중에 앱이 죽는 건 정상 경로다

이 앱에서는 그게 흔한 일이다 — 잠들면 앱을 끄지 않는다. 그래서 세션을 "지금"으로 닫으면
며칠 뒤에 앱을 열었을 때 그 며칠이 통째로 청취 시간이 되고 효용 지표가 몇 배로 부푼다.
`ListeningTracker`는 재생 중 60초마다 생존 신호를 찍고, 다음 실행에서 **마지막 생존
신호까지만** 인정하며 세션을 닫는다. 상한은 12시간.

---

## 무엇을 보내나

### `UsageSnapshot` — 설치당 1개 (upsert)

익명 UUID가 recordName이라 같은 설치는 항상 덮어써진다. 고유 사용자 수 집계용.
`metrics` JSON 한 필드에 아래 수치가 들어간다.

| 키 | 뜻 |
|---|---|
| `listenMin` `sessions` `longestMin` | 누적 청취 분, 끝난 세션 수, 최장 세션 |
| `nightSessions` `sleepSessions` | 밤(22~04시) 시작 세션, 잠든 것으로 보이는 세션 |
| `timerSessions` `timerCompleted` | 타이머를 건 세션과 그중 완주한 세션 |
| `len0`~`len4` | 세션 길이 분포 (5분 미만 / 5~15 / 15~30 / 30~60 / 60분 이상) |
| `streakDays` `activeDays` | 연속 청취일, 소리를 들은 날 수 |
| `mixes` `customMixes` `layeredMixes` `favorites` | 보유·직접 만든·레이어드·즐겨찾기 조합 수 |
| `plays` `topPlays` `unusedMixes` | 총 재생, 최다 재생, 한 번도 안 들은 조합 |
| `flag.*` | isPro / madeOwnMix / usedTimer / effectsMuted / favoritesOnly (0·1) |

### `UsageEvent` — 주요 행동 스트림 (이름만)

`app_open`(20시간 쓰로틀), `listen_start`, `listen_night`, **`sleep_session`**(4시간 쓰로틀),
`timer_start` / `timer_complete` / `timer_cancel`, `mix_create`, `favorite_add`,
`paywall_view`, `paywall_purchase`.

전체 목록은 `UsageReportingService.allEventNames`가 단일 소스다. **새 이벤트를 만들면 여기에도
넣을 것** — 빠지면 통계 화면의 「이 기기」 카드가 그 이벤트를 훑지 않아, 배선이 끊긴 걸 눈치채지 못한다.
(`UsageReportingServiceTests.testAllEventNames_coversEveryDeclaredEvent`가 누락을 잡는다.)

### `CrashReport` — 크래시·멈춤 진단

LeeoKit의 `LeeoDiagnostics`(MetricKit)가 같은 허브에 올린다. 콜스택·앱 버전·OS·기기 종류만 담기며
**설치 식별자조차 붙지 않는다**(크래시 집계에 필요 없다). 보는 곳은 설정 → 안정성.

⚠️ 페이로드는 iOS가 **하루 한 번꼴로 묶어서** 준다 — 실시간 알림용이 아니다. 시뮬레이터에서는
거의 오지 않으므로, 화면이 비어 있는 게 정상일 수 있다.

기본 쓰로틀은 이름당 6시간이다. 그래서 **절대 수치가 아니라 단계 간 비율로 읽어야 한다.**
`sleep_session`만 4시간으로 짧은데, 낮잠까지 세려면 하루 두 번이 뭉개지면 안 되기 때문이다.

### 보내지 않는 것

⚠️ **소리 제목은 절대 보내지 않는다.** 사용자가 직접 지은 이름이라(아이 이름·연인 이름이
흔하다) 익명 지표가 아니다. 기기·계정 식별자도 없다. 나가는 값은 개수·분 단위 수치와
0/1 플래그, 그리고 위에 적힌 고정된 이벤트 이름뿐이다.

---

## 수집을 멈추려면

**원격 킬스위치**가 있다 (LeeoKit 2.9.0의 `LeeoRemoteFlags`). CloudKit Dashboard에서
`RemoteFlags` 레코드의 필드를 `0`으로 내리면 **새 빌드 심사 없이** 다음 실행부터 멈춘다.

| 플래그 | 끄면 멈추는 것 | App Privacy 항목 |
|---|---|---|
| `usageReportingEnabled` | 스냅샷·이벤트 (사용 통계) | Product Interaction |
| `diagnosticsEnabled` | 크래시·멈춤 진단 | CrashData |

둘을 따로 둔 이유는 신고 항목이 다르고 문제가 생기는 이유도 다르기 때문이다 — 하나 때문에
다른 하나까지 끌 일은 없어야 한다.

조회 실패 시 기본값은 **켬**이다(LeeoKit이 그렇게 동작한다). 네트워크 문제로 수집이 임의로
멈추면 킬스위치가 오히려 장애 원인이 된다.

로컬 스위치(`UserDefaults`의 `dalbit.usage.disabled`)도 그대로 남겨 두었다 — 원격이 닿지 않는
상황에서 손으로 끄는 최후 수단이다.

지금 이 기기에서 수집이 도는지는 **설정 → 사용 통계 → 맨 아래 「이 기기」 카드**에서 볼 수 있다.

---

## CloudKit Dashboard 준비 (1회)

https://icloud.developer.apple.com → `iCloud.com.Ysoup.FeedbackHub`

1. **스키마 생성**: Development 환경에서 앱을 한 번 실행하고 소리를 한 번 재생·정지하면
   `UsageSnapshot` / `UsageEvent` 레코드 타입이 자동 생성된다.
2. **인덱스**
   - `UsageSnapshot`: `recordName` **Queryable**
   - `UsageEvent`: `recordName` **Queryable** + `createdTimestamp` **Sortable**
   - `CrashReport`: `recordName` **Queryable** + `createdTimestamp` **Sortable**
   - `appId`는 인덱스 없이 클라이언트에서 필터한다(인덱스 배포를 늘리지 않기 위함).
2-1. **원격 킬스위치용 `RemoteFlags`** (선택 — 안 만들면 항상 "켬"으로 돈다)
   - 레코드 타입 `RemoteFlags`, recordName `flags_com.leeo.LullabyRecipe`
   - 필드: `usageReportingEnabled`, `diagnosticsEnabled` 를 **Int64**(1=켬, 0=끔)로 추가
   - `recordName` **Queryable**
3. **Security Roles**: `_world`는 create만, read 제거. admin 역할에 read 권한과 개발자
   본인 userRecordName 등록 (피드백 인박스와 동일 — 인박스 하단에서 복사 가능).
4. **Production 배포**: Schema → Deploy Schema Changes to Production.

배포 전에는 통계 화면이 "읽지 못했어요 / read 권한 필요" 안내를 보여준다(정상).

---

## App Store 제출 시

익명 사용 데이터를 수집하므로 **App Privacy 설문**을 갱신해야 한다.

- Data Type: *Product Interaction* (Usage Data), Analytics 목적,
  **사용자와 연결되지 않음**, 추적(Tracking) 아님 (ATT 불필요, 광고·데이터 브로커 공유 없음).
- Data Type: *Crash Data*, App Functionality/Analytics 목적, **사용자와 연결되지 않음**, 추적 아님.
  (MetricKit 진단에는 설치 식별자조차 붙지 않는다.)
- 앱 안에 끄는 스위치가 없으므로 개인정보 처리방침(`docs/privacy.html`)에 수집 항목·목적·
  보관을 명시할 것. **이 기능이 들어간 버전부터는 "아무 데이터도 보내지 않는다"는 문구가
  사실이 아니다** — 릴리즈 노트와 처리방침을 함께 고칠 것.
