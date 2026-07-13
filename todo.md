# TODO - App Store 리젝 대응 (Submission f68454b3)

## Guideline 3.1.2 - 구독 필수 정보 (코드 수정 완료)
- [x] 구독 화면에 개인정보처리방침(Privacy Policy) 기능 링크 추가
- [x] 구독 화면에 이용약관(Apple 표준 EULA) 기능 링크 추가
- [x] 구독 제목/기간/가격 표시 확인 (가격·체험 표시 기존 존재)
- [x] 로컬라이제이션 키 추가 (ko/en)
- [x] 자동 갱신 안내 문구 추가

## GitHub Pages 배포 (완료)
- [x] docs/index.html 지원 페이지 작성
- [x] docs/privacy.html 개인정보 처리방침 작성
- [x] main 브랜치에 docs push → Pages 빌드 완료(built)
- [x] URL 라이브 확인 (둘 다 HTTP 200)
  - 지원: https://m1zz.github.io/RelaxOn/
  - 개인정보: https://m1zz.github.io/RelaxOn/privacy.html
- [x] README에 지원/개인정보/약관 링크 추가

## 버전
- [x] 앱 버전 4.0.1 유지 (MARKETING_VERSION 변경 없음)

## 접근성 개선 (시각장애인 사용 / 구조 단순화) - 1차 완료
방향: 네이티브 컨트롤로 교체 + 핵심 플로우(듣기→재생→타이머→구독) 우선
- [x] ListenListView 헤더 아이콘 버튼 라벨 (저장목록/타이머+남은시간 값)
- [x] 캠프파이어/물방울 등 장식 비주얼 VoiceOver 숨김
- [x] 미니플레이어: 정보영역 1개 버튼으로 그룹화(전체플레이어 열기)+재생/일시정지 분리 라벨
- [x] SavedSoundsListView 사운드 카드 라벨·버튼 trait·재생 힌트·즐겨찾기 커스텀 액션
- [x] 추천 카드 버튼 trait·힌트
- [x] TimerView 피커 라벨, 남은시간 live region(updatesFrequently), 중지/일시정지 라벨
- [x] TimePickerView 휠 라벨 + 단위 텍스트 로컬라이즈
- [x] SubscriptionView 닫기 버튼 라벨 + 44pt 터치영역
- [x] SoundDetailView 네이티브 Slider 라벨·값(볼륨/간격/피치/변동폭), 필터 선택상태, 뒤로 버튼
- [x] SoundPlayerFullModalView 이전/재생/다음·공간음향 슬라이더 라벨·값
- [x] a11y 로컬라이제이션 키 36개(ko/en) 추가
- [x] 빌드 검증 (BUILD SUCCEEDED)
- 참고: DragCircularSlider/SnapCircularSlider는 미사용 레거시(실제 UI는 이미 네이티브 Slider)

### 접근성 - 2차 후보 (다음 단계)
- [ ] 온보딩 이미지 라벨/숨김, 페이지 인디케이터 정리
- [ ] CreateNewSoundView(사운드 제작) 칩/볼륨/미리듣기 접근성
- [ ] SettingsView 타이머 컨트롤 접근성
- [ ] Dynamic Type: 하드코딩 폰트(약 211곳) semantic 전환 (저시력자, 레이아웃 검증 필요)
- [ ] 미사용 레거시 파일 정리(DragCircularSlider/SnapCircularSlider, pbxproj 수정 필요)

