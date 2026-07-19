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

## GitHub 저장소 RelaxOn → Dalbit 리네임 반영 - 완료 (2026-07-14)
- [x] README 리브랜딩: 제목 달빛(Dalbit), App Store 링크 새 앱명, 스크린샷/지원/개인정보 링크 새 URL
- [x] SubscriptionView 개인정보 처리방침 URL 수정 (구 URL은 404): m1zz.github.io/Dalbit/privacy.html
- [x] docs/index.html GitHub 링크 → github.com/M1zz/Dalbit
- [x] 로컬 git remote → https://github.com/M1zz/Dalbit.git
- [x] CLAUDE.md의 "저장소·Pages는 여전히 RelaxOn" 문구 갱신
- [ ] (수동) App Store Connect: Privacy Policy URL 필드도 새 URL로 갱신 필요

## 미디 음원 프리뷰 + 첫 실행 무료 음원 + 효과음 끄기 TipKit - 완료 (2026-07-14)
방향: 미디로 만든 배경음악을 전면에. 효과음(레이어 사운드)은 끌 수 있게.
- [x] 사운드 제작 화면 배경음악 카드 프리뷰: 탭=단독 재생, 재탭=정지, 다른 카드=전환 (CreateNewSoundView + AudioEngineManager.playBackground/stopBackground)
  - 전체 미리듣기 중이면 기존처럼 믹스에 포함해 재시작. 카드에 재생중 배지(speaker.wave) 표시.
- [x] 첫 실행 시 순수 미디 음원 3개 무료 제공: 달빛 피아노/포근한 로파이/고요한 명상 (효과음 레이어 없음, 배경음악만)
  - PresetSound.toCustomSound() empty-layers 처리 → filter/category .none 배경 전용 CustomSound
  - allPresets 맨 앞에 배치 → presetSounds.first 자동 선택되어 첫 화면에서 바로 들림
- [x] 효과음 끄기 전역 토글: AudioEngineManager.effectsMuted (UserDefaults 영속), 켜면 배경음악만 재생
  - 보관함(SavedSoundsListView) 상단에 토글 UI 추가. 재생 중 토글 시 현재 사운드 즉시 재평가.
- [x] TipKit: 효과음 거슬리면 아래로 스와이프→보관함에서 끄라고 안내. 앱 실행 초반 최대 3회(MaxDisplayCount 3). '보관함 열기' 액션 → goTo(0). 사용자가 끄면 팁 invalidate.
  - DalbitApp에서 Tips.configure 초기화. 홈(page 1)에서만 상단에 TipView.
- [x] 로컬라이제이션(ko/en): preset_midi.* 6키, library.effects_toggle(+hint), common.on/off, tip.effects_off.*(+open_library) 추가
- [x] 시뮬레이터 빌드 검증 (BUILD SUCCEEDED)

## 위성(달 궤도) 시각 조정 - 완료 (2026-07-14)
- [x] 더 흐릿하게: 순백 코어·흰 테두리 제거(부드러운 밝은 코어), 채도 0.55→0.30, 빛무리 opacity 0.6→0.30, 본체 blur 1.1, 표시 opacity 1→0.7
- [x] 더 천천히: 공전 주기 780초(13분)→1560초(26분), 노출 시간도 동일하게 연장
- [x] 색상 보색 회피: 랜덤 hue(0~1) → 달 색(orbTint) hue ±0.05 유사색으로 제한 (UIColor.getHue로 달 hue 추출)
- [x] 시뮬레이터 빌드 성공

## v4.0.4 릴리즈 - 완료 (2026-07-14)
- [x] MARKETING_VERSION 4.0.3 → 4.0.4 (Debug/Release 둘 다)
- [x] CURRENT_PROJECT_VERSION(빌드번호) 4 → 5 (새 바이너리 업로드용)
- [x] RELEASE_NOTES_4.0.4.md 작성 (한/영 App Store용): 미디 음원 3곡·배경음악 프리뷰·효과음 끄기·위성 조정
- [ ] (수동) 아카이브·업로드 후 App Store Connect 제출

