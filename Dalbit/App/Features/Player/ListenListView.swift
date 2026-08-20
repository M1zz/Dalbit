//
//  ListenListView.swift
//  Dalbit
//
//  Created by Doyeon on 2023/03/09.
//

import SwiftUI
import UIKit
import MediaPlayer
import CoreMotion
import TipKit

struct ListenListView: View {

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @State private var searchText = ""

    @State private var selectedFile = CustomSound()
    @State private var isShowingSheet = false
    @State private var isShowingPlayer = false
    @State private var editingSound: CustomSound? = nil
    @State private var isShowingEditView = false
    @State private var isShowingCreateModal = false
    @State private var isShowingTimer = false
    @State private var orbPressed = false
    @State private var orbTapPress = false   // 재생/일시정지 탭 시 옴폭 눌리는 효과
    // 오브 스와이프(다음 소리) — 손가락 따라 3D로 굴러가는 느낌
    @State private var orbCommitted: Double = 0   // 확정된 회전(전환 시 ±360 누적)
    @State private var orbDragAngle: Double = 0   // 드래그 중 실시간 회전
    // 세로 굴림(모드 전환): 0=보관함(위), 1=홈(구체), 2=타이머(아래)
    @State private var page: Int = 1
    @State private var dragY: CGFloat = 0
    @State private var vLock: Bool? = nil   // nil=미결정, true=세로, false=가로
    // 구체 세로 회전(전환 시 위/아래로 굴러가는 모습)
    @State private var orbCommittedV: Double = 0
    @State private var orbDragV: Double = 0
    // 오디오 전환 디바운스 (스와이프 중 디코딩으로 롤이 끊기는 것 방지)
    @State private var audioSwitchWork: DispatchWorkItem?
    // 달을 돌리면 나타나 아주 천천히(약 13분/바퀴) 궤도를 도는 위성
    @State private var satelliteVisible = false
    @State private var satelliteToken = 0
    @State private var satelliteStartTime: Double = 0   // 등장 시각(궤도 위상 기준)
    @State private var satelliteStartAngle: Double = 0.62   // 등장 시작각(좌/우 뒤 랜덤)
    @State private var satelliteHue: Double = 0             // 위성 색상(랜덤)
    @State private var satelliteScale: Double = 1.0         // 위성 크기 배리에이션(랜덤)
    // 앱 시작 시 구체가 데굴데굴 굴러 들어오는 등장 애니메이션 (매번 다른 위치 + 기울기 방향)
    @State private var orbAppearOffsetX: CGFloat = 0
    @State private var orbAppearOffsetY: CGFloat = 0
    @State private var orbAppearRoll: Double = 0
    @State private var orbAppearRollY: Double = 0
    @State private var orbEntranceReady = false   // 시작 위치를 잡기 전엔 숨김(중앙 깜빡임 방지)
    @State private var didOrbEntrance = false
    @State private var didAutoPlay = false         // 앱 시작 시 우주 앰비언트 1회 자동재생
    @State private var motionManager = CMMotionManager()
    @State private var showNameLabel = false
    @State private var nameLabelText = ""
    @State private var nameToken = 0
    @AppStorage("didShowSwipeHint") private var didShowSwipeHint = false
    // 즐겨찾기만 재생 모드 (보관함 토글과 공유)
    @AppStorage("favoritesOnlyPlayback") private var favoritesOnlyPlayback = false
    // 달 중심의 화면(global) 좌표 — 달 길게 누르기(즐겨찾기) 판정용
    @State private var orbCenter: CGPoint = .zero
    // 달이 우주를 떠다니는 느낌 — 0~1을 아주 느리게 왕복한다.
    // 가로·세로 주기를 서로 다르게(47초 / 31초) 줘야 같은 길을 오가는 게 아니라
    // 천천히 배회하는 궤적이 된다.
    @State private var floatX: CGFloat = 0
    @State private var floatY: CGFloat = 0
    @State private var isFloating = false
    /// 내가 흔들리는 폭. 가장 가까운 것(달)이 이만큼 움직이고,
    /// 먼 것일수록 조금만 움직인다 — 이 차이(시차)가 "내가 움직인다"로 읽히게 한다.
    private static let floatRangeX: CGFloat = 56
    private static let floatRangeY: CGFloat = 34
    /// 시차 계수 — 별(가장 멀다) < 앰비언트 천체 < 달(가장 가깝다)
    private static let parallaxStars: CGFloat = 0.10
    private static let parallaxCosmic: CGFloat = 0.34

