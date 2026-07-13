//
//  FileManager+Extension.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/29.
//

import Foundation

extension FileManager {
    
    func encode<T: Encodable>(data: T, to fileName: String, directory: FileManager.SearchPathDirectory = .documentDirectory) -> Bool {
        print("\n📁 [FILE] encode 시작: '\(fileName)'")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let encodedData = try? encoder.encode(data) else {
            print("❌ [FILE] 인코딩 실패: '\(fileName)'")
            return false
        }
        print("✅ [FILE] 인코딩 성공: \(encodedData.count) bytes")

        let urls = self.urls(for: directory, in: .userDomainMask)

        if let url = urls.first?.appendingPathComponent("relaxOn") {
            print("📂 [FILE] 디렉토리 경로: \(url.path)")
            do {
                if !fileExists(atPath: url.path) {
                    print("📁 [FILE] relaxOn 폴더 생성 중...")
                    try createDirectory(at: url, withIntermediateDirectories: true)
                    print("✅ [FILE] 폴더 생성 완료")
                } else {
                    print("✅ [FILE] relaxOn 폴더 존재함")
                }

                let fileURL = url.appendingPathComponent(fileName).appendingPathExtension(FileExtension.json.rawValue)
                print("💾 [FILE] 파일 경로: \(fileURL.path)")

                try encodedData.write(to: fileURL)
                print("✅ [FILE] 파일 쓰기 성공")

                // 파일 존재 확인
                if fileExists(atPath: fileURL.path) {
                    let attributes = try attributesOfItem(atPath: fileURL.path)
                    let fileSize = attributes[.size] as? Int ?? 0
                    print("✅ [FILE] 파일 저장 확인: \(fileSize) bytes")
                } else {
                    print("⚠️ [FILE] 경고: 파일이 존재하지 않음")
                }

            } catch {
                print("❌ [FILE] 저장 실패: \(fileName)")
                print("   에러: \(error.localizedDescription)")
                return false
            }
        } else {
            print("❌ [FILE] 저장 경로를 찾을 수 없음")
            return false
        }

        print("🎉 [FILE] '\(fileName)' 저장 완료\n")
        return true
    }

    
    func decode<T: Decodable>(_ fileType: T.Type, from fileName: String, directory: FileManager.SearchPathDirectory = .documentDirectory) -> T? {
        print(#function)
        let urls = self.urls(for: directory, in: .userDomainMask)
        
        guard let url = urls.first?.appendingPathComponent("relaxOn").appendingPathComponent(fileName).appendingPathExtension(FileExtension.json.rawValue) else {
            print("[ERROR] \(fileName) 로드 실패: 파일 경로를 찾을 수 없음")
            return nil
        }
        //print("[ FileManager - decode ] url : \(url)")
        
        guard let data = try? Data(contentsOf: url) else {
            print("[ERROR] \(fileName) 로드 실패: 데이터를 불러올 수 없음")
            return nil
        }
        
        let decoder = JSONDecoder()
        guard let loadedData = try? decoder.decode(T.self, from: data) else {
            print("[ERROR] \(fileName) 디코딩 실패")
            return nil
        }
        
        print("[ FileManager - decode ] loadedData : \(loadedData)")
        return loadedData
    }

}
