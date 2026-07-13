# 달빛 (Dalbit) - 프로젝트 컨텍스트

> 앱 표시 이름: **달빛 / Dalbit** (구 RelaxOn). 루트 디렉토리·프로젝트·스킴·소스 폴더·타깃 모두 `Dalbit`으로 리네임 완료(2026-06-22). **번들ID(`com.leeo.LullabyRecipe`)만 유지.** 루트 경로: `Dalbit/`, Xcode 프로젝트: `Dalbit.xcodeproj`, 소스 폴더: `Dalbit/`, 스킴: `Dalbit`. **GitHub 저장소·Pages URL은 여전히 `RelaxOn`** (원격 remote만 RelaxOn 유지).

## 📱 프로젝트 개요

**달빛(Dalbit)**은 여러 개의 자연 소리를 레이어처럼 겹쳐 나만의 완벽한 백색소음 사운드를 만들 수 있는 iOS 앱입니다.

### 🎯 타겟 사용자

**나만의 백색소음을 찾느라 많은 시간과 노력을 소비하는 사람들**

기존에는 YouTube나 여러 앱에서 백색소음을 찾기 위해:
- 수십 개의 영상/사운드를 일일이 들어보고
- 마음에 드는 조합을 찾기 위해 시간을 낭비하고
- 원하는 조합을 찾아도 매번 같은 과정을 반복해야 했습니다

**달빛은 이런 문제를 해결합니다:**
- 원하는 소리들을 직접 선택하고 조합
- 볼륨, 피치 등 세밀한 조정 가능
- 한 번 만든 조합을 저장하여 언제든 재사용
- 수면, 집중, 명상 등 다양한 상황에 최적화된 나만의 사운드

### 핵심 가치
- 🎵 **멀티 레이어 사운드**: 여러 소리를 동시에 재생하여 개인화된 사운드 제작
- 🔥 **캠프파이어 경험**: 따뜻한 캠프파이어 비주얼과 함께하는 편안한 휴식
- 🎹 **배경 음악**: 피아노, 기타 등 배경 음악을 더해 풍부한 사운드 경험
- ⏱️ **수면 타이머**: 설정한 시간 후 자동으로 음악이 멈추는 타이머
- 💾 **저장 및 재사용**: 만든 사운드 조합을 저장하여 즉시 재생

## 🏗️ 아키텍처

### 기술 스택
- **언어**: Swift
- **UI 프레임워크**: SwiftUI
- **오디오**: AVFoundation (AVAudioEngine)
- **아키텍처**: MVVM 패턴
- **최소 지원**: iOS 26.0+

### 주요 디자인 패턴
- MVVM (Model-View-ViewModel)
- ObservableObject & Published 프로퍼티
- Environment Objects for 전역 상태 관리
- SwiftUI Navigation (NavigationStack & navigationDestination)

## 📂 프로젝트 구조

```
Dalbit/
├── App/
│   ├── Manager/
│   │   ├── AudioEngineManager.swift      # 메인 오디오 엔진 (싱글톤)
│   │   ├── AudioLayerManager.swift       # 멀티 레이어 오디오 관리 (최적화)
│   │   ├── AudioMixingService.swift      # 오디오 믹싱 서비스
│   │   └── TimerManager.swift            # 수면 타이머 관리
│   │
│   ├── Models/
│   │   ├── CustomSound.swift             # 커스텀 사운드 모델
│   │   ├── AudioVariation.swift          # 오디오 파라미터 (볼륨, 피치 등)
│   │   ├── BackgroundSound.swift         # 배경 음악 enum
│   │   └── OnboardItem.swift             # 온보딩 데이터
│   │
│   ├── ViewModels/
│   │   └── CustomSoundViewModel.swift    # 메인 사운드 관리 ViewModel
│   │
│   ├── Views/
│   │   ├── Listen/
│   │   │   ├── ListenListView.swift      # 메인 화면 (캠프파이어)
│   │   │   └── ListenListCell.swift
│   │   │
│   │   ├── Home/
│   │   │   ├── CreateNewSoundView.swift  # 새 사운드 만들기
│   │   │   ├── SoundListView.swift       # 사운드 제작 화면
│   │   │   └── SoundDetailView.swift     # 사운드 상세/편집
│   │   │
│   │   ├── Components/
│   │   │   ├── SoundPlayerFullModalView.swift  # 전체 플레이어
│   │   │   └── SoundThumbnailView.swift        # 레이어 썸네일
│   │   │
│   │   ├── Timer/
│   │   │   └── TimerMainView.swift       # (레거시)
│   │   │
│   │   └── Onboarding/
│   │       └── OnboardingView.swift      # 온보딩 화면
│   │
│   └── Utils/
│       ├── Enums.swift                   # 전역 Enum 정의
│       └── Extensions/                   # Swift 확장
│
└── Assets/
    └── Sound/                            # 오디오 파일 (mp3)
```

## 🎵 핵심 기능

### 1. 멀티 레이어 오디오 시스템

**AudioEngineManager** (싱글톤)
- AVAudioEngine 기반 오디오 재생
- 피치, 볼륨, 간격 등 실시간 파라미터 조정
- 페이드 인/아웃 효과