## 인앱 피드백(CloudKit) + 호흡·위성 조정 + v4.0.5 - 완료 (2026-07-19)
방향: ClipKeyboard의 CloudKit Public DB 피드백 구조를 이식 (메일 앱 불필요, 개발자는 앱 안 인박스에서 확인)
- [x] FeedbackService (Manager/): 컨테이너 `iCloud.com.leeo.LullabyRecipe`, "Feedback" 레코드 제출/조회/완료표시/삭제
- [x] FeedbackView (Views/Settings/): 유형 칩(버그/제안/문의/기타)·내용·자동첨부 기기정보, CloudKit 실패 시 mailto: 폴백
- [x] FeedbackInboxView (개발자 전용, 한국어 고정): 목록/완료 스와이프/삭제/내 userRecordName 복사
- [x] 진입 동선: 보관함(아래 스와이프) '개발자에게 의견 보내기' 행 → FeedbackView, 같은 행 1.5초 길게 누르면 인박스(숨은 동선)
- [x] 엔타이틀먼트에 iCloud(CloudKit) + 컨테이너 추가
- [x] 로컬라이제이션 19키(ko/en) + L.Feedback 키 추가
- [x] 달 호흡을 공명 호흡 연구에 맞춤: 분당 6회(반주기 5초, 0.1Hz), 진폭 ±3.25%→±1.5%로 더 미묘하게
- [x] 위성 흰색 방지: 채도 하한↑(0.35~0.62)·명도 상한↓(0.52~0.82) — 어떤 달 색에서도 쨍한 흰 톤 없음
- [x] MARKETING_VERSION 4.0.4→4.0.5, 빌드번호 5→6, RELEASE_NOTES_4.0.5.md 작성
- [x] 시뮬레이터 빌드 검증 (BUILD SUCCEEDED)
- [ ] (수동) CloudKit Dashboard: Feedback 레코드 타입 확인, World=create만 허용, admin 역할(read/write)+개발자 userRecordName 등록, 스키마 Production 배포
- [ ] (수동) Xcode Signing & Capabilities에서 iCloud 컨테이너가 프로비저닝에 반영되는지 실기기 확인

## 위성 = 하트(즐겨찾기) 버튼 + 즐겨찾기만 재생 - 완료 (2026-07-19)
방향: 위성이 느리게 돌며 하트를 싣고 옴 — 원할 때 누를 수 없는 '느린 즐겨찾기' 컨셉
- [x] CampfireView 위성에 하트 아이콘(빈/채움)·깊은 유사색 얇은 링(버튼 힌트) — 흰색 아님
- [x] 위성이 궤도 앞쪽 반을 지날 때만 탭 가능(contentShape 확대) → 현재 소리 즐겨찾기 토글 + flashLabel 피드백
- [x] VoiceOver: 오브 접근성 액션에 '즐겨찾기' 추가 (위성이 안 떠 있어도 가능)
- [x] 즐겨찾기만 재생: @AppStorage("favoritesOnlyPlayback"), 홈 스와이프/잠금화면 ⏮⏭ 순환 풀에 반영(즐겨찾기 없으면 전체로 폴백)
- [x] 보관함에 '즐겨찾기만 재생' 토글(즐겨찾기 없으면 비활성+안내), 로컬라이제이션 5키(ko/en)
- [x] 재생 시작 시에도 위성 등장 (isPlaying onChange → flashSatellite, 이미 떠 있으면 유지) — 위성은 원래 스와이프 전용이었음(86f6a6a), 재생 중 달 위상 그림자(20분 주기)는 기존 그대로
- [x] 위성 → 하트 버튼 변신 연출: 8초 평범한 위성 → 2초 모프로 분홍(로즈) 구슬 + 하트 등장, 1.6초 주기 '위웅위웅' 펄스(크기 ±6%·빛무리·그림자 radius 동반 변화), 변신 후 선명도 0.7→0.95
- [x] 탭 판정을 부모 orbGesture(global 좌표)로 이동: 전체화면 DragGesture(minimumDistance:0)가 자식 onTapGesture를 가로채 재생/일시정지가 되던 문제 해결 — 탭 위치를 시간 기반 궤도 위치와 비교(orbCenter는 onGeometryChange로 추적), 위성 위면 즐겨찾기·아니면 재생 토글
- [x] 뒤쪽 반이라도 달 림(반지름 110) 밖으로 보이면 탭 허용 (보이는데 안 눌리는 구간 제거)
- [x] 변신 완료 직후 안내 라벨 1회: "하트 위성을 탭하면 이 소리가 즐겨찾기에 담겨요" (listen.satellite_hint ko/en)
- [x] 시뮬레이터 스크린샷 검증: 분홍 하트·펄스(빛무리 크기 변화)·안내 라벨 렌더 확인 + 빌드 성공
- [x] 달 위상 그림자 2단계: 처음 1/16(1.0→0.88)은 20초 easeOut으로 빠르게 → 나머지는 1125초 easeInOut 왕복(속도 비율 유지). 일시정지 시 moonCycleToken으로 2단계 예약 취소. 스크린샷으로 20초 시점 그림자 확인