    /// 내 흔들림(-0.5~0.5). 모든 레이어가 이 하나를 공유한다.
    private var swayX: CGFloat { floatX - 0.5 }
    private var swayY: CGFloat { floatY - 0.5 }
    /// 아주 느린 기울어짐 — 우주에서는 몸이 조금씩 돌아간다
    private var swayRoll: Double { Double(swayX) * 2.6 }
    // 모드 전환 안내 칩(타이머/보관함): 뉴비에게만 노출 — 써봤거나 몇 번 열면 숨김
    @AppStorage("homeAppearCount") private var homeAppearCount = 0
    @AppStorage("didUseModeSwitch") private var didUseModeSwitch = false
    // 첫 실행 1회 제스처 안내
    @AppStorage("didShowGestureCoach") private var didShowGestureCoach = false
    /// 첫 실행 안내(MainTabView 가 덮어 띄운다)를 아직 보고 있는지.
    /// ⚠️ 안내가 덮여 있는 동안 코치마크를 띄우면 안 된다 — 화면 뒤에서 혼자 나타났다가,
    ///    안내를 닫는 순간 이미 떠 있는 상태로 발견된다. "달이 나오고 나서 알려 준다"는
    ///    순서가 깨지면 조작 설명이 무엇에 대한 것인지 알 수 없다.
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false
    // 효과음 끄기 안내 팁 (앱 실행 초반 최대 3회)
    private let effectsOffTip = EffectsOffTip()
    // 달 길게 누르기 = 즐겨찾기 안내 팁 (초보자에게만 가끔, 최대 3회)
    private let favoriteTip = FavoriteLongPressTip()
    // 달 길게 누르기(1초) 즐겨찾기 — 터치 다운 시 예약, 움직이면 취소
    @State private var longPressWork: DispatchWorkItem?
    @State private var longPressFired = false
    @State private var touchActive = false
    // 즐겨찾기에 담을 때 달 위로 떠오르는 하트 팝
    @State private var heartBurst = false
    @State private var heartBurstToken = 0
    @State private var showCoach = false
    @State private var countedThisSession = false
    @StateObject private var timerManager = TimerManager(viewModel: CustomSoundViewModel())
    
    // MARK: - Body
    var body: some View {
        // 세로 굴림 페이저: 위로 스와이프=타이머(아래에서 올라옴), 아래로 스와이프=보관함(위에서 내려옴)
        ZStack {
            // 배경만 화면 전체를 채우고, 페이지는 safe area 안에 둬서
            // 중첩 NavigationStack(타이머/보관함)의 상단 바가 상태바에 가리지 않게 한다.
            ScreenBackground().ignoresSafeArea()
            // 우주 느낌의 은은한 별 (홈 배경)
            // 가장 먼 레이어라 내가 흔들려도 아주 조금만 따라 움직인다.
            Starfield()
                .ignoresSafeArea()
                .offset(x: swayX * Self.floatRangeX * Self.parallaxStars,
                        y: swayY * Self.floatRangeY * Self.parallaxStars)
                .rotationEffect(.degrees(swayRoll * 0.35))
            // 우주 여행 앰비언트 — 가끔 혜성·먼 행성·우주선이 지나간다 (달 뒤로)
            // 별보다 가깝고 달보다 멀다.
            CosmicEventsView()
                .ignoresSafeArea()
                .offset(x: swayX * Self.floatRangeX * Self.parallaxCosmic,
                        y: swayY * Self.floatRangeY * Self.parallaxCosmic)
                .rotationEffect(.degrees(swayRoll * 0.7))

            GeometryReader { geo in
                let H = geo.size.height
                let W = geo.size.width
                // 각 페이지를 개별 오프셋으로 배치: 보관함=위(-H), 홈=가운데(0), 타이머=아래(+H)
                ZStack {
                    libraryPage()
                        .frame(width: W, height: H)
                        .offset(y: pageOffset(0, H))
                        .zIndex(page == 0 ? 1 : 0)

                    homePage()
                        .frame(width: W, height: H)
                        .offset(y: pageOffset(1, H))
                        .zIndex(page == 1 ? 1 : 0)

                    timerPage()
                        .frame(width: W, height: H)
                        .offset(y: pageOffset(2, H))
                        .zIndex(page == 2 ? 1 : 0)
                }
                .frame(width: W, height: H)
                .clipped()
            }

            // 효과음 끄기 안내 팁 (홈에서만, 앱 실행 초반 최대 3회) — 상단에 표시
            if page == 1 && !showCoach {
                VStack {
                    TipView(effectsOffTip) { action in
                        if action.id == EffectsOffTip.openLibraryActionID {
                            goTo(0)   // 아래로 굴러 보관함 열기
                        }
                    }
                    .tipBackground(.ultraThinMaterial)
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.sm)
                    // 달 길게 누르기 = 즐겨찾기 안내 (초보자에게만 가끔)
                    TipView(favoriteTip)
                        .tipBackground(.ultraThinMaterial)
                        .padding(.horizontal, DS.Spacing.screen)
                        .padding(.top, DS.Spacing.xxs)
                    Spacer()
                }
                .zIndex(9)
                .transition(.opacity)
            }

            // 첫 실행 1회: 제스처 사용법 안내 (스킵 가능)
            if showCoach {
                GestureCoachmark { dismissCoach() }
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)

        .navigationDestination(isPresented: $isShowingEditView) {
            if let editing = editingSound {
                SoundDetailView(
                    isTutorial: false,
                    originalSound: OriginalSound(
                        name: editing.category.displayName,
                        filter: editing.filter,
                        category: editing.category
                    ),
                    editingSound: editing
                )
            }
        }

        .trackScreen("Home")
        .onAppear {
            // 앱 실행당 1회만 카운트 (뉴비 안내 칩 노출 판단용)
            if !countedThisSession {
                countedThisSession = true
                homeAppearCount += 1
            }
            startFloating()
            viewModel.loadSound()
            viewModel.loadPresetSounds() // 첫 설치 시 기본 소리(프리셋) 제공
            // 선택된 소리가 없으면 기본 프리셋을 재생 대상으로 지정 → 큰 재생 버튼이 바로 재생 가능
            if viewModel.selectedSound == nil, let firstPreset = viewModel.presetSounds.first {
                viewModel.selectedSound = firstPreset
                viewModel.lastSound = firstPreset
            }
            selectedFile = viewModel.lastSound
            timerManager.viewModel = viewModel
            timerManager.timerDidFinish = {
                // 타이머 종료 시 처리
                print("⏰ 타이머 종료")
            }

            // 앱 시작 시 1회: 우주 앰비언트(space_1min) 자동 재생 (무한 루프)
            // Space는 좌우 굴리기 리스트의 첫 프리셋이기도 하므로 그 항목을 그대로 재생해 리스트와 정합시킨다.
            if !didAutoPlay {
                didAutoPlay = true
                let startup = viewModel.presetSounds.first
                    ?? CustomSound(title: L.PresetSpace.Space.name.localized,
                                   backgroundSound: BackgroundSound.space.rawValue,
                                   backgroundVolume: 0.5)
                viewModel.selectedSound = startup
                viewModel.lastSound = startup
                viewModel.play(with: startup)
            }

            // 처음 한 번: 옆으로 넘기면 소리가 바뀐다는 힌트
            if !didShowSwipeHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    flashLabel(L.Listen.swipeHint.localized, duration: 3.5)
                    didShowSwipeHint = true
                }
            }

