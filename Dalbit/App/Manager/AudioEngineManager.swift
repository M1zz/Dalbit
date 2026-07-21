//
//  AudioEngineManager.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

import AVFoundation
import Combine
import SwiftUI

final class AudioEngineManager: ObservableObject {
    
    // MARK: - Properties
    static let shared = AudioEngineManager()
    
    var engine = AVAudioEngine()

    // 메인 사운드 (물방울 등)
    private var player = AVAudioPlayerNode()
    private var pitchEffect = AVAudioUnitTimePitch()
    private var volumeEffect = AVAudioMixerNode()
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?
    private var scheduleCompletionHandler: (() -> Void)?
    private var intervalCancellable: AnyCancellable?
    private var timerSubscription: Cancellable?
    private var fadeTimer: Timer?
    private var targetVolume: Float = 1.0
    private var stopRequestId: UInt64 = 0
    /// 재생/일시정지 버튼용 마스터 페이드 타이머 (마스터 볼륨 0↔1)
    private var masterFadeTimer: Timer?

    // 다중 레이어 재생용 (새로운 LayerManager 사용)
    private var layerManager: AudioLayerManager?

    // 공간음향 (Spatial Audio)
    private var environmentNode: AVAudioEnvironmentNode?
    @Published var isSpatialAudioEnabled: Bool = true // 공간음향 활성화 여부

    // 배경음 (wave, rain, tv 등)
    private var backgroundPlayer = AVAudioPlayerNode()
    private var backgroundVolumeEffect = AVAudioMixerNode()
    private var backgroundAudioFile: AVAudioFile?
    private var backgroundBuffer: AVAudioPCMBuffer?
    @Published var backgroundVolume: Float = 0.3 {
        didSet {
            backgroundVolumeEffect.outputVolume = backgroundVolume
        }
    }
    @Published var currentBackgroundSound: BackgroundSound?

    @Published private var currentPlayingSound: Playable?
    @Published var interval: Double = 1.0

    /// 전역 효과음(레이어 사운드) 끄기 — 켜면 배경음악만 재생. 보관함 토글로 제어.
    @Published var effectsMuted: Bool = UserDefaults.standard.bool(forKey: "effectsMuted") {
        didSet {
            guard oldValue != effectsMuted else { return }
            UserDefaults.standard.set(effectsMuted, forKey: "effectsMuted")
            // 재생 중이면 현재 사운드를 다시 평가해 효과음 유무를 즉시 반영
            if let sound = currentPlayingSound {
                play(with: sound)
            }
        }
    }

    // 실제 재생 이벤트를 알리기 위한 Publisher
    let soundDidPlay = PassthroughSubject<(volume: Float, pitch: Float), Never>()

    // 레이어 재생 이벤트 Publisher (filter 정보 포함, 단일/다중 레이어 모두 지원)
    let layerSoundDidPlay = PassthroughSubject<(filter: AudioFilter, volume: Float, pitch: Float), Never>()

    // 실시간 출력 음량(0~1) — 메인 믹서에 탭을 걸어 RMS로 계산. 시각화 동기화용.
    @Published var outputLevel: Float = 0
    private var meteringInstalled = false

    /// 메인 믹서에 탭을 설치해 실시간 음량 측정 시작 (시각화가 켜질 때만 호출)
    func startMetering() {
        guard !meteringInstalled else { return }
        let node = engine.mainMixerNode
        let format = node.outputFormat(forBus: 0)
        guard format.channelCount > 0 else { return }

        node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self, let channelData = buffer.floatChannelData else { return }
            let frames = Int(buffer.frameLength)
            guard frames > 0 else { return }
            let channels = Int(buffer.format.channelCount)

            var sumSquares: Float = 0
            for ch in 0..<channels {
                let samples = channelData[ch]
                for i in 0..<frames {
                    let s = samples[i]
                    sumSquares += s * s
                }
            }
            let rms = sqrt(sumSquares / Float(frames * max(1, channels)))
            // 정규화(작은 RMS를 보기 좋게 증폭) + 살짝 스무딩
            let level = min(1.0, rms * 6.0)
            DispatchQueue.main.async {
                self.outputLevel = self.outputLevel * 0.6 + level * 0.4
            }
        }
        meteringInstalled = true
    }

    /// 탭 제거 및 음량 0으로 리셋
    func stopMetering() {
        guard meteringInstalled else { return }
        engine.mainMixerNode.removeTap(onBus: 0)
        meteringInstalled = false
        DispatchQueue.main.async { self.outputLevel = 0 }
    }

    @Published var pitch: Double = 0 {
        didSet {
            pitchEffect.pitch = Float(pitch * 100)
        }
    }
    
    @Published var volume: Float = 1.0 {
        didSet {
            volumeEffect.outputVolume = volume
        }
    }
    
    @Published var audioVariation: AudioVariation = AudioVariation() {
        didSet {
            self.pitchEffect.pitch = Float(audioVariation.pitch * 100)
            self.volumeEffect.outputVolume = audioVariation.volume
            self.interval = Double(audioVariation.interval)
        }
    }

    /// 랜덤 값을 적용한 실제 간격 계산
    private func getRandomizedInterval() -> Double {
        let baseInterval = Double(audioVariation.interval)
        let variation = Double(audioVariation.intervalVariation)

        if variation > 0 {
            // 변동폭만큼 랜덤하게 조정 (예: 30% 변동 = ±30%)
            let randomFactor = Double.random(in: -variation...variation)
            let randomizedInterval = baseInterval * (1.0 + randomFactor)
            return max(0.1, randomizedInterval) // 최소 0.1초
        }

        return baseInterval
    }

    /// 랜덤 값을 적용한 실제 볼륨 계산
    private func getRandomizedVolume() -> Float {
        let baseVolume = audioVariation.volume
        let variation = audioVariation.volumeVariation

        if variation > 0 {
            // 변동폭만큼 랜덤하게 조정
            let randomFactor = Float.random(in: -variation...variation)
            let randomizedVolume = baseVolume * (1.0 + randomFactor)
            return max(0.1, min(1.0, randomizedVolume)) // 0.1 ~ 1.0 범위
        }

        return baseVolume
    }

    /// 랜덤 값을 적용한 실제 피치 계산
    private func getRandomizedPitch() -> Float {
        let basePitch = audioVariation.pitch
        let variation = audioVariation.pitchVariation

        if variation > 0 {
            // 변동폭만큼 랜덤하게 조정 (피치는 -24 ~ +24 semitones 범위)
            let randomFactor = Float.random(in: -variation...variation)
            let randomizedPitch = basePitch + (randomFactor * 24.0) // 최대 ±24 semitones 변동
            return max(-24.0, min(24.0, randomizedPitch)) // -24 ~ +24 범위
        }

        return basePitch
    }
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
        setupEngine()
        setupSpatialAudio()
        setupSubscriptions()
        setupNotifications()

        // LayerManager 초기화
        layerManager = AudioLayerManager(
            engine: engine,
            environmentNode: environmentNode,
            isSpatialAudioEnabled: isSpatialAudioEnabled
        )

        // 레이어 재생 이벤트를 AudioEngineManager의 Publisher로 전달
        layerManager?.onLayerPlay = { [weak self] filter, volume, pitch in
            self?.layerSoundDidPlay.send((filter: filter, volume: volume, pitch: pitch))
        }
    }
}

