//
//  FeedbackView.swift
//  Dalbit
//
//  사용자가 앱을 쓰다가 버그/제안/문의를 개발자에게 바로 보내는 화면.
//  1차: CloudKit Public DB 제출(iCloud 로그인만 필요) → 실패 시 mailto: 폴백.
//

import SwiftUI
import UIKit

// MARK: - Feedback Type

enum FeedbackType: String, CaseIterable {
    case bug      = "bug"
    case feature  = "feature"
    case question = "question"
    case other    = "other"

    var localizedName: String {
        switch self {
        case .bug:      return L.Feedback.typeBug.localized
        case .feature:  return L.Feedback.typeFeature.localized
        case .question: return L.Feedback.typeQuestion.localized
        case .other:    return L.Feedback.typeOther.localized
        }
    }

    var icon: String {
        switch self {
        case .bug:      return "ladybug"
        case .feature:  return "lightbulb"
        case .question: return "questionmark.circle"
        case .other:    return "ellipsis.bubble"
        }
    }
}

// MARK: - Feedback View

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: FeedbackType = .bug
    @State private var message: String = ""
    @State private var didSend = false
    @State private var isSending = false
    @State private var errorMessage: String?

    private static let developerEmail = "mizzking75@gmail.com"

    private let deviceInfo: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let device = UIDevice.current
        return "App \(version) | \(device.model) | \(device.systemName) \(device.systemVersion)"
    }()

    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    typeSelector
                    messageEditor
                    deviceInfoCard
                    sendButton
                    Spacer(minLength: 40)
                }
                .padding(DS.Spacing.screen)
            }
            .dsConstrainedWidth()
        }
        .navigationTitle(L.Feedback.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .center) {
            if didSend { sentConfirmation }
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(L.Feedback.typeLabel.localized)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                ForEach(FeedbackType.allCases, id: \.self) { type in
                    typeChip(type)
                }
            }
        }
    }

    private func typeChip(_ type: FeedbackType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedType = type }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(DS.Font.subhead())
                Text(type.localizedName)
                    .font(DS.Font.subhead())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.xs)
            .background(selectedType == type ? DS.Colors.accent : DS.Colors.surface)
            .foregroundColor(selectedType == type ? DS.Colors.background : DS.Colors.textPrimary)
            .cornerRadius(DS.Radius.sm)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedType == type ? .isSelected : [])
        .accessibilityLabel(type.localizedName)
    }

    // MARK: - Message Editor

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(L.Feedback.messageLabel.localized)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $message)
                    .font(DS.Font.body())
                    .foregroundColor(DS.Colors.textPrimary)
                    .frame(minHeight: 140)
                    .padding(DS.Spacing.xs)
                    .background(DS.Colors.surface)
                    .cornerRadius(DS.Radius.sm)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(L.Feedback.messageLabel.localized)

                if message.isEmpty {
                    Text(placeholderText)
                        .font(DS.Font.body())
                        .foregroundColor(DS.Colors.textTertiary)
                        .padding(.horizontal, DS.Spacing.sm + 2)
                        .padding(.vertical, DS.Spacing.md)
                        .allowsHitTesting(false)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(DS.Font.caption())
                    .foregroundColor(DS.Colors.danger)
            }
        }
    }

    private var placeholderText: String {
        switch selectedType {
        case .bug:      return L.Feedback.placeholderBug.localized
        case .feature:  return L.Feedback.placeholderFeature.localized
        case .question: return L.Feedback.placeholderQuestion.localized
        case .other:    return L.Feedback.placeholderOther.localized
        }
    }

    // MARK: - Device Info Card

    private var deviceInfoCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(L.Feedback.deviceInfo.localized)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textSecondary)

            Text(deviceInfo)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
                .padding(DS.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.Colors.surfaceSunken)
                .cornerRadius(DS.Radius.sm)
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        let isDisabled = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
        return Button(action: sendFeedback) {
            HStack(spacing: DS.Spacing.xs) {
                if isSending {
                    ProgressView()
                        .tint(DS.Colors.background)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(isSending ? L.Feedback.sending.localized : L.Feedback.send.localized)
                    .fontWeight(.semibold)
            }
            .font(DS.Font.body())
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(isDisabled ? DS.Colors.surfaceSunken : DS.Colors.accent)
            .foregroundColor(isDisabled ? DS.Colors.textTertiary : DS.Colors.background)
            .cornerRadius(DS.Radius.md)
        }
        .disabled(isDisabled)
        .accessibilityLabel(L.Feedback.send.localized)
    }

    // MARK: - Sent Confirmation Overlay

    private var sentConfirmation: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(DS.Colors.success)
            Text(L.Feedback.sent.localized)
                .font(DS.Font.headline())
                .multilineTextAlignment(.center)
                .foregroundColor(DS.Colors.textPrimary)
        }
        .padding(DS.Spacing.xxl)
        .background(DS.Colors.surfaceElevated)
        .cornerRadius(DS.Radius.lg)
        .shadow(color: DS.Shadow.floating.color,
                radius: DS.Shadow.floating.radius,
                y: DS.Shadow.floating.y)
        .padding(DS.Spacing.xxxl)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Send Logic

    /// 1차: CloudKit Public DB로 직접 제출. 실패 시 mailto: 폴백을 안내한다.
    private func sendFeedback() {
        isSending = true
        errorMessage = nil
        Task {
            do {
                try await FeedbackService.shared.submit(
                    type: selectedType.rawValue,
                    message: message,
                    deviceInfo: deviceInfo
                )
                await MainActor.run {
                    isSending = false
                    handleSent()
                }
            } catch {
                print("⚠️ [FeedbackView.sendFeedback] CloudKit 제출 실패 → 이메일 폴백: \(error)")
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                    openMailtoURL()
                }
            }
        }
    }

    /// CloudKit 실패 시(예: iCloud 미로그인) mailto:로 기본 메일 앱을 연다.
    private func openMailtoURL() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let subject = "[\(selectedType.localizedName)] Dalbit \(version)"
        let body = "\(message)\n\n---\n\(deviceInfo)"
        let raw = "mailto:\(Self.developerEmail)?subject=\(subject)&body=\(body)"
        guard let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { return }
        UIApplication.shared.open(url)
    }

    private func handleSent() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { didSend = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { FeedbackView() }
            .preferredColorScheme(.dark)
    }
}
