//
//  UserFileManager.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/29.
//

import Foundation

/**
 FileManager에 오디오 데이터를 파일로 저장 & 불러오기 & (파일이름)수정 & 파일 삭제 기능
 */
final class UserFileManager {
    
    // MARK: - Properties
    static let shared = UserFileManager()
    private let fileManager = FileManager.default
    
}

// MARK: - Methods
extension UserFileManager {

    func saveCustomSound(_ customSound: CustomSound) -> Bool {
        fileManager.encode(data: customSound, to: customSound.title)
    }

    func loadCustomSound(title: String) -> CustomSound? {
        return fileManager.decode(CustomSound.self, from: title)
    }

    func updateCustomSound(_ customSound: CustomSound, oldTitle: String) -> Bool {
        // 제목이 변경된 경우 기존 파일 삭제
        if oldTitle != customSound.title {
            deleteCustomSound(title: oldTitle)
        }
        // 새 내용으로 저장
        return saveCustomSound(customSound)
    }

    @discardableResult
    func deleteCustomSound(title: String) -> Bool {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let url = urls.first?.appendingPathComponent("relaxOn").appendingPathComponent(title).appendingPathExtension(FileExtension.json.rawValue) else {
            print("[ERROR] \(title) 삭제 실패: 파일 경로를 찾을 수 없음")
            return false
        }

        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                print("[SUCCESS] \(title) 삭제 성공")
                return true
            } else {
                print("[WARNING] \(title) 파일이 존재하지 않음")
                return false
            }
        } catch {
            print("[ERROR] \(title) 삭제 실패: \(error)")
            return false
        }
    }

}
