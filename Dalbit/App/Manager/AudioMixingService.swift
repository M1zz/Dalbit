//
//  AudioMixingService.swift
//  RelaxOn
//
//  Created by Claude on 2025/12/16.
//

import Foundation
import AVFoundation

/// 여러 오디오 소스를 믹싱하여 하나의 파일로 출력하는 서비스
class AudioMixingService {

    enum MixingError: Error {
        case noSoundsToMix
        case audioFileCreationFailed
        case mixingFailed(String)
    }

    struct MixingConfiguration {
        let sounds: [SoundLayer]
        let backgroundSound: BackgroundSound?
        let backgroundVolume: Float
        let duration: TimeInterval // 믹싱할 총 길이 (초)

        struct SoundLayer {
            let filter: AudioFilter
            let category: SoundCategory
            let volume: Float
            let pitch: Float
            let interval: TimeInterval
            let intervalVariation: Float
            let volumeVariation: Float
            let pitchVariation: Float
        }
    }

    /// 여러 사운드를 믹싱하여 하나의 오디오 파일로 생성
    /// - Parameters:
    ///   - config: 믹싱 설정
    ///   - outputURL: 출력 파일 URL
    ///   - progress: 진행률 콜백 (0.0 ~ 1.0)
    /// - Returns: 생성된 파일의 URL
    func mixSounds(
        config: MixingConfiguration,
        outputURL: URL,
        progress: @escaping (Float) -> Void
    ) async throws -> URL {

        guard !config.sounds.isEmpty else {
            throw MixingError.noSoundsToMix
        }

        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode

        // 출력 포맷 설정
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 2,
            interleaved: false
        )!