            // 잠금화면/제어센터 컨트롤 연결
            setupNowPlaying()

            // 앱 시작 시 1회: 기기 기울기(중력)를 읽어 그 방향에서 데굴데굴 굴러옴
            if !didOrbEntrance {
                didOrbEntrance = true
                // 기울기 샘플을 얻기 위해 모션 업데이트 시작
                if motionManager.isDeviceMotionAvailable {
                    motionManager.deviceMotionUpdateInterval = 0.05
                    motionManager.startDeviceMotionUpdates()
                }
                // 잠깐 기다렸다 중력 읽고 → 그 방향 화면 밖에서 굴러 들어옴
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    let start = computeEntranceStart()
                    motionManager.stopDeviceMotionUpdates()
                    orbAppearOffsetX = start.x
                    orbAppearOffsetY = start.y
                    orbAppearRoll = start.roll
                    orbAppearRollY = start.rollY
                    orbEntranceReady = true   // 시작 위치(화면 밖)에서 등장
                    // 다음 런루프에 가운데로 굴러오기 (시작값이 먼저 반영되어야 애니메이션됨)
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.85, dampingFraction: 0.62)) {
                            orbAppearOffsetX = 0
                            orbAppearOffsetY = 0
                            orbAppearRoll = 0
                            orbAppearRollY = 0
                        }
                        // 착지하는 순간 살짝 눌리는(누르는) 느낌
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
                            withAnimation(.easeOut(duration: 0.1)) { orbPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { orbPressed = false }
                            }
                        }
                    }
                }
            } else {
                orbEntranceReady = true   // 이미 등장했으면 그냥 보이게
            }

            // 첫 실행 1회: 구체가 굴러 들어온 뒤 제스처 안내를 띄움
            // (첫 실행 안내가 아직 떠 있으면 그게 닫힌 뒤에 — 아래 onChange 가 이어받는다)
            scheduleGestureCoachIfNeeded()
        }
        // 재생 상태/곡 변경 시 잠금화면 정보 갱신
        .onChange(of: viewModel.isPlaying) { _, playing in
            updateNowPlaying()
            // 재생을 시작하면 위성이 나와 궤도를 돈다.
            // 이미 떠 있으면 그대로 둠 — 다시 부르면 위치가 순간이동하므로.
            if playing && !satelliteVisible { flashSatellite() }
        }
        .onChange(of: currentSoundTitle) { _, _ in updateNowPlaying() }
        // 첫 실행 안내를 닫은 직후 — 이제 달이 보이니 조작을 알려 줄 차례다.
        .onChange(of: didShowOnboarding) { _, done in
            if done { scheduleGestureCoachIfNeeded() }
        }
    }

    /// 제스처 안내 예약. 아직 안 봤고 첫 실행 안내도 끝났을 때만.
    private func scheduleGestureCoachIfNeeded() {
        guard !didShowGestureCoach, didShowOnboarding, !showCoach else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard !didShowGestureCoach else { return }
            withAnimation(.easeInOut(duration: 0.4)) { showCoach = true }
        }
    }

    /// 달이 우주를 떠다니듯 아주 느리게 흘러가게 한다.
    /// 가로·세로 주기가 달라(47초 / 31초) 왕복이 아니라 천천히 배회하는 궤적이 된다.
    private func startFloating() {
        guard !isFloating else { return }
        isFloating = true
        // repeatForever는 반드시 다음 런루프에서 건다.
        // 같은 트랜잭션에서 걸면 그 프레임에 함께 바뀐 다른 상태까지 이 애니메이션에 끌려간다.
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 47).repeatForever(autoreverses: true)) {
                floatX = 1
            }
            withAnimation(.easeInOut(duration: 31).repeatForever(autoreverses: true)) {
                floatY = 1
            }
        }
    }

    private func dismissCoach() {
        didShowGestureCoach = true
        withAnimation(.easeInOut(duration: 0.3)) { showCoach = false }
    }

    // MARK: - Vertical Pager Pages

    /// 모드 전환 안내 칩 노출 여부 — 아직 한 번도 안 써봤고, 앱을 3번 미만 열었을 때만
    private var showModeHints: Bool {
        !didUseModeSwitch && homeAppearCount < 3
    }

    /// 등장 시작 위치/회전 계산: 기기가 기울어진 방향(중력)에서, 매번 다른 높이에서 굴러오게
    private func computeEntranceStart() -> (x: CGFloat, y: CGFloat, roll: Double, rollY: Double) {
        let distance = CGFloat.random(in: 340...440)
        let gravity = motionManager.deviceMotion?.gravity

        // 가로 방향: 기울기가 뚜렷하면 그쪽에서, 아니면(시뮬레이터 등) 랜덤
        let horiz: Double
        if let g = gravity, abs(g.x) > 0.06 {
            horiz = g.x > 0 ? 1 : -1   // 오른쪽으로 기울면 오른쪽에서 굴러옴
        } else {
            horiz = Bool.random() ? 1 : -1
        }
        // 세로 시작 높이는 매번 랜덤 → 실행마다 다른 위치에서 굴러옴
        let vert = Double.random(in: -0.65...0.65)

        let startX = CGFloat(horiz) * distance
        let startY = CGFloat(vert) * 260
        // 이동량에 비례한 회전 → 실제로 굴러오는 모습
        return (startX, startY, Double(startX) * 1.05, Double(startY) * 1.05)
    }

    /// 재생/일시정지 탭 시: 안쪽으로 옴폭 눌렸다가 스프링으로 통통 튀어나옴
    private func pressOrb() {
        withAnimation(.easeIn(duration: 0.08)) { orbTapPress = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.42)) { orbTapPress = false }
        }
    }

    /// page 1 — 홈(구체). 탭=재생/일시정지, 좌우=다음 소리, 위/아래=모드 전환
    @ViewBuilder
    private func homePage() -> some View {
        let timerActive = timerManager.textTimer != nil && timerManager.remainingSeconds > 0
        VStack(spacing: 0) {
            Spacer()

            // 위로 굴리면 타이머 (탭으로도 열림) — 뉴비에게만 안내
            if showModeHints {
                modeHint(icon: "chevron.up", title: L.A11y.timerButton.localized, active: timerActive) {
                    goTo(2)
                }
                .padding(.bottom, DS.Spacing.lg)
                .transition(.opacity)
            }

            // 메인 오브
            VStack(spacing: DS.Spacing.md) {
                ZStack {
                    // 길게 누르기(즐겨찾기) 판정 기준점 — 달의 '정지 위치'.
                    // 달에 직접 붙이면 부유 오프셋까지 따라가서 판정이 어긋난다.
                    Color.clear
                        .frame(width: 240, height: 240)
                        .onGeometryChange(for: CGPoint.self) { proxy in
                            let f = proxy.frame(in: .global)
                            return CGPoint(x: f.midX, y: f.midY)
                        } action: { orbCenter = $0 }
                        .allowsHitTesting(false)

                    CampfireView(isPlaying: viewModel.isPlaying,
                                 tint: orbTint,
                                 roll: orbCommitted + orbDragAngle + orbAppearRoll,
                                 rollY: orbCommittedV + orbDragV + orbAppearRollY,
                                 satelliteVisible: satelliteVisible,
                                 satelliteStart: satelliteStartTime,
                                 satelliteStartAngle: satelliteStartAngle,
                                 satelliteHue: satelliteHue,
                                 satelliteScale: satelliteScale,
                                 sway: CGSize(width: swayX, height: swayY))
                    .scaleEffect(orbPressed ? 0.97 : 1.0)
                    .scaleEffect(orbTapPress ? 0.92 : 1.0)              // 탭 시 옴폭
                    // 가장 가까운 레이어 — 내가 흔들리는 만큼 그대로 반대로 밀린다
                    .offset(x: swayX * Self.floatRangeX,
                            y: swayY * Self.floatRangeY)
                    .rotationEffect(.degrees(swayRoll))
                    .offset(x: orbAppearOffsetX, y: orbAppearOffsetY)   // 등장 시 기울어진 방향에서 굴러옴
                    .opacity(orbEntranceReady ? 1 : 0)                  // 시작 위치 잡기 전 숨김
                    .animation(.easeInOut(duration: 0.6), value: orbTint)
                    .accessibilityElement()
                    .accessibilityLabel(viewModel.isPlaying ? L.A11y.pause.localized : L.A11y.play.localized)
                    .accessibilityValue(currentSoundTitle)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(named: Text(L.A11y.nextSound.localized)) { nextSound() }
                    .accessibilityAction(named: Text(L.A11y.favorite.localized)) { toggleFavoriteCurrent() }
                    .accessibilityAction(named: Text(L.A11y.timerButton.localized)) { goTo(2) }
                    .accessibilityAction(named: Text(L.A11y.savedSoundsButton.localized)) { goTo(0) }

                    // 달을 지그시 누르면 떠오르는 하트 팝 (즐겨찾기에 담았을 때)
                    if heartBurst {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color(hue: 0.92, saturation: 0.55, brightness: 0.90).opacity(0.9))
                            .shadow(color: Color(hue: 0.92, saturation: 0.60, brightness: 0.85).opacity(0.6), radius: 14)
                            .offset(y: -26)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }

                Text(nameLabelText)
                    .font(DS.Font.callout())
                    .foregroundColor(DS.Colors.textSecondary)
                    .lineLimit(1)
                    .opacity(showNameLabel ? 1 : 0)
                    .frame(height: 22)
                    .accessibilityHidden(true)
            }

            // 아래로 굴리면 보관함 — 뉴비에게만 안내
            if showModeHints {
                modeHint(icon: "chevron.down", title: L.A11y.savedSoundsButton.localized, active: false) {
                    goTo(0)
                }
                .padding(.top, DS.Spacing.lg)
                .transition(.opacity)
            }

            Spacer()
        }
        .dsConstrainedWidth()
        // 스와이프 영역을 화면 전체로 — 빈 곳에서도 탭/좌우/상하 제스처가 동작한다.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(orbGesture())
        .allowsHitTesting(page == 1)
    }

    /// 위/아래 굴림 안내 + 탭 단축 (작은 글래스 칩)
    @ViewBuilder
    private func modeHint(icon: String, title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(DS.Font.caption().weight(.medium))
            }
            .foregroundColor(active ? DS.Colors.accent : DS.Colors.textSecondary.opacity(0.7))
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                Capsule().fill(DS.Colors.surfaceSunken.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    /// page 0 — 보관함 (위에서 내려옴). 자체 커스텀 헤더(닫기+제목+추가) 사용.
    @ViewBuilder
    private func libraryPage() -> some View {
        SavedSoundsListView(onClose: { goTo(1) })
            .allowsHitTesting(page == 0)
    }

    /// page 2 — 타이머/알람 (아래에서 올라옴). 세그먼트로 [수면타이머 | 알람] 구분.
    @ViewBuilder
    private func timerPage() -> some View {
        TimerAlarmPagerView(timerManager: timerManager,
                            isShowingTimer: Binding(get: { page == 2 },
                                                    set: { if !$0 { goTo(1) } }),
                            onClose: { goTo(1) })
            .allowsHitTesting(page == 2)
    }

    /// 페이지 상단 커스텀 바 (중첩 NavigationStack 없이 닫기 chevron + 제목)
    @ViewBuilder
    private func pageTopBar(icon: String, title: String, onClose: @escaping () -> Void) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Button(action: onClose) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.Common.close.localized)

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // 좌우 균형용 더미 (제목 가운데 정렬)
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Orb Gesture (탭 / 좌우 소리 전환 / 상하 모드 전환)
    private func orbGesture() -> some Gesture {
        // global 좌표: 달 길게 누르기(즐겨찾기)의 위치 판정에 사용 (translation 로직은 영향 없음)
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                // 터치 다운: 달 위라면 길게 누르기(즐겨찾기) 타이머 예약
                if !touchActive {
                    touchActive = true
                    longPressFired = false
                    let loc = value.location
                    if orbCenter != .zero, hypot(loc.x - orbCenter.x, loc.y - orbCenter.y) < 150 {
                        let work = DispatchWorkItem {
                            // 1초간 누른 채 안 움직였으면 즐겨찾기 토글
                            guard vLock == nil else { return }
                            longPressFired = true
                            favoriteLongPress()
                        }
                        longPressWork = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
                    }
                }
                let adx = abs(value.translation.width)
                let ady = abs(value.translation.height)
                if vLock == nil, max(adx, ady) > 10 {
                    vLock = ady > adx   // 처음 의미있게 움직인 축으로 고정
                    longPressWork?.cancel()   // 움직이기 시작 → 길게 누르기 취소
                }
                if vLock == true {
                    // 세로: 구체만 손가락 따라 굴림 (화면은 그대로 — 다 구른 뒤 전환)
                    orbDragV = max(-170, min(170, Double(value.translation.height) * 0.5))
                } else if vLock == false {
                    orbPressed = true
                    orbDragAngle = max(-85, min(85, Double(value.translation.width) * 0.55))
                }
            }
            .onEnded { value in
                longPressWork?.cancel()
                longPressWork = nil
                touchActive = false
                // 길게 눌러 즐겨찾기가 이미 발동됐으면 탭/드래그 처리는 건너뛴다
                if longPressFired {
                    longPressFired = false
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        orbDragAngle = 0
                        orbPressed = false
                    }
                    vLock = nil
                    return
                }
                let dx = value.translation.width
                let dy = value.translation.height
                if vLock == true {
                    // 세로 굴림 → 모드 전환 (구체가 그 방향으로 굴러가며 전환)
                    let predicted = value.predictedEndTranslation.height
                    let decisive = abs(dy) > abs(predicted) ? dy : predicted
                    if decisive < -40 { goTo(2) }        // 위로 → 타이머
                    else if decisive > 40 { goTo(0) }    // 아래로 → 보관함
                    else {
                        // 부족하면 도로 제자리 (구체도 원위치)
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            orbDragV = 0
                        }
                    }
                } else if vLock == false {
                    // 가로 굴림 → 다음 소리
                    let predicted = value.predictedEndTranslation.width
                    if abs(dx) > 24 || abs(predicted) > 60 {
                        let dec = abs(dx) > abs(predicted) ? dx : predicted
                        let dir: Double = dec < 0 ? -1 : 1
                        withAnimation(.easeOut(duration: 0.6)) {
                            orbCommitted += dir * 360
                            orbDragAngle = 0
                            orbPressed = false
                        }
                        flashSatellite()   // 달을 돌리면 위성이 나와서 궤도를 돈다
                        nextSound()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            orbDragAngle = 0
                            orbPressed = false
                        }
                    }
                } else {
                    // 거의 안 움직임 → 탭 = 재생/일시정지 (옴폭 눌렸다 나오는 효과)
                    if hypot(dx, dy) < 10 {
                        togglePlay()
                        pressOrb()
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        orbDragAngle = 0
                        orbPressed = false
                    }
                }
                vLock = nil
            }
    }

    /// 페이지 i의 세로 오프셋 (전환은 page 값으로만 — 구체가 다 구른 뒤 슬라이드)
    private func pageOffset(_ i: Int, _ H: CGFloat) -> CGFloat {
        CGFloat(i - page) * H
    }

    /// 모드 전환: ① 구체가 제자리에서 한 바퀴 다 굴러가고 → ② 화면이 슬라이드 전환.
    private func goTo(_ p: Int) {
        let from = page
        guard p != from else { return }
        Haptics.light()
        didUseModeSwitch = true   // 한 번 써봤으면 안내 칩은 다음부터 숨김
        let dir = p > from ? 1.0 : -1.0
        let rollDur = 0.5

        if from == 1 {
            // 홈 출발: 구체가 한 바퀴 굴러가며(가속) → 끝나기 직전 화면이 슬라이드(감속)로
            // 이어받아 멈칫 없이 흐른다.
            withAnimation(.easeIn(duration: rollDur)) {
                orbCommittedV -= 360 * dir   // 손가락 따라 굴러간 상태에서 이어서 한 바퀴
                orbDragV = 0
            }
            // 회전이 거의 끝난 시점(82%)에 슬라이드를 겹쳐 시작 → 이음매 정지 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + rollDur * 0.82) {
                withAnimation(.easeOut(duration: 0.4)) { page = p }
            }
        } else {
            // 홈으로 복귀: 구체가 가려져 안 보이므로 바로 슬라이드 (회전값은 원위치로 정렬)
            withAnimation(.easeInOut(duration: 0.42)) { page = p }
            orbCommittedV -= 360 * dir
            orbDragV = 0
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 64))
                    .foregroundColor(Color(.Text).opacity(0.3))

                VStack(spacing: 8) {
                    Text(L.Listen.noSavedSounds.localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.TitleText))

                    Text(L.Listen.createFirstSound.localized)
                        .font(.system(size: 15))
                        .foregroundColor(Color(.Text).opacity(0.6))
                }

                Button(action: {
                    isShowingCreateModal = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text(L.Listen.newSoundCreate.localized)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color(.PrimaryPurple))
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.DefaultBackground))
    }

    // MARK: - Header View
    @ViewBuilder
    private func headerView() -> some View {
        let timerActive = timerManager.textTimer != nil && timerManager.remainingSeconds > 0
        HStack(spacing: DS.Spacing.sm) {
            Text(L.Tab.listen.localized)
                .font(DS.Font.largeTitle())
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: DS.Spacing.xs)

            // 저장된 사운드 목록 버튼
            CircleIconButton(systemName: "music.note.list") {
                isShowingCreateModal = true
            }
            .accessibilityLabel(L.A11y.savedSoundsButton.localized)

            // 타이머 버튼
            CircleIconButton(systemName: "timer", active: timerActive) {
                isShowingTimer = true
            }
            .accessibilityLabel(L.A11y.timerButton.localized)
            .accessibilityValue(
                timerActive
                ? String(format: L.A11y.timerActiveValue.localized, formatRemainingTime(timerManager.remainingSeconds))
                : ""
            )
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.xs)
        .padding(.bottom, DS.Spacing.md)
    }

    // MARK: - Smart Recommendations View
    @ViewBuilder
    private func smartRecommendationsView() -> some View {
        let recommendations = viewModel.getSmartRecommendations()

        if !recommendations.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                // 헤더
                SectionHeader(title: getRecommendationTitle(), systemIcon: "sparkles")
                    .padding(.horizontal, DS.Spacing.screen)

                // 가로 스크롤 카드
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(recommendations) { sound in
                            RecommendationCard(sound: sound)
                                .onTapGesture {
                                    viewModel.selectedSound = sound
                                    viewModel.play(with: sound)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityHint(L.A11y.playSoundHint.localized)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
    }

    private func getRecommendationTitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12:
            return L.Listen.recommendationMorning.localized
        case 12..<18:
            return L.Listen.recommendationFocus.localized
        case 18..<22:
            return L.Listen.recommendationEvening.localized
        default:
            return L.Listen.recommendationSleep.localized
        }
    }

    // MARK: - Play Button
    /// 메인 버튼: 재생 중이면 멈추고, 아니면 (선택된 소리 또는 마지막 소리를) 재생
    private func togglePlay() {
        Haptics.soft()
        audioSwitchWork?.cancel() // 대기 중인 스와이프 오디오 전환 취소
        if viewModel.isPlaying {
            viewModel.stopSound()
        } else {
            let sound = viewModel.selectedSound ?? viewModel.lastSound
            viewModel.selectedSound = sound
            viewModel.play(with: sound)
        }
    }

    /// 현재(또는 마지막) 소리 제목
    private var currentSoundTitle: String {
        (viewModel.selectedSound ?? viewModel.lastSound).title
    }

    /// 현재(또는 마지막) 소리
    private var currentSound: CustomSound {
        viewModel.selectedSound ?? viewModel.lastSound
    }

    /// 현재 소리의 즐겨찾기 여부 — selectedSound는 복사본이라 원본 목록에서 id로 조회
    private var isCurrentFavorite: Bool {
        viewModel.customSounds.first(where: { $0.id == currentSound.id })?.isFavorite ?? false
    }

    /// 달을 지그시(1초) 누름 — 즐겨찾기 토글 + 담을 때는 달 위로 하트 팝
    private func favoriteLongPress() {
        toggleFavoriteCurrent()
        favoriteTip.invalidate(reason: .actionPerformed)   // 직접 해봤으니 팁은 그만
        // 옴폭 눌리는 촉감 (탭과 같은 시각 피드백)
        pressOrb()
        // 담을 때만 하트 팝 (뺄 때는 라벨만)
        if isCurrentFavorite {
            heartBurstToken += 1
            let token = heartBurstToken
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { heartBurst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if token == heartBurstToken {
                    withAnimation(.easeOut(duration: 0.5)) { heartBurst = false }
                }
            }
        }
    }

    /// 현재 소리를 즐겨찾기에 담거나 뺀다 (달 길게 누르기·접근성 액션에서 호출)
    private func toggleFavoriteCurrent() {
        let sound = currentSound
        Haptics.soft()
        viewModel.toggleFavorite(sound)
        let nowFavorite = viewModel.customSounds.first(where: { $0.id == sound.id })?.isFavorite ?? false
        flashLabel(nowFavorite ? L.Listen.favoriteOn.localized : L.Listen.favoriteOff.localized)
    }

    /// 재생 순환 풀 — '즐겨찾기만 재생'이 켜져 있고 즐겨찾기가 있으면 그것만 돈다
    private var playPool: [CustomSound] {
        if favoritesOnlyPlayback {
            let favorites = viewModel.customSounds.filter { $0.isFavorite }
            if !favorites.isEmpty { return favorites }
        }
        return viewModel.customSounds
    }

    /// 비슷한 채도의 차분한 색 팔레트 (소리/분위기마다 다른 색)
    private static let orbPalette: [Color] = [
        Color(hex: "6F6AD6"), // 라벤더
        Color(hex: "4FA2C4"), // 청록
        Color(hex: "5DAE84"), // 세이지
        Color(hex: "C77BA8"), // 모브 로즈
        Color(hex: "D2A158"), // 머스타드
        Color(hex: "6580C0"), // 슬레이트 블루
        Color(hex: "A579CE"), // 라일락
        Color(hex: "DA8A78")  // 코랄
    ]

    /// 현재 소리에 대응하는 오브 색 (목록 위치 기반 → 곡마다 일관)
    private var orbTint: Color {
        let pool = viewModel.customSounds
        guard !pool.isEmpty,
              let idx = pool.firstIndex(where: { $0.id == viewModel.selectedSound?.id }) else {
            return DS.Colors.accent
        }
        return Self.orbPalette[idx % Self.orbPalette.count]
    }

    /// 다음 배경음으로 전환 (마지막이면 처음으로 순환). 재생 중이 아니면 자동 재생.
    private func nextSound() {
        let pool = playPool
        guard !pool.isEmpty else { return }
        Haptics.selection()
        let idx = pool.firstIndex(where: { $0.id == viewModel.selectedSound?.id }) ?? -1
        let next = pool[(idx + 1) % pool.count]
        // 색/제목은 즉시 갱신(가벼움) — 시각 피드백은 바로
        viewModel.selectedSound = next
        flashLabel(next.title)
        // 오디오 전환은 디바운스: 연속 스와이프 중엔 디코딩하지 않고,
        // 멈춘 뒤(롤 애니메이션이 끝난 시점) 최종 선택된 소리만 한 번 로딩 → 롤이 끊기지 않음
        scheduleAudioSwitch()
    }

    /// 무거운 오디오 로딩(파일 디코딩)을 롤 애니메이션 이후로 미뤄, 스와이프 중 메인 스레드 블록을 방지
    private func scheduleAudioSwitch() {
        audioSwitchWork?.cancel()
        guard viewModel.isPlaying else { return } // 멈춰 있으면 선택만 바꿈
        let work = DispatchWorkItem { [weak viewModel] in
            guard let viewModel, viewModel.isPlaying, let target = viewModel.selectedSound else { return }
            viewModel.play(with: target) // 페이드 인으로 부드럽게
        }
        audioSwitchWork = work
        // 롤(0.6s)이 끝난 뒤 실행 → 디코딩 블록이 정지 상태의 구체에서 일어나 눈에 띄지 않음
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62, execute: work)
    }

    /// 이전 배경음으로 전환 (처음이면 마지막으로 순환). 잠금화면 ⏮ 버튼용.
    private func prevSound() {
        let pool = playPool
        guard !pool.isEmpty else { return }
        let idx = pool.firstIndex(where: { $0.id == viewModel.selectedSound?.id }) ?? 0
        let prev = pool[(idx - 1 + pool.count) % pool.count]
        let wasPlaying = viewModel.isPlaying
        viewModel.selectedSound = prev
        if wasPlaying {
            viewModel.play(with: prev)
        }
        flashLabel(prev.title)
    }

    // MARK: - Now Playing (잠금화면 / 제어센터)
    /// 리모트 커맨드를 한 번 등록하고 현재 상태를 잠금화면에 반영
    private func setupNowPlaying() {
        let np = NowPlayingManager.shared
        np.setupRemoteCommands()
        np.onPlay = { if !viewModel.isPlaying { togglePlay() } }
        np.onPause = { if viewModel.isPlaying { togglePlay() } }
        np.onToggle = { togglePlay() }
        np.onNext = { nextSound() }
        np.onPrevious = { prevSound() }
        updateNowPlaying()
    }

    /// 현재 곡 제목/재생 상태/색을 잠금화면 정보에 반영
    private func updateNowPlaying() {
        NowPlayingManager.shared.update(
            title: currentSoundTitle,
            isPlaying: viewModel.isPlaying,
            tint: UIColor(orbTint)
        )
    }

    /// 달을 돌릴 때 위성을 등장시키고, 아주 천천히 한 바퀴(약 26분) 돈 뒤 사라지게.
    /// 등장 위치(좌/우 뒤)·크기는 매번 랜덤, 공전 속도(1560초)만 고정. 색은 달 색과 유사하게.
    private func flashSatellite(duration: Double = 1560) {   // 1560초 ≈ 26분
        satelliteStartTime = Date().timeIntervalSinceReferenceDate
        // 좌/우 중 랜덤 + 약간의 흔들림 → 항상 달 뒤(가려진 위치)에서 시작
        let side: Double = Bool.random() ? 1 : -1
        satelliteStartAngle = side * (0.62 + Double.random(in: -0.2...0.2))
        // 달 색(orbTint)의 색상(hue) 근처로만 변주 → 보색 대비를 피해 눈에 덜 띄게
        var moonHue: CGFloat = 0.7
        UIColor(orbTint).getHue(&moonHue, saturation: nil, brightness: nil, alpha: nil)
        var hue = Double(moonHue) + Double.random(in: -0.05...0.05)   // 유사색(analogous) 범위
        hue = hue.truncatingRemainder(dividingBy: 1.0)
        if hue < 0 { hue += 1 }
        satelliteHue = hue
        satelliteScale = Double.random(in: 0.75...1.3)        // 크기 배리에이션
        withAnimation(.easeInOut(duration: 1.2)) { satelliteVisible = true }   // 달 뒤에서 서서히 등장
        satelliteToken += 1
        let token = satelliteToken
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if token == satelliteToken {
                withAnimation(.easeIn(duration: 1.5)) { satelliteVisible = false }  // 천천히 사라짐
            }
        }
    }

    /// 라벨(소리 이름/힌트)을 잠깐 보여주고 사라지게
    private func flashLabel(_ text: String, duration: Double = 1.8) {
        nameLabelText = text
        nameToken += 1
        let token = nameToken
        withAnimation(.easeInOut(duration: 0.35)) { showNameLabel = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if token == nameToken {
                withAnimation(.easeInOut(duration: 0.5)) { showNameLabel = false }
            }
        }
    }

    // MARK: - Mini Player View
    @ViewBuilder
    private func miniPlayerView() -> some View {
        HStack(spacing: 16) {
            // 정보 영역(앨범 아트 + 제목/카테고리)을 하나의 접근성 요소로 묶어
            // "전체 플레이어 열기" 버튼으로 노출
            HStack(spacing: DS.Spacing.md) {
                // 앨범 아트 (부드러운 오브) - 장식용
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.accent.opacity(0.85), DS.Colors.accent.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: viewModel.isPlaying ? "waveform" : "moon.stars.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true) // 장식용 아이콘

                // 사운드 정보
                VStack(alignment: .leading, spacing: 3) {
                    if let sound = viewModel.selectedSound {
                        Text(sound.title)
                            .font(DS.Font.headline())
                            .foregroundColor(DS.Colors.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: DS.Spacing.xs) {
                            Text(sound.category.displayName)
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.textSecondary)

                            // 타이머 활성화 시 남은 시간 표시
                            if timerManager.textTimer != nil && timerManager.remainingSeconds > 0 {
                                Text("•")
                                    .font(DS.Font.caption())
                                    .foregroundColor(DS.Colors.textTertiary)

                                HStack(spacing: 3) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 10))
                                    Text(formatRemainingTime(timerManager.remainingSeconds))
                                        .font(DS.Font.caption().weight(.medium))
                                }
                                .foregroundColor(DS.Colors.accent)
                            }
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingSheet = true
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(L.A11y.openFullPlayerHint.localized)

            // 재생/일시정지 버튼 (독립된 버튼 - 전체 플레이어 열지 않음)
            Button(action: {
                if viewModel.isPlaying {
                    viewModel.stopSound()
                } else {
                    if let sound = viewModel.selectedSound {
                        viewModel.play(with: sound)
                    }
                }
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(DS.Colors.accent))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(viewModel.isPlaying ? L.A11y.pause.localized : L.A11y.play.localized)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Colors.surface)
                .shadow(color: DS.Shadow.floating.color, radius: DS.Shadow.floating.radius, x: 0, y: DS.Shadow.floating.y)
        )
        .padding(.horizontal, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.lg)
        .navigationDestination(isPresented: $isShowingSheet) {
            SoundPlayerFullModalView()
        }
    }

    // MARK: - Helper Functions
    private func formatRemainingTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Empty Player View
    @ViewBuilder
    private func emptyPlayerView() -> some View {
        Button {
            isShowingCreateModal = true
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
                    .accessibilityHidden(true)

                Text(L.Listen.selectSoundToPlay.localized)
                    .font(DS.Font.callout())
                    .foregroundColor(DS.Colors.textSecondary)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Colors.surface)
                    .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: 0, y: DS.Shadow.card.y)
            )
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Campfire View

/// 구 표면(질감 점 + 아이콘)만 따로 그리는 뷰.
/// Animatable 채택 → SwiftUI가 offset/opacity 최종값이 아니라 "회전각(roll) 자체"를
/// 보간하고 매 프레임 sin/cos를 다시 계산한다. (안 그러면 roll 0→-360 시 시작·끝 위치가
/// 같아서 "변화 없음"으로 처리되어 아이콘이 안 굴러간다.)
struct ListenListView_Previews: PreviewProvider {
    static var previews: some View {
        ListenListView()
    }
}

// MARK: - Saved Sounds List View