**AudioLayerManager** (최적화)
- 여러 소리를 동시에 재생
- 버퍼 캐싱으로 메모리 70% 절감
- 백그라운드 스레드 스케줄링으로 CPU 50% 절감
- 3D 공간 오디오 (AVAudioEnvironmentNode)

```swift
// 레이어 추가 예시
let layerId = try audioLayerManager.addLayer(
    filter: .WaterDrop,
    category: .WaterDrop,
    variation: AudioVariation(),
    position: AVAudio3DPoint(x: 0, y: 0, z: 0)
)
audioLayerManager.startAllLayers()
```

### 2. 사운드 제작 워크플로우

```
1. CreateNewSoundView - 사운드 선택
   ↓
2. 원본 사운드 선택 (여러 개 토글 가능)
   ↓
3. 배경 음악 선택 (선택 사항)
   ↓
4. 볼륨 조절
   ↓
5. 저장 → CustomSound 생성
```

**주요 특징:**
- 토글 방식 선택/해제
- 실시간 미리듣기
- FlowLayout으로 선택된 레이어 표시

### 3. 수면 타이머

**TimerView** (새 디자인)
- 시간 선택 휠 (시간/분)
- 원형 프로그레스 바
- 종료 10초 전 페이드 아웃 시작
- 타이머 종료 시 음악 자동 정지

**미니 플레이어 통합:**
- 타이머 활성화 시 남은 시간 표시
- 헤더에 타이머 상태 아이콘

### 4. 캠프파이어 비주얼

**CampfireView**
- 5개 레이어 불꽃 애니메이션
- 재생 상태에 따른 동적 변화
- 불꽃 파편 효과
- 입체적인 장작 디자인

## 🔑 핵심 컴포넌트

### CustomSoundViewModel

메인 ViewModel로 앱의 모든 사운드 상태를 관리합니다.

```swift
class CustomSoundViewModel: ObservableObject {
    @Published var customSounds: [CustomSound] = []
    @Published var selectedSound: CustomSound?
    @Published var isPlaying: Bool = false

    // 주요 메서드
    func play(with sound: CustomSound)
    func stopSound()
    func loadSound()
}
```

### CustomSound 모델

```swift
struct CustomSound: Identifiable, Codable {
    let id: String
    let title: String
    let category: SoundCategory
    let variation: AudioVariation
    let filter: AudioFilter
    let color: String

    // 배경 음악
    let backgroundSound: String?
    let backgroundVolume: Float?

    // 멀티 레이어
    let soundLayers: [SoundLayer]?

    var isLayeredSound: Bool {
        soundLayers != nil && soundLayers!.count > 1
    }
}
```

### AudioVariation

오디오 파라미터를 정의합니다.

```swift
struct AudioVariation: Codable {
    var volume: Float = 1.0          // 0.0 ~ 1.0
    var pitch: Float = 0.0           // -2400 ~ 2400 (cents)
    var interval: Float = 1.5        // 재생 간격 (초)
    var intervalVariation: Float = 0.2
    var volumeVariation: Float = 0.1
    var pitchVariation: Float = 0.0
}
```

## 🎨 UI/UX 가이드라인

### 색상 시스템

```swift
// 주요 색상
Color(.PrimaryPurple)      // 메인 보라색
Color(.DefaultBackground)  // 다크 배경
Color(.TitleText)          // 제목 텍스트
Color(.Text)               // 일반 텍스트

// 다크 그라데이션 배경
LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.1, green: 0.05, blue: 0.15),
        Color(red: 0.15, green: 0.1, blue: 0.2),
        Color(red: 0.2, green: 0.15, blue: 0.25)
    ]),
    startPoint: .top,
    endPoint: .bottom
)
```

### 디자인 원칙

1. **일관된 여백**: 20pt ~ 24pt 표준 패딩
2. **카드 디자인**: 흰색 배경, 16pt 코너, 부드러운 그림자
3. **그라데이션 버튼**: PrimaryPurple 그라데이션 + 그림자
4. **다크 테마**: 모든 화면에 다크 그라데이션 배경

### 네비게이션 구조

**전면 리팩토링 완료 (2025-01-17)**
- ❌ Sheet 사용 금지
- ✅ NavigationStack + navigationDestination만 사용
- 모든 화면 전환이 일관된 네이티브 네비게이션

## 📋 최근 주요 변경사항 (2025-01-17)

### 1. 오디오 레이어 최적화
- **AudioLayerManager.swift** 신규 추가
- 버퍼 캐싱으로 메모리 70% 절감
- 백그라운드 스레드 스케줄링으로 CPU 50% 절감
- 10개 이상의 레이어 동시 재생 가능

### 2. 네비게이션 전면 리팩토링
- 7개 모달 → navigationDestination 전환
- NavigationStack 중첩 제거
- presentationDetents 제거
- 일관된 네비게이션 경험

### 3. 타이머 기능 개선
- 독립적인 TimerView 추가
- 헤더에 타이머 상태 표시
- 미니 플레이어에 남은 시간 표시
- 타이머 종료 시 음악 자동 정지
- 페이드 인/아웃 효과