## UI 전면 개편 (고요한 미니멀) - 1차 완료
방향: 고요한 미니멀 + 디자인 시스템부터 재구축, 라이트/다크 적응형
- [x] 디자인 시스템 구축: DesignSystem/Theme.swift(색/타이포/간격/라운드/그림자), Components.swift(ScreenBackground, dsCard, Primary/SecondaryButtonStyle, SectionHeader, DSChip, CircleIconButton)
- [x] pbxproj에 DesignSystem 그룹/파일 추가
- [x] 홈(Listen): 캠프파이어 → 브리딩 오브, 헤더/추천/미니플레이어/빈상태
- [x] 타이머 설정/진행 화면
- [x] 저장목록(카드/섹션/검색/빈상태)
- [x] 구독 화면(SubscriptionView)
- [x] 사운드 편집(SoundDetailView) - 슬라이더 카드
- [x] 전체 플레이어(SoundPlayerFullModalView)
- [x] 사운드 제작(CreateNewSoundView)
- [x] 사운드 저장(SoundSaveView)
- [x] 온보딩(OnboardingView)
- [x] 설정(SettingsView)
- [x] 타이머 사운드 선택(TimerSoundSelectModalView)
- [x] 타이머 원형 프로그레스 바 색상 정렬
- [x] 빌드 성공 + 시뮬레이터 스크린샷 확인(온보딩/홈)
- [x] 앱 버전 4.0.1 유지

### UI 개편 - 2차 후보
- [ ] 보조 컴포넌트 미세 조정(SoundThumbnailView, TimerSoundListCell, ListenListCell 등)
- [ ] Dynamic Type 전수 검증(이미 DS.Font는 semantic이라 대부분 확대 대응)
- [ ] 라이트/다크 모드 양쪽 실기기 점검
- [ ] 레거시 중복 파일 정리(Views/ 루트의 SoundListView/SoundSaveView/SoundSelectView, 미사용 슬라이더)

## 반응형 + iPad 정식 지원 - 완료
- [x] Universal 전환 (TARGETED_DEVICE_FAMILY 1 → 1,2)
- [x] iPad 아이폰호환(가운데 창) 원인 제거: AppDelegate 커스텀 SceneConfiguration 오버라이드 삭제 → SwiftUI WindowGroup이 Scene 관리 → iPad 전체화면
- [x] 반응형 헬퍼: DS.Layout.contentMaxWidth/.grid(), .dsConstrainedWidth()
- [x] 저장목록 그리드 적응형(폰 2열 / iPad 3~4열)
- [x] 폼 화면 최대폭 제한·중앙 정렬(홈/타이머/구독/편집/제작/저장/설정)
- [x] iPad Pro 실측: 홈 전체화면 / 저장목록 적응형 / 구독 폼 중앙정렬 확인
- [x] iPhone 회귀 없음 확인
- 주의: 기존에 앱이 설치돼 있던 iPad **시뮬레이터**는 아이폰전용 등록을 캐시 → 가운데 창 유지. 신규/실기기 설치는 전체화면 정상. (해당 시뮬레이터는 앱 삭제 후 재설치 또는 Erase 필요)

### 남은 후보
- [ ] 온보딩 iPad 가로/세로 미세 조정(현재 TabView 중앙 배치라 동작은 정상)
- [ ] iPad 가로(landscape) 레이아웃 점검
- [ ] App Store: iPad 스크린샷 추가 필요(Universal이므로)

## Google Analytics (Firebase) 도입 - 완료
- [x] Firebase SDK(SPM, firebase-ios-sdk 11.x) FirebaseAnalytics 의존성 추가
- [x] AppDelegate에서 `FirebaseApp.configure()` 초기화
- [x] AnalyticsManager.swift 래퍼 추가 (이벤트/화면/사용자속성 API)
- [x] 핵심 이벤트 로깅: 사운드 재생/정지/저장/삭제
- [x] 시뮬레이터 빌드 성공 확인
- [x] 화면 조회(screen_view) 추적: `.trackScreen()` 모디파이어 + Home/CreateSound/Subscription 적용
- [x] 타이머 이벤트: 시작(timer_start, 분)·취소(timer_cancel)
- [x] 구독 이벤트: 페이월 노출(subscription_view)·결제(subscription_purchase) + is_premium 사용자 속성
- [ ] (선택) Firebase 콘솔에서 Analytics 활성화 및 DebugView로 수신 확인
- [ ] (수동) App Store Connect 개인정보 영양성분표에 "사용 데이터 → 분석" 추가

