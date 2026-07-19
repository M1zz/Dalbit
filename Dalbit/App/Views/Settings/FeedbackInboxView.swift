//
//  FeedbackInboxView.swift
//  Dalbit
//
//  개발자 전용 피드백 인박스 — CloudKit Public DB의 Feedback 레코드를 앱 안에서 바로 확인한다.
//  진입: 보관함의 '의견 보내기' 행을 길게(1.5초) 누르면 열린다 (숨은 동선).
//
//  ⚠️ 다른 사용자의 레코드를 읽으려면 CloudKit Dashboard에서 admin 역할을 만들어
//  read/write 권한과 본인 userRecordName을 등록해야 한다. 일반 사용자가 열어도
//  권한 오류/빈 목록만 보일 뿐 데이터는 노출되지 않는다.
//  (개발자 전용 화면이라 문구는 한국어 고정)
//

import SwiftUI
import UIKit

struct FeedbackInboxView: View {
    @State private var records: [FeedbackService.FeedbackRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var userRecordName: String?
    @State private var didCopyId = false
    @State private var pendingDelete: FeedbackService.FeedbackRecord?

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("yyMMdjmm")
        return f
    }

    var body: some View {
        List {
            if isLoading && records.isEmpty {
                Section {
                    HStack(spacing: DS.Spacing.sm) {
                        ProgressView()
                        Text("불러오는 중…")
                            .font(DS.Font.body())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .listRowBackground(DS.Colors.surface)
                }
            } else if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "xmark.circle.fill")
                        .font(DS.Font.body())
                        .foregroundColor(DS.Colors.danger)
                        .listRowBackground(DS.Colors.surface)
                } footer: {
                    Text("권한 오류라면 CloudKit Dashboard에서 admin 역할에 read 권한과 아래 사용자 ID를 등록했는지 확인하세요.")
                        .font(DS.Font.caption())
                }
            } else if records.isEmpty {
                Section {
                    Text("아직 접수된 피드백이 없어요")
                        .font(DS.Font.body())
                        .foregroundColor(DS.Colors.textSecondary)
                        .listRowBackground(DS.Colors.surface)
                }
            } else {
                Section {
                    ForEach(records) { record in
                        recordRow(record)
                            .listRowBackground(DS.Colors.surface)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleDone(record)
                                } label: {
                                    Label(record.isDone ? "완료 해제" : "완료 표시",
                                          systemImage: record.isDone ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(record.isDone ? .orange : .green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingDelete = record
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("접수 \(records.count)건 · 완료 \(records.filter(\.isDone).count)건")
                } footer: {
                    Text("오른쪽으로 밀면 완료 표시, 왼쪽으로 밀면 삭제. 완료/삭제는 CloudKit admin 역할에 쓰기 권한이 있어야 반영돼요.")
                        .font(DS.Font.caption())
                }
            }

            // Dashboard admin 역할 등록용 내 사용자 ID
            if let userRecordName {
                Section {
                    Button {
                        UIPasteboard.general.string = userRecordName
                        withAnimation { didCopyId = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { didCopyId = false }
                        }
                    } label: {
                        HStack {
                            Text(userRecordName)
                                .font(.caption.monospaced())
                                .foregroundColor(DS.Colors.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Image(systemName: didCopyId ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(didCopyId ? DS.Colors.success : DS.Colors.accent)
                        }
                    }
                    .listRowBackground(DS.Colors.surface)
                } header: {
                    Text("내 사용자 ID")
                } footer: {
                    Text("CloudKit Dashboard의 admin 역할에 이 ID를 추가하면 앱에서 모든 피드백을 읽을 수 있어요. 탭하면 복사됩니다.")
                        .font(DS.Font.caption())
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ScreenBackground())
        .navigationTitle("접수된 피드백")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
        .alert("이 피드백을 삭제할까요?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("삭제", role: .destructive) {
                if let record = pendingDelete { deleteRecord(record) }
                pendingDelete = nil
            }
            Button("취소", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("서버에서 완전히 삭제되며 되돌릴 수 없어요.")
        }
    }

    private func recordRow(_ record: FeedbackService.FeedbackRecord) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack(spacing: 6) {
                let type = FeedbackType(rawValue: record.type)
                Image(systemName: record.isDone ? "checkmark.circle.fill" : (type?.icon ?? "ellipsis.bubble"))
                    .font(.caption)
                    .foregroundColor(record.isDone ? DS.Colors.success : DS.Colors.accent)
                    .accessibilityHidden(true)
                Text(type?.localizedName ?? record.type)
                    .font(DS.Font.caption().weight(.semibold))
                    .foregroundColor(record.isDone ? DS.Colors.textSecondary : DS.Colors.accent)
                if record.isDone {
                    Text("완료")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(DS.Colors.success.opacity(0.15))
                        .foregroundColor(DS.Colors.success)
                        .clipShape(Capsule())
                }
                Spacer()
                if let createdAt = record.createdAt {
                    Text(dateFormatter.string(from: createdAt))
                        .font(.caption2)
                        .foregroundColor(DS.Colors.textTertiary)
                }
            }

            Text(record.message)
                .font(DS.Font.body())
                .foregroundColor(record.isDone ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                .textSelection(.enabled)

            Text(record.deviceInfo.isEmpty
                 ? "\(record.appVersion) · \(record.locale)"
                 : "\(record.deviceInfo) · \(record.locale)")
                .font(.caption2)
                .foregroundColor(DS.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if userRecordName == nil {
            userRecordName = await FeedbackService.shared.currentUserRecordName()
        }
        do {
            records = try await FeedbackService.shared.fetchAll()
        } catch {
            print("❌ [FeedbackInboxView.load] \(error)")
            errorMessage = "피드백을 불러오지 못했어요: \(error.localizedDescription)"
        }
    }

    /// 완료/미완료 토글 — 서버 반영 후 로컬 목록 갱신.
    private func toggleDone(_ record: FeedbackService.FeedbackRecord) {
        Task {
            do {
                try await FeedbackService.shared.setDone(recordName: record.id, done: !record.isDone)
                if let index = records.firstIndex(where: { $0.id == record.id }) {
                    records[index].status = record.isDone ? nil : "done"
                }
            } catch {
                print("❌ [FeedbackInboxView.toggleDone] \(error)")
                errorMessage = "처리하지 못했어요: \(error.localizedDescription)"
            }
        }
    }

    /// 서버에서 레코드 삭제 후 로컬 목록에서 제거.
    private func deleteRecord(_ record: FeedbackService.FeedbackRecord) {
        Task {
            do {
                try await FeedbackService.shared.delete(recordName: record.id)
                records.removeAll { $0.id == record.id }
            } catch {
                print("❌ [FeedbackInboxView.deleteRecord] \(error)")
                errorMessage = "처리하지 못했어요: \(error.localizedDescription)"
            }
        }
    }
}
