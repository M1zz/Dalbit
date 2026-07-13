//
//  SoundSaveView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/07.
//

import SwiftUI

/**
 이전 화면에서 커스텀 했던 음원에 이름과 이미지를 지정하여 파일로 저장하는 기능이 있는 View
 */
struct SoundSaveView: View {

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @FocusState private var isFocused: Bool
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @State var title: String = ""

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @State var originalSound: OriginalSound
    var editingSound: CustomSound? = nil

    var isEditMode: Bool {
        editingSound != nil
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack{
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(DS.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(L.A11y.backButton.localized)

                    Spacer()

                    Text(originalSound.category.displayName)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Colors.textPrimary)

                    Spacer()

                    Button {

                        if title.count <= 0 {
                            alertMessage = L.SaveView.enterOneChar.localized
                            isShowingAlert = true
                        } else {
                            let success: Bool

                            if isEditMode, let editing = editingSound {
                                // 편집 모드
                                success = viewModel.update(
                                    originalSound: editing,
                                    newTitle: title,
                                    newColor: viewModel.color)
                            } else {
                                // 새로 저장 모드
                                success = viewModel.save(
                                    with: originalSound,
                                    filter: viewModel.sound.filter,
                                    title: title,
                                    color: viewModel.color)
                            }

                            if success {
                                presentationMode.wrappedValue.dismiss()
                                presentationMode.wrappedValue.dismiss()
                                appState.moveToTab(.listen)
                            } else {
                                alertMessage = L.SaveView.duplicateName.localized
                                isShowingAlert = true
                            }
                        }

                    } label: {
                        Text(L.Common.save.localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.xs)

                VStack {
                    TextField(originalSound.name, text: $title)
                        .font(DS.Font.body())
                        .foregroundColor(DS.Colors.textPrimary)
                        .tint(DS.Colors.accent)
                        .multilineTextAlignment(.center)
                        .keyboardType(.default)
                        .autocorrectionDisabled(true)
                        .focused($isFocused)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                .fill(DS.Colors.surfaceSunken)
                        )
                }
                .padding(.horizontal, DS.Spacing.xl)

                ZStack {
                    ZStack(alignment: .topTrailing) {
                        Image(originalSound.category.imageName)
                            .resizable()
                            .scaledToFit()
                            .background(Color(hex: viewModel.color))
                        Button {
                            let randomColor = CustomSoundImageBackgroundColor.allCases.randomElement()?.rawValue
                            viewModel.color = randomColor ?? originalSound.color
                        } label: {
                            Image("repeat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                                .foregroundColor(Color(hex: "1F1F1F"))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("색상 바꾸기")
                    }
                    .cornerRadius(DS.Radius.md)
                    .padding(.vertical, DS.Spacing.xxxl)
                    .padding(.horizontal, DS.Spacing.xl)
                }
                Spacer()
            }
            .dsConstrainedWidth()
        }
        .onAppear {
            viewModel.stopSound()
            // 키보드 자동 표시 제거
            isFocused = false

            // 편집 모드일 경우 기존 값 로드
            if isEditMode, let editing = editingSound {
                title = editing.title
                viewModel.color = editing.color
            } else {
                viewModel.color = originalSound.color
            }
        }
        .onDisappear {
            viewModel.stopSound()
            presentationMode.wrappedValue.dismiss()
        }
        .background(DS.Colors.background)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text(L.Alert.saveFailed.localized), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .ignoresSafeArea(.keyboard)
    }
}


struct SoundSaveView_Previews: PreviewProvider {
    static var previews: some View {
        SoundSaveView(originalSound: OriginalSound(name: "물방울", filter: .WaterDrop, category: .WaterDrop))
            .environmentObject(CustomSoundViewModel())
    }
}