// MARK: - Setup
extension AudioEngineManager {
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
        }
    }

    /// 엔진 구성 변경·오디오 인터럽션 알림 등록
    /// - 백그라운드 전환·화면잠금·오디오 라우트 변경 시 하드웨어 포맷이 바뀌면
    ///   AVAudioEngine이 구성 변경 알림을 발행하며 그래프가 깨진다(→ 크래클/지지직).
    ///   이를 감지해 세션 재활성화·엔진 재시작·버퍼 재스케줄로 복구한다.
    private func setupNotifications() {
        let center = NotificationCenter.default

        center.addObserver(
            self,
            selector: #selector(handleEngineConfigurationChange(_:)),
            name: .AVAudioEngineConfigurationChange,
            object: engine
        )

        center.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    /// 엔진 구성 변경 처리 — 그래프를 복구하고 재생 중이던 사운드를 이어서 재생한다.
    @objc private func handleEngineConfigurationChange(_ notification: Notification) {
        // 알림은 오디오 스레드에서 올 수 있으므로 메인에서 안전하게 복구한다.
        DispatchQueue.main.async { [weak self] in
            self?.recoverAudioGraph()
        }
    }

    /// 오디오 인터럽션(전화·타 앱 재생 등) 처리
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // 인터럽션 시작: 시스템이 세션을 비활성화한다. 플레이어를 잠시 멈춘다.
            player.pause()
            backgroundPlayer.pause()
        case .ended:
            // 인터럽션 종료: 시스템이 재개를 허용하면 세션을 재활성화하고 이어서 재생.
            let options = (info[AVAudioSessionInterruptionOptionKey] as? UInt).map {
                AVAudioSession.InterruptionOptions(rawValue: $0)
            }
            if options?.contains(.shouldResume) == true {
                DispatchQueue.main.async { [weak self] in
                    self?.recoverAudioGraph()
                }
            }
        @unknown default:
            break
        }
    }

    /// 오디오 그래프 복구: 세션 재활성화 → 엔진 재시작 → 배경음·레이어 버퍼 재스케줄 후 재생.
    /// 엔진이 정지하면 플레이어에 예약된 버퍼가 사라지므로 반드시 다시 스케줄해야 한다.
    private func recoverAudioGraph() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ [AudioEngineManager] 세션 재활성화 실패: \(error.localizedDescription)")
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("⚠️ [AudioEngineManager] 구성 변경 후 엔진 재시작 실패: \(error.localizedDescription)")
                return
            }
        }

        // 배경음이 재생 중이었다면 루프 버퍼를 다시 스케줄하고 재생 재개
        if currentBackgroundSound != nil, backgroundBuffer != nil {
            scheduleBackgroundLoop()
            if !backgroundPlayer.isPlaying {
                backgroundPlayer.play()
            }
        }

        // 레이어 사운드 재개
        layerManager?.rescheduleActiveLayers()

        print("✅ [AudioEngineManager] 오디오 그래프 복구 완료")
    }

    private func setupEngine() {
        engine.attach(player)
        engine.attach(pitchEffect)
        engine.attach(volumeEffect)
    }

    /// 공간음향 환경 설정
    private func setupSpatialAudio() {
        let environment = AVAudioEnvironmentNode()

        // 엔진에 환경 노드 추가
        engine.attach(environment)

        // HRTF (Head-Related Transfer Function) 알고리즘 사용
        // 이는 헤드폰에서 최적화된 3D 오디오를 제공합니다
        environment.renderingAlgorithm = .HRTFHQ

        // 리스너(청자) 위치를 중앙으로 설정
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)

        // 거리 감쇠 파라미터 설정 (거리감 조절)
        let distanceParams = environment.distanceAttenuationParameters
        distanceParams.distanceAttenuationModel = .inverse // 역제곱 감쇠 모델
        distanceParams.referenceDistance = 1.0 // 기준 거리 (1미터)
        distanceParams.maximumDistance = 10.0 // 최대 거리 (10미터)
        distanceParams.rolloffFactor = 1.0 // 감쇠 계수 (1.0 = 자연스러운 감쇠)

        // 환경 노드를 메인 믹서에 연결
        engine.connect(environment, to: engine.mainMixerNode, format: nil)

        environmentNode = environment

        print("🎧 [SpatialAudio] 공간음향 환경 초기화 완료")
        print("   - Rendering Algorithm: HRTF HQ")
        print("   - Listener Position: (0, 0, 0)")
        print("   - Distance Model: Inverse")
        print("   - Reference Distance: 1.0m")
        print("   - Maximum Distance: 10.0m")
    }

    /// 레이어 인덱스에 따라 3D 공간 위치 계산
    /// - Parameters:
    ///   - index: 레이어 인덱스
    ///   - totalLayers: 전체 레이어 수
    /// - Returns: 3D 공간 좌표
    private func calculate3DPosition(for index: Int, totalLayers: Int) -> AVAudio3DPoint {
        // 레이어들을 원형으로 배치 (반지름 2미터)
        let radius: Float = 2.0
        let angle = (2.0 * .pi / Float(totalLayers)) * Float(index)

        // Y축은 귀 높이(0)로 고정, X-Z 평면에서 원형 배치
        let x = radius * cos(angle)
        let z = -radius * sin(angle) // 앞쪽이 음수

        // 거리감을 위해 약간의 깊이 변화 추가
        let depthVariation = Float.random(in: -0.3...0.3)

        return AVAudio3DPoint(x: x, y: 0, z: z + depthVariation)
    }

    /// 특정 레이어의 3D 위치를 업데이트 (LayerManager 사용)
    /// - Parameters:
    ///   - index: 레이어 인덱스
    ///   - distance: 청자로부터의 거리 (미터)
    ///   - angle: 각도 (도, 0-360)
    ///   - height: 높이 (미터, -2 ~ 2)
    func updateLayerPosition(index: Int, distance: Float, angle: Float, height: Float) {
        guard let manager = layerManager else { return }

        let layerIds = manager.getAllLayerIds()
        guard index < layerIds.count else { return }

        // 각도를 라디안으로 변환
        let angleRad = angle * .pi / 180.0

        // 극좌표를 직교좌표로 변환
        let x = distance * cos(angleRad)
        let z = -distance * sin(angleRad) // 앞쪽이 음수

        let newPosition = AVAudio3DPoint(x: x, y: height, z: z)

        // 레이어 위치 업데이트
        let layerId = layerIds[index]
        manager.setLayerPosition(layerId, position: newPosition)

        print("🎧 [SpatialAudio] 레이어 \(index) 위치 업데이트:")
        print("   - 거리: \(distance)m, 각도: \(angle)°, 높이: \(height)m")
        print("   - 좌표: (\(x), \(height), \(z))")
    }

    /// 모든 레이어의 현재 위치 정보 가져오기 (LayerManager 사용)
    func getLayerPositions() -> [(index: Int, position: AVAudio3DPoint)] {
        guard let manager = layerManager else { return [] }

        let layerIds = manager.getAllLayerIds()
        return layerIds.enumerated().compactMap { (index, layerId) in
            guard let position = manager.getLayerPosition(layerId) else { return nil }
            return (index, position)
        }
    }

    /// 레이어 제거 (외부에서 호출 가능)
    func removeLayer(at index: Int) {
        guard let manager = layerManager else { return }

        let layerIds = manager.getAllLayerIds()
        guard index < layerIds.count else { return }

        let layerId = layerIds[index]
        manager.removeLayer(layerId)

        print("🗑️ [AudioEngineManager] 레이어 \(index) 제거 완료")
    }

    /// 현재 레이어 개수 가져오기
    func getLayerCount() -> Int {
        return layerManager?.getAllLayerIds().count ?? 0
    }

    private func setupConnections() {
        print("🔗 [AudioEngineManager] setupConnections() 호출됨")
        print("   - Engine 실행 중: \(engine.isRunning)")
        print("   - 배경음 재생 중: \(currentBackgroundSound?.rawValue ?? "없음")")

        guard let audioFile = audioFile else {
            print("   ❌ audioFile이 없음")
            return
        }

        // 노드가 attach되어 있는지 확인
        let isPlayerAttached = engine.attachedNodes.contains(player)
        let isPitchAttached = engine.attachedNodes.contains(pitchEffect)
        let isVolumeAttached = engine.attachedNodes.contains(volumeEffect)

        // 노드가 attach되지 않았으면 attach
        if !isPlayerAttached {
            engine.attach(player)
        }
        if !isPitchAttached {
            engine.attach(pitchEffect)
        }
        if !isVolumeAttached {
            engine.attach(volumeEffect)
        }

        // 엔진이 실행 중이면 중지해야 연결을 안전하게 변경할 수 있음
        if engine.isRunning {
            print("   - Engine 중지 후 재연결")
            engine.stop()
        }

        // 기존 연결 모두 해제 (안전하게)
        if isPlayerAttached {
            engine.disconnectNodeOutput(player)
            engine.disconnectNodeInput(player)
        }
        if isPitchAttached {
            engine.disconnectNodeOutput(pitchEffect)
            engine.disconnectNodeInput(pitchEffect)
        }
        if isVolumeAttached {
            engine.disconnectNodeOutput(volumeEffect)
            engine.disconnectNodeInput(volumeEffect)
        }

        // 새로운 연결 설정
        let format = audioFile.processingFormat
        engine.connect(player, to: pitchEffect, format: format)
        engine.connect(pitchEffect, to: volumeEffect, format: format)
        engine.connect(volumeEffect, to: engine.mainMixerNode, format: format)
        print("   ✅ 메인 사운드 노드 연결 완료")

        // 엔진 시작
        if !engine.isRunning {
            do {
                try engine.start()
                print("   ✅ Engine 시작 완료")
            } catch {
                print("   ❌ Engine 시작 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     오디오 재생 간격이 변경되었을 때 이를 감지하여 새 버퍼를 스케줄링하는 구독을 설정합니다.
     Combine을 이용하여 'interval' 프로퍼티의 값이 변동되면 300 밀리초 후에 scheduleNextBuffer 함수를 호출합니다.
     */
    private func setupSubscriptions() {
        intervalCancellable = $interval
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.timerSubscription?.cancel()
                self?.scheduleNextBuffer(immediate: false)
            }
    }
    
}

// MARK: - Play & Pause
extension AudioEngineManager {

    func play<T: Playable>(with sound: T) {
        print("🎵 [AudioEngineManager] play() 호출됨")
        print("   - 재생할 사운드: \(sound.filter.rawValue)")
        print("   - 현재 배경음 재생 중: \(currentBackgroundSound?.rawValue ?? "없음")")

        // 기존 재생 정리 (엔진은 중지하지 않고 노드만 정리)
        fadeTimer?.invalidate()
        fadeTimer = nil
        masterFadeTimer?.invalidate()
        masterFadeTimer = nil
        timerSubscription?.cancel()
        player.stop()
        stopLayers()
        backgroundPlayer.stop()
        currentBackgroundSound = nil
        clearBuffer()

        // 페이드 인을 위해 마스터 볼륨을 0에서 시작
        engine.mainMixerNode.outputVolume = 0

        currentPlayingSound = sound

        // 전역 효과음 끄기: 효과음 레이어는 건너뛰고 배경음악만 재생
        if effectsMuted {
            if let customSound = sound as? CustomSound,
               let backgroundSoundName = customSound.backgroundSound,
               let backgroundSound = BackgroundSound.from(backgroundSoundName) {
                if let savedBackgroundVolume = customSound.backgroundVolume {
                    self.backgroundVolume = savedBackgroundVolume
                }
                audioVariation = customSound.audioVariation
                playBackground(backgroundSound)
                masterFadeIn()
            } else {
                // 배경음악이 없는 사운드는 효과음이 꺼지면 무음 (마스터 볼륨 복원)
                engine.mainMixerNode.outputVolume = 1.0
                print("🔇 [AudioEngineManager] 효과음 꺼짐 · 배경음악 없음 → 무음")
            }
            return
        }

        // CustomSound이면서 레이어 방식인 경우
        if let customSound = sound as? CustomSound, customSound.isLayeredSound {
            playLayeredSound(customSound)
            masterFadeIn()
            return
        }

        // 효과음 없이 배경음만 있는 경우 (스튜디오에서 배경음만 선택) → 배경음만 재생
        if let customSound = sound as? CustomSound,
           customSound.filter == .none,
           let backgroundSoundName = customSound.backgroundSound,
           let backgroundSound = BackgroundSound.from(backgroundSoundName) {
            if let savedBackgroundVolume = customSound.backgroundVolume {
                self.backgroundVolume = savedBackgroundVolume
            }
            audioVariation = customSound.audioVariation
            playBackground(backgroundSound)
            masterFadeIn()
            return
        }

        // 일반 사운드 재생 (기존 로직)
        let targetFile = sound.filter.rawValue
        guard let fileURL = Bundle.main.url(forResource: targetFile, withExtension: MusicExtension.mp3.rawValue) else {
            print("❌ [AudioEngineManager] 파일을 찾을 수 없음: \(targetFile)")
            return
        }

        do {
            audioFile = try AVAudioFile(forReading: fileURL)
            audioBuffer = prepareBuffer()
            setupConnections()

            if let customSound = sound as? CustomSound {
                audioVariation = customSound.audioVariation

                // 배경음이 저장되어 있으면 함께 재생
                if let backgroundSoundName = customSound.backgroundSound,
                   let backgroundSound = BackgroundSound.from(backgroundSoundName) {
                    print("🎵 [AudioEngineManager] 저장된 배경음 재생: \(backgroundSoundName)")

                    // 저장된 배경 볼륨 적용
                    if let savedBackgroundVolume = customSound.backgroundVolume {
                        self.backgroundVolume = savedBackgroundVolume
                        print("   - 배경 볼륨: \(savedBackgroundVolume)")
                    }

                    playBackground(backgroundSound)
                }
            }

            scheduleNextBuffer(with: sound)
            masterFadeIn() // 부드럽게 페이드 인
            print("✅ [AudioEngineManager] 메인 사운드 재생 시작 완료")

        } catch {
            print("❌ [AudioEngineManager] 재생 오류: \(error.localizedDescription)")
            engine.mainMixerNode.outputVolume = 1.0 // 실패 시 볼륨 복원
        }
    }

    /// 여러 레이어를 동시에 재생 (LayerManager 사용)
    private func playLayeredSound(_ sound: CustomSound) {
        print("🎵 [AudioEngineManager] 레이어 사운드 재생")

        guard let layers = sound.soundLayers, !layers.isEmpty else {
            print("❌ [AudioEngineManager] 레이어 정보가 없음")
            return
        }

        guard let manager = layerManager else {
            print("❌ [AudioEngineManager] LayerManager가 초기화되지 않음")
            return
        }

        // 기존 레이어 정리
        stopLayers()

        do {
            // 엔진 시작
            if !engine.isRunning {
                try engine.start()
            }

            var successfulLayers = 0

            // 각 레이어 추가
            for (index, layer) in layers.enumerated() {
                let position = calculate3DPosition(for: index, totalLayers: layers.count)

                do {
                    let layerId = try manager.addLayer(
                        filter: layer.filter,
                        category: layer.category,
                        variation: layer.audioVariation,
                        position: position
                    )

                    successfulLayers += 1
                    print("✅ [AudioEngineManager] 레이어 \(index) 추가: \(layer.filter.rawValue) (ID: \(layerId))")
                } catch {
                    print("❌ [AudioEngineManager] 레이어 \(index) 추가 실패: \(error.localizedDescription)")
                    print("   - 필터: \(layer.filter.rawValue)")
                    print("   - 파일 존재 여부 확인 필요: \(layer.filter.rawValue).mp3")
                }
            }

            // 레이어가 하나도 추가되지 않았으면 단일 사운드로 폴백
            if successfulLayers == 0 {
                print("⚠️ [AudioEngineManager] 레이어 추가 실패, 단일 사운드로 폴백")
                playSingleSoundFallback(sound)
                return
            }

            // 배경음 재생
            if let backgroundSoundName = sound.backgroundSound,
               let backgroundSound = BackgroundSound.from(backgroundSoundName) {
                if let savedBackgroundVolume = sound.backgroundVolume {
                    self.backgroundVolume = savedBackgroundVolume
                }
                playBackground(backgroundSound)
            }

            // 모든 레이어 재생 시작
            manager.startAllLayers()

            print("✅ [AudioEngineManager] 모든 레이어 재생 시작 (성공: \(successfulLayers)/\(layers.count)개)")

        } catch {
            print("❌ [AudioEngineManager] 레이어 재생 오류: \(error.localizedDescription)")
            // 폴백: 단일 사운드로 재생 시도
            playSingleSoundFallback(sound)
        }
    }

    /// 레이어 재생 실패 시 단일 사운드로 폴백
    private func playSingleSoundFallback(_ sound: CustomSound) {
        print("🔄 [AudioEngineManager] 단일 사운드 폴백 재생 시도")

        let targetFile = sound.filter.rawValue
        guard let fileURL = Bundle.main.url(forResource: targetFile, withExtension: MusicExtension.mp3.rawValue) else {
            print("❌ [AudioEngineManager] 폴백 파일도 찾을 수 없음: \(targetFile)")
            return
        }

        do {
            audioFile = try AVAudioFile(forReading: fileURL)
            audioBuffer = prepareBuffer()
            setupConnections()
            audioVariation = sound.audioVariation

            // 배경음 재생
            if let backgroundSoundName = sound.backgroundSound,
               let backgroundSound = BackgroundSound.from(backgroundSoundName) {
                if let savedBackgroundVolume = sound.backgroundVolume {
                    self.backgroundVolume = savedBackgroundVolume
                }
                playBackground(backgroundSound)
            }

            scheduleNextBuffer(with: sound, immediate: true)
            print("✅ [AudioEngineManager] 폴백 단일 사운드 재생 시작")

        } catch {
            print("❌ [AudioEngineManager] 폴백 재생 오류: \(error.localizedDescription)")
        }
    }

    /// 레이어 재생 중지 (LayerManager 사용)
    private func stopLayers() {
        guard let manager = layerManager else { return }

        print("🛑 [AudioEngineManager] 레이어 중지 시작")

        manager.removeAllLayers()

        print("✅ [AudioEngineManager] 모든 레이어 중지 완료")
    }

    /// 버퍼 준비 (AudioFile로부터)
    private func prepareBuffer(from file: AVAudioFile) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            return nil
        }

        try? file.read(into: buffer)
        return buffer
    }

    func stop() {
        print("⏹️ [AudioEngineManager] stop() 호출됨")
        print("   - 배경음 상태: \(currentBackgroundSound?.rawValue ?? "없음")")

        fadeTimer?.invalidate()
        fadeTimer = nil
        masterFadeTimer?.invalidate()
        masterFadeTimer = nil
        timerSubscription?.cancel()

        // 메인 플레이어 즉시 중지
        player.stop()

        // 레이어 중지
        stopLayers()

        // 배경음 중지
        backgroundPlayer.stop()
        currentBackgroundSound = nil

        currentPlayingSound = nil

        // 엔진 중지 (레이스 컨디션 방지: stop 후 바로 play가 호출되면 엔진을 멈추지 않음)
        stopRequestId &+= 1
        let currentRequestId = stopRequestId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            // stop 이후 새로운 play가 호출되지 않았을 때만 엔진 중지
            if self.currentPlayingSound == nil && self.stopRequestId == currentRequestId {
                self.engine.stop()
                print("✅ [AudioEngineManager] 엔진 중지 완료")
            }
        }

        clearBuffer()
    }

    func stopAll() {
        print("⏹️ [AudioEngineManager] stopAll() 호출됨 - 모든 사운드 중지")

        fadeTimer?.invalidate()
        fadeTimer = nil
        timerSubscription?.cancel()
        player.stop()
        backgroundPlayer.stop()

        // 레이어 중지
        stopLayers()

        engine.stop()
        clearBuffer()

        print("✅ [AudioEngineManager] 모든 사운드 중지 완료")
    }

    func stopWithFade(duration: TimeInterval = 5.0, completion: (() -> Void)? = nil) {
        fadeOut(duration: duration) { [weak self] in
            self?.stop()
            completion?()
        }
    }
}