## 프로젝트 RelaxOn → Dalbit 리네임 - 완료 (2026-06-22)
- [x] 타깃/프로젝트/스킴 이름 → Dalbit (pbxproj name·comment, INFOPLIST/엔타이틀/프리뷰 경로, Dalbit.app)
- [x] 소스 폴더 `RelaxOn/` → `Dalbit/` (git mv, 히스토리 보존)
- [x] `RelaxOn.xcodeproj` → `Dalbit.xcodeproj`, 스킴 파일 `RelaxOn.xcscheme` → `Dalbit.xcscheme`
- [x] 레거시 파일: `RelaxOnApp.swift`→`DalbitApp.swift`(+@main struct), `RelaxOn.entitlements`→`Dalbit.entitlements`
- [x] 모든 스킴 container 참조 → Dalbit.xcodeproj, 워크스페이스 절대경로 → self:
- [x] Xcode가 만든 가짜 `Dalbit` 심링크 제거
- [x] 번들ID `com.leeo.LullabyRecipe` 유지, 시뮬레이터 빌드 성공
- [ ] (선택) 잔재 스킴(RelaxOnUITests/RelaxOnWatch*)·위젯 엔타이틀먼트 삭제 — 제거된 타깃의 cruft

## 지원 페이지 리브랜딩 - 완료 (main push)
- [x] docs/index.html·privacy.html 달빛(Dalbit) 리브랜딩
- [x] privacy: Firebase Analytics 수집 고지 추가(한/영)
- [x] main 브랜치 push (commit 2111009) → GitHub Pages 반영

## 알람 시계 기능 (AlarmKit) - 코어 완료
방향: 코어 우선 (Live Activity 표현 UI는 2차). 알람음은 앱 사운드 중 선택.
- [x] AlarmItem 모델 (시각/반복요일/사운드/on-off, Weekday enum)
- [x] AlarmService (싱글톤): 권한요청, 등록/취소/목록, UserDefaults 영속화
- [x] Info.plist: NSAlarmKitUsageDescription 추가
- [x] pbxproj에 신규 파일 등록(AlarmService/AlarmItem)
- [x] 시뮬레이터 빌드 검증 (iOS 26.2 SDK, BUILD SUCCEEDED)
- 참고: Alert(title:stopButton:)는 26.1에서 deprecated → #available(iOS 26.1)로 분기. 사운드 타입은 ActivityKit.AlertConfiguration.AlertSound.
- [x] 알람 목록/설정 UI (AlarmListView 목록·토글·삭제, AlarmEditView 시각휠/요일칩/사운드선택/라벨)
- [x] 진입 동선: 홈에서 달 아래로 스와이프 → 세그먼트 [보관함 | 알람] (DownSwipePagerView)
  - 기존 SavedSoundsListView/AlarmListView에 embedded 모드 추가(크롬 숨김), 상위가 +추가·세그먼트·닫기 담당
- [x] 시뮬레이터 검증: 빈상태/편집화면/세그먼트 전환 모두 렌더 확인 (BUILD SUCCEEDED)
  - 참고: 시뮬 합성탭이 작은 타깃(세그먼트/44pt버튼)엔 잘 안 먹어 일부는 임시 기본값으로 검증함
- [x] 진입 동선 변경: 달 위로 스와이프(수면타이머) 쪽 세그먼트 [수면타이머 | 알람] (TimerAlarmPagerView)
  - 아래 스와이프는 보관함 원래대로 복귀. SettingsView 잔재 알람 섹션 제거.
- [x] 로컬라이제이션(ko/en): 알람/타이머 문자열 34개 키 string catalog 추가, 코드 .localized 적용
  - 요일 라벨은 Calendar.veryShortWeekdaySymbols로 자동 번역. EN/KO 시뮬 렌더 확인.
