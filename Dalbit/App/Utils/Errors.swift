//
//  Errors.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/04/18.
//

import Foundation

/// UserFileManager 에서 발생하는 에러
enum UserFileManagerError: Error {
    case fileNotFound
}

/// MixedSound 객체 관련 에러
enum MixedSoundError: Error {
    case fileSaveFailed
    case invalidData
    case decodingFailed
}