// MARK: - Fade Effects
extension AudioEngineManager {

    /// 페이드 인: 볼륨을 0에서 목표 볼륨까지 서서히 증가
    func fadeIn(duration: TimeInterval = 3.0, targetVolume: Float? = nil) {
        fadeTimer?.invalidate()

        let target = targetVolume ?? audioVariation.volume
        self.targetVolume = target

        // 시작 볼륨을 0으로 설정
        volumeEffect.outputVolume = 0.0

        let steps = 30 // 30단계로 나눔
        let stepDuration = duration / Double(steps)
        let volumeIncrement = target / Float(steps)

        var currentStep = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            currentStep += 1

            if currentStep >= steps {
                self.volumeEffect.outputVolume = target
                timer.invalidate()
                self.fadeTimer = nil
            } else {
                self.volumeEffect.outputVolume = volumeIncrement * Float(currentStep)
            }
        }
    }

    /// 페이드 아웃: 현재 볼륨에서 0까지 서서히 감소
    func fadeOut(duration: TimeInterval = 5.0, completion: (() -> Void)? = nil) {
        fadeTimer?.invalidate()

        let startVolume = volumeEffect.outputVolume
        let steps = 50 // 50단계로 나눔
        let stepDuration = duration / Double(steps)
        let volumeDecrement = startVolume / Float(steps)

        var currentStep = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion?()
                return
            }

            currentStep += 1

            if currentStep >= steps {
                self.volumeEffect.outputVolume = 0.0
                timer.invalidate()
                self.fadeTimer = nil
                completion?()
            } else {
                self.volumeEffect.outputVolume = startVolume - (volumeDecrement * Float(currentStep))
            }
        }
    }

    /// 페이드 효과 취소
    func cancelFade() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        // 원래 볼륨으로 복원
        volumeEffect.outputVolume = targetVolume
    }

    // MARK: - Master Fade (재생/일시정지 버튼용)

    /// 재생 시작 시: 마스터 볼륨을 0 → 1로 부드럽게 (단일·레이어·배경음 모두 포함)
    func masterFadeIn(duration: TimeInterval = 1.2) {
        masterFadeTimer?.invalidate()
        let steps = 30
        let stepDuration = duration / Double(steps)
        let increment = 1.0 / Float(steps)
        engine.mainMixerNode.outputVolume = 0
        var currentStep = 0
        masterFadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            currentStep += 1
            if currentStep >= steps {
                self.engine.mainMixerNode.outputVolume = 1.0
                timer.invalidate()
                self.masterFadeTimer = nil
            } else {
                self.engine.mainMixerNode.outputVolume = increment * Float(currentStep)
            }
        }
    }

    /// 일시정지 시: 마스터 볼륨을 0으로 줄인 뒤 정지하고, 다음 재생을 위해 1로 복원
    func masterFadeOutAndStop(duration: TimeInterval = 1.0) {
        masterFadeTimer?.invalidate()
        let startVolume = engine.mainMixerNode.outputVolume
        guard startVolume > 0 else {
            stop()
            engine.mainMixerNode.outputVolume = 1.0
            return
        }
        let steps = 30
        let stepDuration = duration / Double(steps)
        let decrement = startVolume / Float(steps)
        var currentStep = 0
        masterFadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            currentStep += 1
            if currentStep >= steps {
                timer.invalidate()
                self.masterFadeTimer = nil
                self.stop()
                // 다음 재생을 위해 마스터 볼륨 복원 (play()에서 다시 0으로 시작)
                self.engine.mainMixerNode.outputVolume = 1.0
            } else {
                self.engine.mainMixerNode.outputVolume = startVolume - (decrement * Float(currentStep))
            }
        }
    }
}