        // 출력 파일 생성
        guard let outputFile = try? AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings
        ) else {
            throw MixingError.audioFileCreationFailed
        }

        var playerNodes: [(player: AVAudioPlayerNode, times: [TimeInterval])] = []

        // 1. 배경음 설정
        if let background = config.backgroundSound {
            if let backgroundPlayer = try? setupBackgroundPlayer(
                engine: engine,
                background: background,
                volume: config.backgroundVolume,
                duration: config.duration
            ) {
                playerNodes.append((backgroundPlayer, [0.0])) // 배경음은 처음부터 재생
            }
        }

        // 2. 각 사운드 레이어 설정
        for sound in config.sounds {
            if let (player, scheduleTimes) = try? setupSoundLayer(
                engine: engine,
                sound: sound,
                duration: config.duration
            ) {
                playerNodes.append((player, scheduleTimes))
            }
        }

        // 3. 믹싱 시작
        try engine.start()

        // 4. 오디오 탭 설정하여 믹싱된 오디오 캡처
        let bufferSize: AVAudioFrameCount = 4096
        var totalFramesProcessed: AVAudioFramePosition = 0
        let totalFrames = AVAudioFramePosition(config.duration * outputFormat.sampleRate)

        mainMixer.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: outputFormat
        ) { buffer, time in
            do {
                try outputFile.write(from: buffer)
                totalFramesProcessed += AVAudioFramePosition(buffer.frameLength)

                let progressValue = Float(totalFramesProcessed) / Float(totalFrames)
                DispatchQueue.main.async {
                    progress(min(progressValue, 1.0))
                }
            } catch {
                print("❌ [AudioMixing] 버퍼 쓰기 실패: \(error)")
            }
        }

        // 5. 모든 플레이어 시작
        for (player, _) in playerNodes {
            player.play()
        }

        // 6. 믹싱 완료 대기
        try await Task.sleep(nanoseconds: UInt64(config.duration * 1_000_000_000))

        // 7. 정리
        for (player, _) in playerNodes {
            player.stop()
        }
        mainMixer.removeTap(onBus: 0)
        engine.stop()

        print("✅ [AudioMixing] 믹싱 완료: \(outputURL.lastPathComponent)")
        return outputURL
    }

    /// 배경음 플레이어 설정
    private func setupBackgroundPlayer(
        engine: AVAudioEngine,
        background: BackgroundSound,
        volume: Float,
        duration: TimeInterval
    ) throws -> AVAudioPlayerNode {

        let player = AVAudioPlayerNode()
        engine.attach(player)

        // 배경음 파일 로드
        guard let audioFileURL = Bundle.main.url(
            forResource: background.fileName,
            withExtension: "mp3"
        ),
              let audioFile = try? AVAudioFile(forReading: audioFileURL) else {
            throw MixingError.mixingFailed("배경음 파일을 찾을 수 없습니다: \(background.fileName)")
        }

        let format = audioFile.processingFormat
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // 볼륨 설정
        player.volume = volume

        // 배경음 스케줄링 (루프)
        player.scheduleFile(audioFile, at: nil, completionHandler: nil)

        return player
    }

    /// 사운드 레이어 플레이어 설정
    private func setupSoundLayer(
        engine: AVAudioEngine,
        sound: MixingConfiguration.SoundLayer,
        duration: TimeInterval
    ) throws -> (AVAudioPlayerNode, [TimeInterval]) {

        let player = AVAudioPlayerNode()
        let pitchEffect = AVAudioUnitTimePitch()

        engine.attach(player)
        engine.attach(pitchEffect)

        // 오디오 파일 로드
        let fileName = sound.filter.rawValue
        guard let audioFileURL = Bundle.main.url(
            forResource: fileName,
            withExtension: "mp3"
        ),
              let audioFile = try? AVAudioFile(forReading: audioFileURL) else {
            throw MixingError.mixingFailed("사운드 파일을 찾을 수 없습니다: \(fileName)")
        }

        let format = audioFile.processingFormat

        // 피치 설정
        pitchEffect.pitch = sound.pitch * 100 // -2400 ~ +2400 cents

        // 연결: player → pitch → mixer
        engine.connect(player, to: pitchEffect, format: format)
        engine.connect(pitchEffect, to: engine.mainMixerNode, format: format)

        // 볼륨 설정
        player.volume = sound.volume

        // 재생 시간 계산
        var scheduleTimes: [TimeInterval] = []
        var currentTime: TimeInterval = 0

        while currentTime < duration {
            scheduleTimes.append(currentTime)

            // 간격에 변동폭 적용
            let variation = Double(sound.intervalVariation) * sound.interval
            let randomOffset = TimeInterval.random(in: -variation...variation)
            currentTime += sound.interval + randomOffset
        }

        // 각 시간에 사운드 스케줄링
        for (index, time) in scheduleTimes.enumerated() {
            // 볼륨 변동 적용
            let volumeVariation = sound.volumeVariation * sound.volume
            let randomVolume = sound.volume + Float.random(in: -volumeVariation...volumeVariation)

            let sampleTime = AVAudioFramePosition(time * format.sampleRate)
            let when = AVAudioTime(sampleTime: sampleTime, atRate: format.sampleRate)

            player.scheduleFile(audioFile, at: when) {
                // 스케줄 완료
            }

            // 다음 재생 전에 볼륨 조정
            if index < scheduleTimes.count - 1 {
                player.volume = max(0.0, min(1.0, randomVolume))
            }
        }

        return (player, scheduleTimes)
    }

    /// 믹싱된 파일 저장을 위한 출력 URL 생성
    static func generateOutputURL(soundTitle: String) -> URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let mixedSoundsDirectory = documentsPath.appendingPathComponent("MixedSounds", isDirectory: true)

        // 디렉토리 생성
        try? FileManager.default.createDirectory(
            at: mixedSoundsDirectory,
            withIntermediateDirectories: true
        )

        // 파일명 생성 (timestamp 포함)
        let timestamp = Date().timeIntervalSince1970
        let fileName = "\(soundTitle)_\(Int(timestamp)).m4a"

        return mixedSoundsDirectory.appendingPathComponent(fileName)
    }
}
