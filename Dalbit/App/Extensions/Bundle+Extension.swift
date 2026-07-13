//
//  Bundle+Extension.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/29.
//

import Foundation

extension Bundle {
    
    func encode<T: Encodable>(data: T, to file: String, fileExtension: String) {
        let encoder = JSONEncoder()

        guard let encodedData = try? encoder.encode(data) else {
            fatalError("[ERROR] \(file) 인코딩 실패")
        }

        guard let url = self.url(forResource: file, withExtension: fileExtension) else {
            fatalError("[ERROR] \(file) 저장 경로를 찾을 수 없음")
        }
        
        do {
            try encodedData.write(to: url)
        } catch {
            fatalError("[ERROR] \(file) 저장 실패: \(error)")
        }
    }
    
    func decode<T: Decodable>(file: String, fileExtension: String) -> T {
        guard let url = self.url(forResource: file, withExtension: fileExtension) else {
            fatalError("[ERROR] \(file) 찾을 수 없음")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("[ERROR] \(file) 불러오기 실패")
        }
        
        let decoder = JSONDecoder()
        
        guard let loadedData = try? decoder.decode(T.self, from: data) else {
            fatalError("[ERROR] \(file) 디코딩 실패")
        }
        
        return loadedData
    }
}