// MARK: - Buffer
extension AudioEngineManager {
    
    private func clearBuffer() {
        audioBuffer = nil
    }
    
    private func prepareBuffer() -> AVAudioPCMBuffer? {
        print(#function)
        
        guard let audioFile = audioFile else { return nil }
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                      frameCapacity: AVAudioFrameCount(audioFile.length))!
        do {
            try audioFile.read(into: buffer)
        } catch {
            print("Failed to read buffer")
            return nil
        }
        return buffer
    }
    
    /**
     다음 오디오 버퍼를 스케줄링합니다. 준비된 버퍼를 사용해 오디오를 재생하고, 주어진 인터벌에 따라 다음 버퍼 재생을 스케줄링합니다.
     Combine 프레임워크의 Timer.publish를 사용하여 지정된 인터벌마다 버퍼 재생을 반복합니다.
     - Parameter immediate: true이면 첫 번째 사운드를 즉시 재생
     */
    private func scheduleNextBuffer(with playingSound: Playable? = nil, immediate: Bool = true) {
        print(#function)

        guard let buffer = audioBuffer else {
            print("Failed to prepare buffer")
            return
        }

        guard let sound = playingSound ?? currentPlayingSound else {
            print("No playing sound")
            return
        }

        // 취소 가능한 타이머를 만듭니다.
        timerSubscription?.cancel()

        // 첫 번째 사운드를 즉시 재생
        if immediate {
            playBufferImmediately(buffer: buffer)
        }

        // 랜덤화된 간격 계산
        let randomizedInterval = getRandomizedInterval()

        timerSubscription = Timer.publish(
            every: randomizedInterval + sound.filter.duration,
            on: RunLoop.main,
            in: .common
        )
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.player.pause()

                // 랜덤화된 볼륨 적용
                let randomizedVolume = self.getRandomizedVolume()
                self.volumeEffect.outputVolume = randomizedVolume

                // 랜덤화된 피치 적용
                let randomizedPitch = self.getRandomizedPitch()
                self.pitchEffect.pitch = randomizedPitch * 100 // AVAudioUnitTimePitch는 cents 단위 (100 cents = 1 semitone)

                let scheduleTime = AVAudioTime(hostTime: mach_absolute_time())
                self.player.scheduleBuffer(buffer, at: scheduleTime) { [weak self] in
                    self?.scheduleCompletionHandler?()
                    self?.scheduleCompletionHandler = nil
                }

                if !self.engine.isRunning {
                    do {
                        try self.engine.start()
                    } catch {
                        print("Unable to start engine: \(error.localizedDescription)")
                    }
                }

                if !self.player.isPlaying {
                    self.player.play()
                }

                // 재생 이벤트 발행 (물방울 애니메이션 싱크용)
                self.soundDidPlay.send((volume: randomizedVolume, pitch: randomizedPitch))
                if let filter = sound.filter as AudioFilter? {
                    self.layerSoundDidPlay.send((filter: filter, volume: randomizedVolume, pitch: randomizedPitch))
                }

                // 다음 재생을 위한 새로운 타이머 (랜덤 간격으로 재스케줄)
                self.scheduleNextBuffer(immediate: false)
            }
    }

