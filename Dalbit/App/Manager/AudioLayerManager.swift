//
//  AudioLayerManager.swift
//  RelaxOn
//
//  Created by Claude on 2026/01/16.
//

import AVFoundation
import Combine

/// 오디오 레이어 생명주기 및 성능 최적화를 담당하는 관리자
final class AudioLayerManager {

    // MARK: - Types

    /// 오디오 레이어 정보
    struct AudioLayer {
        let id: UUID
        let player: AVAudioPlayerNode
        let pitchEffect: AVAudioUnitTimePitch
        let audioFile: AVAudioFile
        let audioBuffer: AVAudioPCMBuffer
        let variation: AudioVariation
        var position: AVAudio3DPoint
        let filter: AudioFilter
        let category: SoundCategory

        // 스케줄링 상태
        var isScheduling: Bool = false
        var lastScheduleTime: Date?
    }

    // MARK: - Properties

    private let engine: AVAudioEngine
    private let environmentNode: AVAudioEnvironmentNode?
    private var isSpatialAudioEnabled: Bool

    /// 현재 활성화된 레이어들
    private(set) var layers: [UUID: AudioLayer] = [:]

    /// 버퍼 캐시 (파일명 -> 버퍼)
    private var bufferCache: [String: AVAudioPCMBuffer] = [:]

    /// 오디오 파일 캐시 (파일명 -> AVAudioFile)
    private var fileCache: [String: AVAudioFile] = [:]

    /// 레이어별 스케줄링 타이머
    private var schedulingTimers: [UUID: Timer] = [:]

    /// 레이어 재생 시 호출되는 콜백 (filter, volume, pitch)
    var onLayerPlay: ((AudioFilter, Float, Float) -> Void)?

    // MARK: - Initialization

    init(engine: AVAudioEngine, environmentNode: AVAudioEnvironmentNode?, isSpatialAudioEnabled: Bool) {
        self.engine = engine
        self.environmentNode = environmentNode
        self.isSpatialAudioEnabled = isSpatialAudioEnabled
    }

    // MARK: - Public Methods

    /// 레이어 추가
    func addLayer(
        filter: AudioFilter,
        category: SoundCategory,
        variation: AudioVariation,
        position: AVAudio3DPoint
    ) throws -> UUID {
        let layerId = UUID()

        // 파일 로드 (캐시 사용)
        let fileName = filter.rawValue
        guard let audioFile = try loadAudioFile(fileName: fileName) else {
            throw AudioLayerError.fileNotFound(fileName)
        }

        // 버퍼 준비 (캐시 사용)
        guard let buffer = try prepareBuffer(audioFile: audioFile, fileName: fileName) else {
            throw AudioLayerError.bufferCreationFailed
        }

        // 플레이어 및 이펙트 생성
        let player = AVAudioPlayerNode()
        let pitchEffect = AVAudioUnitTimePitch()

        // 엔진에 노드 추가
        engine.attach(player)
        engine.attach(pitchEffect)

        let format = audioFile.processingFormat

        // 공간음향 활성화 여부에 따라 연결
        if isSpatialAudioEnabled, let environment = environmentNode {
            engine.connect(player, to: pitchEffect, format: format)
            engine.connect(pitchEffect, to: environment, format: format)
            player.position = position
        } else {
            engine.connect(player, to: pitchEffect, format: format)
            engine.connect(pitchEffect, to: engine.mainMixerNode, format: format)
        }

        // 초기 설정 적용
        player.volume = variation.volume
        pitchEffect.pitch = Float(variation.pitch * 100)

        // 레이어 생성
        let layer = AudioLayer(
            id: layerId,
            player: player,
            pitchEffect: pitchEffect,
            audioFile: audioFile,
            audioBuffer: buffer,
            variation: variation,
            position: position,
            filter: filter,
            category: category
        )

        layers[layerId] = layer

        print("✅ [LayerManager] 레이어 추가: \(fileName) (ID: \(layerId))")

        return layerId
    }