## 위성 하트 롤백 + 설정 페이지 신설 + 우주 이벤트 간격 완화 - 완료 (2026-07-19)
- [x] 위성 핑크 하트 변신·펄스·하트 아이콘·탭 판정 전부 제거 → 위성은 순수 장식으로 복원 (즐겨찾기는 달 길게 누르기로 일원화)
- [x] listen.satellite_hint 키 삭제, 팁/보관함 문구에서 위성 하트 언급 제거
- [x] 우주 이벤트 최소 등장 간격 4분: 첫 등장 240~360초, 이후 240~480초
- [x] SettingsView 전면 재작성(구 타이머 설정 대체): 사운드(효과음 끄기·즐겨찾기만 재생)/지원(의견 보내기)/정보(앱 버전) 섹션
  - 진입: 보관함 헤더 톱니(gearshape) 버튼 → push. 보관함에서 세 개 행 제거(리스트가 다시 주인공)
  - 히든 모드: 앱 버전 7번 연속 탭(2초 안 누르면 리셋) → FeedbackInboxView. 기존 '의견 보내기 행 길게 누르기' 동선 삭제
- [x] 로컬라이제이션: settings.* 5키 추가, 효과음 팁 문구를 설정 경로로 갱신
- [x] 시뮬레이터 빌드 검증 (BUILD SUCCEEDED)

## 달 길게 누르기 = 즐겨찾기 (피로도 개선) - 완료 (2026-07-19)
방향: 위성 하트는 '보너스'로 유지, 달을 1초 지그시 누르면 언제든 즐겨찾기 토글
- [x] orbGesture 터치다운 시 DispatchWorkItem 예약(1.0초, 달 중심 150pt 이내만), 10pt 이상 움직이면 취소, 발동 시 onEnded의 탭/드래그 처리 건너뜀
- [x] 발동: toggleFavoriteCurrent + pressOrb(옴폭) + 담을 때 달 위 하트 팝(스프링 등장→1초 뒤 페이드)
- [x] FavoriteLongPressTip (TipKit, MaxDisplayCount 3): "달을 지그시 눌러보세요" — 직접 길게 누르면 invalidate. 홈 상단 효과음 팁 아래 배치
- [x] 로컬라이제이션 2키(ko/en), 시뮬레이터에서 팁 표시 확인 + 빌드 성공

## 우주 여행 앰비언트 (혜성·행성·우주선) - 완료 (2026-07-19)
- [x] CosmicEventsView 신규: 별밭 위·달 뒤 레이어, TimelineView 시간 기반(위치 lerp·양끝 페이드·점멸)
- [x] 혜성(꼬리+코어, 얼음청/따뜻한 주황, 5.5~8.5초 대각선) / 먼 행성(라디얼 구체+절반 확률 고리, 30~50초 수평 드리프트) / 우주선(동체+창문+0.9초 점멸등, 9~14초 사선)
- [x] 빈도: 첫 등장 20~45초, 이후 50~140초 간격 랜덤. 달(중앙)을 피해 상단 8~26%/하단 74~90% 띠로만 지나감
- [x] 버그 수정: onAppear 시점 geo.size가 레이아웃 확정 전 값이라 경로가 화면 꼭대기에 몰림 → canvas @State로 상시 추적, 발사 시점 크기 사용(+크기 미확정 시 3초 재시도)
- [x] 시뮬레이터 검증: 혜성이 우측에서 정상 밴드(fy≈0.16)로 꼬리 끌며 진입하는 프레임 캡처 확인, 빌드 성공

## visionOS / tvOS 지원 검토 → 하지 않기로 결정 (2026-07-19)
- [x] 검토 결과: tvOS는 별도 타깃 필요(AlarmKit·CoreMotion·햅틱·스와이프 UI 블로커), visionOS는 'Designed for iPad' 호환만 가능
- [x] 결정: 둘 다 지원하지 않음 — 잠시 추가했던 SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD 설정 제거 (iOS/iPadOS 전용 유지)

## 남은 작업 (수동 - 코드 아님)
- [x] dev 브랜치 코드 변경 push / PR → main 머지로 완료 (2026-07-13)
- [ ] App Store Connect: App Description 또는 EULA 필드에 표준 약관 링크 추가
- [ ] App Store Connect: Privacy Policy 필드에 https://m1zz.github.io/Dalbit/privacy.html 입력 (저장소 리네임으로 URL 변경됨)
- [ ] Guideline 2.3.3: 6.5"/5.5" iPhone 스크린샷을 최신 UI로 교체 (수동)
- [ ] Apple에 회신