    /// 버퍼를 즉시 재생
    private func playBufferImmediately(buffer: AVAudioPCMBuffer) {
        // 랜덤화된 볼륨/피치 적용
        let randomizedVolume = getRandomizedVolume()
        let randomizedPitch = getRandomizedPitch()

        volumeEffect.outputVolume = randomizedVolume
        pitchEffect.pitch = randomizedPitch * 100

        let scheduleTime = AVAudioTime(hostTime: mach_absolute_time())
        player.scheduleBuffer(buffer, at: scheduleTime) { [weak self] in
            self?.scheduleCompletionHandler?()
            self?.scheduleCompletionHandler = nil
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Unable to start engine: \(error.localizedDescription)")
            }
        }

        if !player.isPlaying {
            player.play()
        }

        // 재생 이벤트 발행
        soundDidPlay.send((volume: randomizedVolume, pitch: randomizedPitch))
        if let sound = currentPlayingSound {
            layerSoundDidPlay.send((filter: sound.filter, volume: randomizedVolume, pitch: randomizedPitch))
        }
        print("✅ [AudioEngineManager] 첫 사운드 즉시 재생")
    }
}

// MARK: - Background Sound

extension AudioEngineManager {

    /// 배경음 재생
    func playBackground(_ background: BackgroundSound) {
        // subdirectory 없이 파일명으로만 검색 시도
        guard let fileURL = Bundle.main.url(forResource: background.fileName, withExtension: "mp3") else {
            print("⚠️ [AudioEngineManager] 배경음 파일을 찾을 수 없음: \(background.fileName).mp3")
            print("   - 배경음 없이 메인 사운드만 재생됩니다")
            // 배경음 파일이 없어도 currentBackgroundSound는 설정하지 않음
            return
        }

        currentBackgroundSound = background
        print("✅ [AudioEngineManager] 배경음 파일 발견: \(fileURL.path)")

        do {
            backgroundAudioFile = try AVAudioFile(forReading: fileURL)
            backgroundBuffer = prepareBackgroundBuffer()

            if !engine.attachedNodes.contains(backgroundPlayer) {
                engine.attach(backgroundPlayer)
                engine.attach(backgroundVolumeEffect)

                if let audioFile = backgroundAudioFile {
                    engine.connect(backgroundPlayer, to: backgroundVolumeEffect, format: audioFile.processingFormat)
                    engine.connect(backgroundVolumeEffect, to: engine.mainMixerNode, format: audioFile.processingFormat)
                }
            }

            backgroundVolumeEffect.outputVolume = backgroundVolume

            scheduleBackgroundLoop()

            if !engine.isRunning {
                try engine.start()
            }

            if !backgroundPlayer.isPlaying {
                backgroundPlayer.play()
            }

        } catch {
            print("Background play error: \(error.localizedDescription)")
        }
    }

