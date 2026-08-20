//
//  IdleDimming.swift
//  Dalbit
//
//  자동 화면 어둡게 — 앱을 잠시 만지지 않으면 화면이 서서히 어두워지고,
//  아무 조작이나 하면 부드럽게 밝아진다. (수면 중 눈부심 방지)
//
//  · 터치 감지는 UIKit 제스처 인식기를 window에 얹어서 한다. 인식기는 touchesBegan에서
//    곧바로 .failed로 떨어지기 때문에 기존 SwiftUI 제스처(달 굴리기/길게 누르기 등)를
//    전혀 방해하지 않고 "터치가 있었다"는 사실만 관찰한다.
//  · 깊게 어두워진 상태에서의 첫 터치는 깨우기만 하고 아래 UI로 전달되지 않는다.
//    (자다 깨서 화면을 만졌을 때 재생/일시정지가 잘못 눌리는 걸 막는다)
//  · 설정 > 화면 에서 끌 수 있다. (@AppStorage "idleDimmingEnabled")
//

import SwiftUI
import UIKit

// MARK: - Controller

@MainActor
final class IdleDimController: ObservableObject {

    /// 현재 어둡기 (0 = 평소, maxDim = 가장 어두움)
    @Published private(set) var dim: Double = 0

    /// 이 값을 넘으면 "깊게 어두워진" 상태로 보고 첫 터치를 삼킨다.
    static let wakeAbsorbThreshold: Double = 0.35

    /// 마지막 조작 후 어두워지기 시작할 때까지의 시간
    private let idleDelay: TimeInterval = 45
    /// 어두워지는 데 걸리는 시간 (아주 천천히)
    private let dimDuration: TimeInterval = 8
    /// 최대 어둡기 — 완전 검정이 아니라 달이 희미하게 비치는 정도
    private let maxDim: Double = 0.92

    private var lastInteraction = Date()
    private var ticker: Timer?
    private var isDimming = false
    /// 설정에서 꺼두면 아무 것도 하지 않는다.
    private var enabled = true

    var isDeeplyDimmed: Bool { dim >= Self.wakeAbsorbThreshold }

    // MARK: 수명 주기

    func setEnabled(_ newValue: Bool) {
        guard enabled != newValue else { return }
        enabled = newValue
        if newValue {
            start()
        } else {
            stop()
            wake()
        }
    }

    func start() {
        guard enabled, ticker == nil else { return }
        lastInteraction = Date()
        // 1초에 한 번만 확인 — 실제 페이드는 단발성 애니메이션이 처리한다.
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
    }

    // MARK: 동작

    /// 어떤 조작이든 있었음 — 밝기를 되돌리고 유휴 시계를 리셋한다.
    func noteInteraction() {
        lastInteraction = Date()
        guard enabled else { return }
        if isDimming || dim > 0 { wake() }
    }

    private func tick() {
        guard enabled, !isDimming, dim == 0 else { return }
        guard Date().timeIntervalSince(lastInteraction) >= idleDelay else { return }
        isDimming = true
        withAnimation(.easeInOut(duration: dimDuration)) { dim = maxDim }
    }

    private func wake() {
        isDimming = false
        withAnimation(.easeOut(duration: 0.35)) { dim = 0 }
    }
}

// MARK: - 터치 관찰 (window 레벨)

/// 아무 것도 인식하지 않고 터치 발생만 알려주는 제스처 인식기.
/// touchesBegan에서 즉시 .failed가 되므로 다른 제스처를 가로채지 않는다.
private final class PassiveTouchRecognizer: UIGestureRecognizer {
    var onTouch: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouch?()
        state = .failed
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouch?()
        state = .failed
    }
}

private struct IdleTouchObserver: UIViewRepresentable {
    let onTouch: () -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.isUserInteractionEnabled = false   // 자기 자신은 터치를 받지 않는다
        view.onTouch = onTouch
        return view
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        uiView.onTouch = onTouch
    }

    final class ObserverView: UIView {
        var onTouch: (() -> Void)?
        private var recognizer: PassiveTouchRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard recognizer == nil, let window else { return }
            let gr = PassiveTouchRecognizer(target: nil, action: nil)
            gr.onTouch = { [weak self] in self?.onTouch?() }
            gr.cancelsTouchesInView = false
            gr.delaysTouchesBegan = false
            gr.delaysTouchesEnded = false
            window.addGestureRecognizer(gr)
            recognizer = gr
        }
    }
}

// MARK: - Modifier

private struct IdleDimmingModifier: ViewModifier {
    @AppStorage("idleDimmingEnabled") private var idleDimmingEnabled = true
    @StateObject private var controller = IdleDimController()
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .background(
                IdleTouchObserver { controller.noteInteraction() }
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            )
            .overlay {
                Color.black
                    .opacity(controller.dim)
                    .contentShape(Rectangle())
                    .onTapGesture { controller.noteInteraction() }
                    // 평소엔 터치를 통과시키고, 깊게 어두울 때만 첫 터치를 삼켜 깨우기 전용으로 쓴다.
                    //
                    // 순서가 중요하다. allowsHitTesting 뒤에 contentShape/제스처를 붙이면
                    // 바깥쪽에 터치 영역이 다시 생겨서, 평소에도 이 오버레이가 화면 전체의
                    // 탭을 전부 삼켜 버린다(달이 아예 안 눌림). 반드시 가장 바깥에 둘 것.
                    .allowsHitTesting(controller.isDeeplyDimmed)
                    .ignoresSafeArea()
                    // VoiceOver 사용자에겐 화면을 가리는 요소로 보이면 안 된다.
                    .accessibilityHidden(true)
            }
            .onAppear {
                controller.setEnabled(idleDimmingEnabled)
                controller.start()
            }
            .onDisappear { controller.stop() }
            .onChange(of: idleDimmingEnabled) { _, enabled in
                controller.setEnabled(enabled)
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    controller.noteInteraction()
                    controller.start()
                default:
                    // 백그라운드에서는 타이머를 돌릴 이유가 없다.
                    controller.stop()
                }
            }
    }
}

extension View {
    /// 앱을 잠시 쓰지 않으면 화면이 서서히 어두워지고, 조작하면 다시 밝아진다.
    func idleDimming() -> some View {
        modifier(IdleDimmingModifier())
    }
}