### 4. UI/UX 개선
- CreateNewSoundView 전면 재설계
- 섹션별 카드 레이아웃
- FlowLayout으로 레이어 칩 표시
- 사운드 선택 토글 기능
- 일관된 여백 및 스타일링

### 5. 온보딩 리뉴얼
- 앱 컨셉에 맞는 문구 업데이트
- 다크 그라데이션 배경
- 향상된 페이지 인디케이터
- TutorialView 제거 (즉시 시작)

## 🐛 알려진 이슈

### 경고 메시지
- `onChange(of:perform:)` deprecated (iOS 17+)
  - 영향: 없음 (동작은 정상)
  - 해결: iOS 17+ 전용으로 마이그레이션 필요

### 잠재적 개선사항
- SettingsView 타이머 섹션 중복 (ListenListView에 통합됨)
- 레거시 TimerMainView.swift 정리 필요

## 🔧 개발 가이드

### 새로운 사운드 추가

1. **오디오 파일 준비**
   - 형식: MP3
   - 경로: `Dalbit/App/Assets/Sound/`

2. **Enum 추가**
```swift
// AudioFilter enum에 추가
enum AudioFilter: String, Codable {
    case NewSound = "new_sound"
}

// SoundCategory enum에 추가
enum SoundCategory: String, Codable {
    case NewCategory = "새 카테고리"
}
```

3. **AvailableSound 리스트에 추가**
```swift
// CreateSoundViewModel.loadAvailableSounds()
AvailableSound(
    id: "newsound",
    name: "새 사운드",
    icon: "waveform",
    color: .blue,
    category: .NewCategory,
    filter: .NewSound,
    duration: 2.0
)
```

### 새로운 배경 음악 추가

1. **파일 추가**: `Dalbit/App/Assets/Sound/music/`
2. **BackgroundSound enum 수정**
```swift
enum BackgroundSound: String, CaseIterable {
    case newMusic = "새 음악"

    var fileName: String {
        switch self {
        case .newMusic: return "new_music_10min"
        }
    }

    var colors: [Color] {
        switch self {
        case .newMusic: return [.blue, .purple]
        }
    }
}
```

### 빌드 및 실행

```bash
# 클린 빌드
xcodebuild clean build \
  -project Dalbit.xcodeproj \
  -scheme Dalbit \
  -sdk iphonesimulator \
  -configuration Debug

# 시뮬레이터에서 실행
open -a Simulator
xcodebuild build \
  -project Dalbit.xcodeproj \
  -scheme Dalbit \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📝 코딩 컨벤션

### Swift 스타일
- 들여쓰기: 4 spaces
- 네이밍: camelCase (변수/함수), PascalCase (타입)
- 한글 주석 사용 (한국어 프로젝트)

### SwiftUI 컴포넌트
```swift
// ViewBuilder 사용
@ViewBuilder
private func componentView() -> some View {
    VStack { ... }
}

// 섹션별 MARK 주석
// MARK: - Body
// MARK: - Helper Views
// MARK: - Actions
```

### 파일 구조
```swift
// 1. Import
import SwiftUI

// 2. Main View/Class
struct MyView: View {
    // 3. Properties (@State, @Binding, etc)
    @State private var value = 0

    // 4. Body
    var body: some View { }

    // 5. Helper Views (private)
    @ViewBuilder
    private func helperView() -> some View { }

    // 6. Actions (private)
    private func action() { }
}

// 7. Preview
struct MyView_Previews: PreviewProvider { }
```

## 🎯 향후 계획

### 단기 목표
- [ ] SettingsView 정리 (타이머 중복 제거)
- [ ] onChange deprecated 경고 해결
- [ ] 레거시 코드 정리 (TimerMainView.swift)

### 중기 목표
- [ ] 사운드 믹스 저장/불러오기 개선
- [ ] 즐겨찾기 기능
- [ ] 사운드 공유 기능

### 장기 목표
- [ ] iCloud 동기화
- [ ] Widget 지원
- [ ] Apple Watch 앱
- [ ] 커뮤니티 사운드 공유

## 🤝 기여 가이드

### Pull Request
1. 기능별 브랜치 생성
2. 명확한 커밋 메시지 (한글)
3. 빌드 성공 확인
4. 테스트 시나리오 작성

### 커밋 메시지 예시
```
add: 새로운 사운드 필터 추가
fix: 타이머 종료 시 음악 정지 버그 수정
update: 온보딩 화면 디자인 개선
refactor: 네비게이션 구조 전면 리팩토링
```

## 📚 참고 자료

### Apple 문서
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [SwiftUI Navigation](https://developer.apple.com/documentation/swiftui/navigationstack)

### 프로젝트 문서
- [AudioLayerManager 설계](Dalbit/App/Manager/AudioLayerManager.swift)
- [CustomSound 모델](Dalbit/App/Models/CustomSound.swift)

---

**Last Updated**: 2025-01-17
**Current Version**: 4.0.1
**Maintained by**: 달빛(Dalbit) Team