    /// 배경음 중지
    func stopBackground() {
        backgroundPlayer.stop()
        currentBackgroundSound = nil
    }

    /// 배경음 버퍼 준비
    private func prepareBackgroundBuffer() -> AVAudioPCMBuffer? {
        guard let audioFile = backgroundAudioFile else { return nil }

        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                      frameCapacity: AVAudioFrameCount(audioFile.length))!
        do {
            try audioFile.read(into: buffer)
        } catch {
            print("Failed to read background buffer")
            return nil
        }
        return buffer
    }

    /// 배경음 루프 스케줄링 (10분 파일을 계속 반복)
    private func scheduleBackgroundLoop() {
        guard let buffer = backgroundBuffer else { return }

        backgroundPlayer.scheduleBuffer(buffer, at: nil, options: .loops) { }
    }
}

/// 배경음 타입
enum BackgroundSound: String, CaseIterable {
    // 자연음
    case wave = "wave"
    case rain = "rain"
    case tv = "tv"

    // 멜로디 음악
    case piano = "piano"
    case guitar = "guitar"
    case ambient = "ambient"
    case lofi = "lofi"
    case meditation = "meditation"
    case space = "space"   // 우주 앰비언트 (앱 시작 시 자동 재생)

    // 우주 앰비언트 베이스 음악 (좌우 굴리기 리스트) — 새 기본 사운드
    case spaceCinematic = "spaceCinematic"
    case spaceAmbient1 = "spaceAmbient1"
    case spaceDeep = "spaceDeep"
    case spaceAmbient2 = "spaceAmbient2"
    case spaceCinematic2 = "spaceCinematic2"
    case spaceShuttle = "spaceShuttle"
    case spaceSolar = "spaceSolar"
    case spaceDrift = "spaceDrift"
    case spaceCinematic3 = "spaceCinematic3"
    case spaceAmbient3 = "spaceAmbient3"
    case spaceOrbit = "spaceOrbit"
    case spaceVoid = "spaceVoid"