    /// 레이어 제거
    func removeLayer(_ layerId: UUID) {
        guard let layer = layers[layerId] else {
            print("⚠️ [LayerManager] 제거할 레이어를 찾을 수 없음: \(layerId)")
            return
        }

        // 타이머 정리
        schedulingTimers[layerId]?.invalidate()
        schedulingTimers.removeValue(forKey: layerId)

        // 페이드아웃 후 제거
        fadeOutAndRemove(layer: layer)

        // 레이어 목록에서 제거
        layers.removeValue(forKey: layerId)

        print("🗑️ [LayerManager] 레이어 제거: \(layer.filter.rawValue)")
    }

    /// 모든 레이어 제거
    func removeAllLayers() {
        let layerIds = Array(layers.keys)
        for layerId in layerIds {
            removeLayer(layerId)
        }

        print("🗑️ [LayerManager] 모든 레이어 제거 완료")
    }

    /// 레이어 재생 시작
    func startLayer(_ layerId: UUID) {
        guard var layer = layers[layerId] else {
            print("⚠️ [LayerManager] 재생할 레이어를 찾을 수 없음: \(layerId)")
            return
        }

        layer.isScheduling = true
        layers[layerId] = layer

        scheduleNextBuffer(for: layerId)

        if !layer.player.isPlaying {
            layer.player.play()
        }

        print("▶️ [LayerManager] 레이어 재생 시작: \(layer.filter.rawValue)")
    }

    /// 모든 레이어 재생 시작
    func startAllLayers() {
        for layerId in layers.keys {
            startLayer(layerId)
        }
    }

    /// 레이어 볼륨 변경
    func setLayerVolume(_ layerId: UUID, volume: Float) {
        guard let layer = layers[layerId] else { return }
        layer.player.volume = max(0.0, min(1.0, volume))
    }

    /// 레이어 피치 변경
    func setLayerPitch(_ layerId: UUID, pitch: Float) {
        guard let layer = layers[layerId] else { return }
        layer.pitchEffect.pitch = Float(pitch * 100)
    }

    /// 레이어 위치 변경
    func setLayerPosition(_ layerId: UUID, position: AVAudio3DPoint) {
        guard var layer = layers[layerId] else { return }
        layer.position = position
        layer.player.position = position
        layers[layerId] = layer
    }

    /// 레이어 위치 가져오기
    func getLayerPosition(_ layerId: UUID) -> AVAudio3DPoint? {
        return layers[layerId]?.position
    }

    /// 공간음향 설정 변경
    func setSpatialAudioEnabled(_ enabled: Bool) {
        isSpatialAudioEnabled = enabled
        // 모든 레이어를 재연결해야 하므로 재시작 필요
        print("🎧 [LayerManager] 공간음향 설정 변경: \(enabled)")
    }

    /// 현재 레이어 정보 가져오기
    func getLayerInfo(_ layerId: UUID) -> (filter: AudioFilter, category: SoundCategory, variation: AudioVariation)? {
        guard let layer = layers[layerId] else { return nil }
        return (layer.filter, layer.category, layer.variation)
    }

    /// 모든 레이어 ID 가져오기
    func getAllLayerIds() -> [UUID] {
        return Array(layers.keys)
    }

    // MARK: - Private Methods

    /// 오디오 파일 로드 (캐시 사용)
    private func loadAudioFile(fileName: String) throws -> AVAudioFile? {
        // 캐시에서 확인
        if let cachedFile = fileCache[fileName] {
            return cachedFile
        }

        // 새로 로드
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            return nil
        }

        let audioFile = try AVAudioFile(forReading: fileURL)
        fileCache[fileName] = audioFile

