//
//  FeedbackService.swift
//  Dalbit
//
//  앱 내 피드백/기능 요청을 CloudKit Public Database로 직접 제출한다.
//  메일 앱 없이도 동작하며, 개발자는 앱 안의 인박스(FeedbackInboxView) 또는
//  CloudKit Dashboard에서 접수 내역을 확인한다.
//
//  ⚠️ CloudKit Dashboard 설정 필요:
//  - Public DB에 "Feedback" 레코드 타입 (개발 환경에서 첫 저장 시 자동 생성)
//  - Security Roles: World에 create만 허용, read 권한 제거
//  - 개발자 계정용 admin 역할에 read/write 권한 + 본인 userRecordName 등록
//  - 스키마를 Production으로 배포
//

import Foundation
import CloudKit

final class FeedbackService {
    static let shared = FeedbackService()
    private init() {}

    /// 앱 번들ID(com.leeo.LullabyRecipe) 기반 iCloud 컨테이너
    private static let containerIdentifier = "iCloud.com.leeo.LullabyRecipe"
    static let recordType = "Feedback"

    enum FeedbackError: LocalizedError {
        case iCloudUnavailable
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable:
                return L.Feedback.errorICloud.localized
            case .saveFailed:
                return L.Feedback.errorSend.localized
            }
        }
    }

    // MARK: - 제출 (사용자)

    /// 피드백을 Public DB에 제출한다. 실패 시 throw — 호출부에서 이메일 폴백 처리.
    func submit(type: String, message: String, deviceInfo: String) async throws {
        let container = CKContainer(identifier: Self.containerIdentifier)

        // Public DB 쓰기도 iCloud 로그인이 필요하다.
        let status = try await container.accountStatus()
        guard status == .available else {
            print("⚠️ [FeedbackService.submit] iCloud 계정 없음: \(status)")
            throw FeedbackError.iCloudUnavailable
        }

        let record = CKRecord(recordType: Self.recordType)
        record["type"] = type
        record["message"] = message
        record["deviceInfo"] = deviceInfo
        record["appVersion"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        record["locale"] = Locale.current.identifier
        record["platform"] = "iOS"

        do {
            _ = try await container.publicCloudDatabase.save(record)
            print("✅ [FeedbackService.submit] 피드백 제출 완료 (type=\(type))")
        } catch {
            print("❌ [FeedbackService.submit] 제출 실패: \(error)")
            throw FeedbackError.saveFailed(error)
        }
    }

    // MARK: - 개발자 인박스 (조회/처리)

    /// 접수된 피드백 한 건 (조회용 read model)
    struct FeedbackRecord: Identifiable {
        let id: String
        let type: String
        let message: String
        let deviceInfo: String
        let appVersion: String
        let locale: String
        let createdAt: Date?
        /// 처리 상태 — "done"이면 완료 (개발자가 인박스에서 표시)
        var status: String?

        var isDone: Bool { status == "done" }

        init(_ record: CKRecord) {
            self.id = record.recordID.recordName
            self.type = record["type"] as? String ?? "-"
            self.message = record["message"] as? String ?? ""
            self.deviceInfo = record["deviceInfo"] as? String ?? ""
            self.appVersion = record["appVersion"] as? String ?? ""
            self.locale = record["locale"] as? String ?? ""
            self.createdAt = record.creationDate
            self.status = record["status"] as? String
        }
    }

    /// 접수된 피드백 전체 조회 (최신순, 최대 limit개).
    /// ⚠️ 개발자 계정 전용 — CloudKit Dashboard에서 admin 역할에 read 권한과
    /// 본인 userRecordName을 등록해야 다른 사용자의 레코드를 읽을 수 있다.
    func fetchAll(limit: Int = 100) async throws -> [FeedbackRecord] {
        let container = CKContainer(identifier: Self.containerIdentifier)
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (results, _) = try await container.publicCloudDatabase.records(
            matching: query, resultsLimit: limit)
        let records = results.compactMap { _, result in
            (try? result.get()).map(FeedbackRecord.init)
        }
        print("📬 [FeedbackService.fetchAll] 피드백 \(records.count)건 로드")
        return records
    }

    /// 현재 iCloud 계정의 CloudKit userRecordName — Dashboard admin 역할 등록에 필요.
    func currentUserRecordName() async -> String? {
        let container = CKContainer(identifier: Self.containerIdentifier)
        return try? await container.userRecordID().recordName
    }

    /// 피드백 완료/미완료 표시 (서버 반영).
    /// ⚠️ 다른 사용자의 레코드 수정이라 admin 역할에 **Write** 권한이 필요하다.
    func setDone(recordName: String, done: Bool) async throws {
        let db = CKContainer(identifier: Self.containerIdentifier).publicCloudDatabase
        let record = try await db.record(for: CKRecord.ID(recordName: recordName))
        record["status"] = done ? "done" : nil
        _ = try await db.save(record)
        print("✅ [FeedbackService.setDone] \(recordName) → done=\(done)")
    }

    /// 피드백 삭제 (서버 반영). admin 역할 Write 권한 필요.
    func delete(recordName: String) async throws {
        let db = CKContainer(identifier: Self.containerIdentifier).publicCloudDatabase
        _ = try await db.deleteRecord(withID: CKRecord.ID(recordName: recordName))
        print("🗑️ [FeedbackService.delete] \(recordName) 삭제")
    }
}