    // 브레인 마사지 (미디 조합 배경음악) — 베이스 트랙 믹스 (레거시 · 굴리기 리스트에서 제외)
    case brainmassageFull = "brainmassageFull"
    case brainmassageDeep = "brainmassageDeep"
    case brainmassageWarm = "brainmassageWarm"
    case brainmassageBright = "brainmassageBright"
    case brainmassageDrone = "brainmassageDrone"
    case brainmassageGlow = "brainmassageGlow"
    case brainmassageMidnight = "brainmassageMidnight"
    case brainmassageCeleste = "brainmassageCeleste"

    /// 기존 한국어 rawValue로 저장된 데이터 호환을 위한 매핑
    private static let legacyMapping: [String: BackgroundSound] = [
        "파도": .wave,
        "비": .rain,
        "TV 소음": .tv,
        "피아노": .piano,
        "기타": .guitar,
        "앰비언트": .ambient,
        "로파이": .lofi,
        "명상 음악": .meditation
    ]

    /// 기존 한국어 rawValue도 지원하는 초기화
    static func from(_ value: String) -> BackgroundSound? {
        return BackgroundSound(rawValue: value) ?? legacyMapping[value]
    }

    var displayName: String {
        switch self {
        case .wave: return L.Background.wave.localized
        case .rain: return L.Background.rain.localized
        case .tv: return L.Background.tv.localized
        case .piano: return L.Background.piano.localized
        case .guitar: return L.Background.guitar.localized
        case .ambient: return L.Background.ambient.localized
        case .lofi: return L.Background.lofi.localized
        case .meditation: return L.Background.meditation.localized
        case .space: return "우주"
        case .spaceCinematic: return "우주 시네마틱"
        case .spaceAmbient1: return "우주 앰비언트 I"
        case .spaceDeep: return "딥 스페이스"
        case .spaceAmbient2: return "우주 앰비언트 II"
        case .spaceCinematic2: return "우주 시네마틱 II"
        case .spaceShuttle: return "스페이스 셔틀"
        case .spaceSolar: return "솔라 윈드"
        case .spaceDrift: return "우주 표류"
        case .spaceCinematic3: return "우주 시네마틱 III"
        case .spaceAmbient3: return "우주 앰비언트 III"
        case .spaceOrbit: return "오빗"
        case .spaceVoid: return "보이드"
        case .brainmassageFull: return "브레인 마사지"
        case .brainmassageDeep: return "딥 슬립"
        case .brainmassageWarm: return "웜 하모니"
        case .brainmassageBright: return "브라이트"
        case .brainmassageDrone: return "미니멀 드론"
        case .brainmassageGlow: return "글로우"
        case .brainmassageMidnight: return "미드나잇"
        case .brainmassageCeleste: return "셀레스트"
        }
    }