        return audioFile
    }

    /// 버퍼 준비 (캐시 사용)
    private func prepareBuffer(audioFile: AVAudioFile, fileName: String) throws -> AVAudioPCMBuffer? {
        // 캐시에서 확인
        if let cachedBuffer = bufferCache[fileName] {
            return cachedBuffer
        }

        // 새로 생성
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            return nil
        }

        try audioFile.read(into: buffer)
        bufferCache[fileName] = buffer

        print("📦 [LayerManager] 버퍼 캐시 저장: \(fileName)")

        return buffer
    }

    /// 다음 버퍼 스케줄링
    private func scheduleNextBuffer(for layerId: UUID) {
        guard var layer = layers[layerId], layer.isScheduling else { return }

        let randomizedInterval = getRandomizedInterval(for: layer.variation)
        let randomVolume = getRandomizedVolume(for: layer.variation)
        let randomPitch = getRandomizedPitch(for: layer.variation)

        // 버퍼 스케줄링
        layer.player.scheduleBuffer(layer.audioBuffer) { [weak self] in
            guard let self = self else { return }

            // 다음 재생 스케줄 (메인 스레드가 아닌 백그라운드에서)
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + randomizedInterval) {
                self.scheduleNextBuffer(for: layerId)
            }
        }

        // 플레이어 시작
        if !layer.player.isPlaying {
            layer.player.play()
        }

        // 변동폭 적용
        layer.player.volume = randomVolume
        layer.pitchEffect.pitch = randomPitch

        // 재생 이벤트 콜백 (메인 스레드에서 UI 업데이트용)
        let filter = layer.filter
        DispatchQueue.main.async { [weak self] in
            self?.onLayerPlay?(filter, randomVolume, randomPitch)
        }

        layer.lastScheduleTime = Date()
        layers[layerId] = layer
    }

    /// 페이드아웃 후 노드 제거
    private func fadeOutAndRemove(layer: AudioLayer) {
        let initialVolume = layer.player.volume
        var fadeStep = 0
        let totalSteps = 20
        let fadeInterval = 0.005 // 0.1초 페이드아웃

        let fadeTimer = Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            fadeStep += 1
            let newVolume = initialVolume * Float(totalSteps - fadeStep) / Float(totalSteps)
            layer.player.volume = max(0, newVolume)

            if fadeStep >= totalSteps {
                timer.invalidate()

                // 플레이어 중지 및 detach
                layer.player.stop()
                self.engine.detach(layer.player)
                self.engine.detach(layer.pitchEffect)

                print("✅ [LayerManager] 레이어 fadeOut 완료: \(layer.filter.rawValue)")
            }
        }

        RunLoop.current.add(fadeTimer, forMode: .common)
    }

    /// 변동폭이 적용된 간격 계산
    private func getRandomizedInterval(for variation: AudioVariation) -> Double {
        let baseInterval = Double(variation.interval)
        let variationAmount = Double(variation.intervalVariation)

        if variationAmount > 0 {
            let randomFactor = Double.random(in: -variationAmount...variationAmount)
            let randomizedInterval = baseInterval * (1.0 + randomFactor)
            return max(0.1, randomizedInterval)
        }

        return baseInterval
    }

    /// 변동폭이 적용된 볼륨 계산
    private func getRandomizedVolume(for variation: AudioVariation) -> Float {
        let baseVolume = variation.volume
        let variationAmount = variation.volumeVariation

        if variationAmount > 0 {
            let randomFactor = Float.random(in: -variationAmount...variationAmount)
            let randomizedVolume = baseVolume * (1.0 + randomFactor)
            return max(0.1, min(1.0, randomizedVolume))
        }

        return baseVolume
    }

    /// 변동폭이 적용된 피치 계산
    private func getRandomizedPitch(for variation: AudioVariation) -> Float {
        let basePitch = variation.pitch
        let variationAmount = variation.pitchVariation

        if variationAmount > 0 {
            let randomFactor = Float.random(in: -variationAmount...variationAmount)
            let randomizedPitch = basePitch + randomFactor
            return Float(randomizedPitch * 100)
        }

        return Float(basePitch * 100)
    }

    // MARK: - Cleanup

    /// 캐시 정리
    func clearCache() {
        bufferCache.removeAll()
        fileCache.removeAll()
        print("🧹 [LayerManager] 캐시 정리 완료")
    }
}

// MARK: - Errors

enum AudioLayerError: Error {
    case fileNotFound(String)
    case bufferCreationFailed
    case engineNotRunning

    var localizedDescription: String {
        switch self {
        case .fileNotFound(let fileName):
            return "오디오 파일을 찾을 수 없습니다: \(fileName)"
        case .bufferCreationFailed:
            return "오디오 버퍼 생성에 실패했습니다"
        case .engineNotRunning:
            return "오디오 엔진이 실행 중이지 않습니다"
        }
    }
}