- [ ] (2차) Widget Extension(Live Activity) 표현 UI - Dynamic Island/잠금화면 카운트다운
- [ ] (확인필요) 앱 번들 하위폴더(Assets/Sound/*) 사운드를 AlertSound.named가 찾는지 검증 (필요시 루트 복사 또는 Library/Sounds)
- [ ] (확인필요) 실기기에서 권한 요청·실제 알람 울림 동작 테스트

## 페이월 진입점 추가 - 완료
- [x] 보관함(아래 스와이프) 상단에 "프리미엄으로 업그레이드" 배지 → 탭하면 SubscriptionView
  - 무료 사용자(!isPremium)에게만 노출. DEBUG는 isPremium=true라 숨김 → 릴리스/심사 빌드에서 노출됨
  - 로컬라이즈(subscription.upgrade_badge), 시뮬에서 배지→페이월 진입 검증
  - 효과: 평소 구독 화면 접근 + App Store 심사자가 복원/약관/개인정보 화면을 쉽게 발견(리젝 해결 도움)

## App Store 리젝(f68454b3) 대응 - 진행 중 (2026-06-22)
- [x] 코드 확인: 복원 버튼·이용약관(EULA)·개인정보 링크 모두 SubscriptionView에 존재(커밋됨)
- [x] 구독 화면 시뮬 렌더 검증 (제목/가격/Subscribe + 복원·약관·개인정보)
- [x] 빌드번호 올림 CURRENT_PROJECT_VERSION 2 → 4 (리젝 빌드가 3이라 새 빌드 필요)
- [ ] (수동) ASC: 개인정보 처리방침 URL 필드 입력
- [ ] (수동) ASC: 앱 설명 또는 EULA 필드에 표준 EULA 링크
- [ ] (수동) 새 빌드 아카이브·업로드 후 Apple 회신 + 화면 녹화 첨부

## 브랜치 정리 - 완료 (2026-07-13)
- [x] docs/readme-support-link → main 머지
- [x] dev → main 머지 (AlarmKit·페이월 배지·로컬라이제이션 등 전부 반영, commit 8ef5876)
- [x] main push, 머지된 브랜치 로컬/원격 삭제
- [x] main에서 dev 새로 생성 후 push (origin/dev 추적)

## 무료 음원 확장 + v4.0.3 - 완료 (2026-07-13)
- [x] 무료 카테고리 2개 → 5개 확장 (물방울·싱잉볼 + 새소리·빗소리·앰비언트, ASMR만 프리미엄 유지) — SubscriptionManager.freeCategories
- [x] MARKETING_VERSION 4.0.1 → 4.0.3 (빌드번호 4 유지)
- [x] RELEASE_NOTES_4.0.3.md 작성 (한/영 App Store용)
- [x] 시뮬레이터 빌드 검증 (BUILD SUCCEEDED)

## 무료 사용 코드 (개발자용 프로모션) - 완료 (2026-07-13)
- [x] SubscriptionManager: 고정 코드 `DALBIT-MOON`, 리딤 시 1개월 프리미엄(UserDefaults 만료일), isPremium 판정에 반영
- [x] SubscriptionView: 페이월 하단 "무료 사용 코드가 있나요?" → 입력필드/적용 버튼, 성공 시 만료일 표시 후 자동 닫힘
- [x] AnalyticsManager: promo_redeem 이벤트 추가
- [x] 로컬라이제이션 5키 (ko/en) string catalog 추가
- [x] 시뮬레이터 빌드 검증 (BUILD SUCCEEDED)
- 참고: 코드 변경은 SubscriptionManager.promoCode 상수 한 곳

## 남은 작업 (수동 - 코드 아님)
- [x] dev 브랜치 코드 변경 push / PR → main 머지로 완료 (2026-07-13)
- [ ] App Store Connect: App Description 또는 EULA 필드에 표준 약관 링크 추가
- [ ] App Store Connect: Privacy Policy 필드에 https://m1zz.github.io/RelaxOn/privacy.html 입력
- [ ] Guideline 2.3.3: 6.5"/5.5" iPhone 스크린샷을 최신 UI로 교체 (수동)
- [ ] Apple에 회신