    var fileName: String {
        switch self {
        case .wave: return "wave_10min"
        case .rain: return "rain_10min"
        case .tv: return "tv_10min"
        case .piano: return "piano_10min"
        case .guitar: return "guitar_10min"
        case .ambient: return "ambient_10min"
        case .lofi: return "lofi_10min"
        case .meditation: return "meditation_10min"
        case .space: return "space_1min"
        case .spaceCinematic: return "space_cinematic"
        case .spaceAmbient1: return "space_ambient_1"
        case .spaceDeep: return "space_deep"
        case .spaceAmbient2: return "space_ambient_2"
        case .spaceCinematic2: return "space_cinematic_2"
        case .spaceShuttle: return "space_shuttle"
        case .spaceSolar: return "space_solar"
        case .spaceDrift: return "space_drift"
        case .spaceCinematic3: return "space_cinematic_3"
        case .spaceAmbient3: return "space_ambient_3"
        case .spaceOrbit: return "space_orbit"
        case .spaceVoid: return "space_void"
        case .brainmassageFull: return "brainmassage_full"
        case .brainmassageDeep: return "brainmassage_deep"
        case .brainmassageWarm: return "brainmassage_warm"
        case .brainmassageBright: return "brainmassage_bright"
        case .brainmassageDrone: return "brainmassage_drone"
        case .brainmassageGlow: return "brainmassage_glow"
        case .brainmassageMidnight: return "brainmassage_midnight"
        case .brainmassageCeleste: return "brainmassage_celeste"
        }
    }

    var icon: String {
        switch self {
        case .wave: return "water.waves"
        case .rain: return "cloud.rain.fill"
        case .tv: return "tv.fill"
        case .piano: return "pianokeys"
        case .guitar: return "guitars.fill"
        case .ambient: return "waveform"
        case .lofi: return "music.note.list"
        case .meditation: return "sparkles"
        case .space: return "moon.stars.fill"
        case .spaceCinematic, .spaceCinematic2, .spaceCinematic3: return "sparkles"
        case .spaceAmbient1, .spaceAmbient2, .spaceAmbient3: return "moon.stars.fill"
        case .spaceDeep: return "moon.zzz.fill"
        case .spaceShuttle: return "airplane"
        case .spaceSolar: return "sun.max.fill"
        case .spaceDrift: return "wind"
        case .spaceOrbit: return "circle.dashed"
        case .spaceVoid: return "circle.fill"
        case .brainmassageFull: return "brain.head.profile"
        case .brainmassageDeep: return "moon.zzz.fill"
        case .brainmassageWarm: return "flame.fill"
        case .brainmassageBright: return "sun.max.fill"
        case .brainmassageDrone: return "waveform.path"
        case .brainmassageGlow: return "sparkle"
        case .brainmassageMidnight: return "moon.stars.fill"
        case .brainmassageCeleste: return "star.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .wave:
            return [
                Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.15),
                Color(red: 0.1, green: 0.5, blue: 0.9).opacity(0.1)
            ]
        case .rain:
            return [
                Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.15),
                Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.1)
            ]
        case .tv:
            return [
                Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.15),
                Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.1)
            ]
        case .piano:
            return [
                Color(red: 0.8, green: 0.6, blue: 0.9).opacity(0.15),
                Color(red: 0.7, green: 0.5, blue: 0.8).opacity(0.1)
            ]
        case .guitar:
            return [
                Color(red: 0.9, green: 0.7, blue: 0.5).opacity(0.15),
                Color(red: 0.8, green: 0.6, blue: 0.4).opacity(0.1)
            ]
        case .ambient:
            return [
                Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.15),
                Color(red: 0.4, green: 0.6, blue: 0.8).opacity(0.1)
            ]
        case .lofi:
            return [
                Color(red: 0.9, green: 0.5, blue: 0.6).opacity(0.15),
                Color(red: 0.8, green: 0.4, blue: 0.5).opacity(0.1)
            ]
        case .meditation:
            return [
                Color(red: 0.6, green: 0.8, blue: 0.7).opacity(0.15),
                Color(red: 0.5, green: 0.7, blue: 0.6).opacity(0.1)
            ]
        case .space, .spaceCinematic, .spaceAmbient1, .spaceDeep, .spaceAmbient2,
             .spaceCinematic2, .spaceShuttle, .spaceSolar, .spaceDrift,
             .spaceCinematic3, .spaceAmbient3, .spaceOrbit, .spaceVoid:
            return [
                Color(red: 0.45, green: 0.45, blue: 0.85).opacity(0.15),
                Color(red: 0.30, green: 0.30, blue: 0.60).opacity(0.1)
            ]
        case .brainmassageFull, .brainmassageDeep, .brainmassageWarm, .brainmassageBright,
             .brainmassageDrone, .brainmassageGlow, .brainmassageMidnight, .brainmassageCeleste:
            return [
                Color(red: 0.50, green: 0.42, blue: 0.80).opacity(0.15),
                Color(red: 0.32, green: 0.28, blue: 0.58).opacity(0.10)
            ]
        }
    }

    var isMelodic: Bool {
        switch self {
        case .wave, .rain, .tv:
            return false
        case .piano, .guitar, .ambient, .lofi, .meditation, .space,
             .spaceCinematic, .spaceAmbient1, .spaceDeep, .spaceAmbient2, .spaceCinematic2,
             .spaceShuttle, .spaceSolar, .spaceDrift, .spaceCinematic3, .spaceAmbient3,
             .spaceOrbit, .spaceVoid,
             .brainmassageFull, .brainmassageDeep, .brainmassageWarm, .brainmassageBright,
             .brainmassageDrone, .brainmassageGlow, .brainmassageMidnight, .brainmassageCeleste:
            return true
        }
    }
}
