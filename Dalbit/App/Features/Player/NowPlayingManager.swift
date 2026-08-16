//
//  NowPlayingManager.swift
//  Dalbit
//
//  잠금화면·제어센터·이어폰 버튼 연동. 재생 정보 갱신과 원격 명령 처리.
//

import Foundation
import MediaPlayer
import UIKit

final class NowPlayingManager {
    static let shared = NowPlayingManager()
    private init() {}

    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onToggle: (() -> Void)?
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?

    private var configured = false

    /// 리모트 커맨드 등록 (앱 생애 1회)
    func setupRemoteCommands() {
        guard !configured else { return }
        configured = true

        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.onPlay?(); return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.onPause?(); return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onToggle?(); return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.onNext?(); return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.onPrevious?(); return .success
        }
        [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
         center.nextTrackCommand, center.previousTrackCommand].forEach { $0.isEnabled = true }
    }

    /// 잠금화면에 표시할 곡 정보 갱신
    func update(title: String, isPlaying: Bool, tint: UIColor) {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = L.App.name.localized
        info[MPNowPlayingInfoPropertyIsLiveStream] = true   // 백색소음 = 무한 재생(스크러버 숨김)
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        let art = Self.artwork(tint: tint)
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: art.size) { _ in art }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    /// 곡 색에 맞춘 단순한 구체 아트워크 생성
    private static func artwork(tint: UIColor) -> UIImage {
        let size = CGSize(width: 400, height: 400)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(white: 0.07, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            tint.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 90, y: 90, width: 220, height: 220))
        }
    }
}

// MARK: - Timer View
