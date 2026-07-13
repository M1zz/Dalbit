//
//  NewOnboardingView.swift
//  RelaxOn
//
//  Created by 김연호 on 2022/08/08.
//

import SwiftUI

struct OnboardingView: View {
    // MARK: - State Properties
    @State var select: Int = 0
    @State var selectedBaseSound: Sound = Sound(id: 0,
                                                name: "Empty",
                                                soundType: .base,
                                                audioVolume: 0.5,
                                                fileName: "")
    @State var selectedMelodySound: Sound = Sound(id: 10,
                                                  name: "Empty",
                                                  soundType: .melody,
                                                  audioVolume: 0.5,
                                                  fileName: "")
    @State var selectedWhiteNoiseSound: Sound = Sound(id: 20,
                                                      name: "Empty",
                                                      soundType: .whiteNoise,
                                                      audioVolume: 0.5,
                                                      fileName: "")

    @State var selectedImageNames: (base: String, melody: String, whiteNoise: String) = (
        base: "",
        melody: "",
        whiteNoise: ""
    )

    @State var opacityAnimationValues = [0.0, 0.0, 0.0]
    @State var textEntered = ""
    @State var stepBarWidth = deviceFrame.screenWidth * 0.33
    @State var volumes: [Float] = [0.5, 0.5, 0.5]
    
    @Binding var showOnboarding: Bool
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // MARK: - General Properties
    let baseAudioManager = AudioManager()
    let melodyAudioManager = AudioManager()
    let whiteNoiseAudioManager = AudioManager()

    var items = ["BASE", "MELODY", "WHITE NOISE"]

    // MARK: - Life Cycles
    var body: some View {
        NavigationView {
            ZStack {
                Color.relaxBlack.ignoresSafeArea()

                VStack {
                    Spacer()
                    HStack{
                        OnboardingStepBar()
                        Spacer()
                    }

                    HStack {
                        HStack {
                            VStack(alignment: .leading) {

                                HStack {
                                    let text: String = "Please select \n\(items[select])"
                                    Text(LocalizedStringKey(text))
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                }.fixedSize()
                            }

                            Spacer()
                        }
                        .padding()

                        Spacer()

                        MixButton()
                            .padding()
                    }.padding(.horizontal)

                    CDCoverImageView(selectedImageNames: selectedImageNames)
                        .addWhiteBackground()
                        .DeviceFrame()

                    CustomSegmentControlView(items: items, selection: $select)


                    switch select {
                    case 1:
                        SoundSelectView(sectionTitle: "Melody",
                                        soundType: .melody)
                        .onAppear() {
                            withAnimation(.default) {
                                stepBarWidth = deviceFrame.screenWidth * 0.66
                            }
                        }

                    case 2:
                        SoundSelectView(sectionTitle: "WhiteNoise Sound",
                                        soundType: .whiteNoise)
                        .onAppear() {
                            withAnimation(.default) {
                                stepBarWidth = deviceFrame.screenWidth * 0.95
                            }
                        }

                    default:
                        SoundSelectView(sectionTitle: "Base Sound",
                                        soundType: .base)
                        .onAppear() {
                            withAnimation(.default) {
                                stepBarWidth = deviceFrame.screenWidth * 0.33
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
            }
        }
    }
}

// MARK: - ViewBuilder
extension OnboardingView {
    @ViewBuilder
    func SoundSelectView(sectionTitle: String,
                         soundType: SoundType) -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "speaker.wave.1.fill")
                    .frame(width: 18.0, height: 18.0)
                    .foregroundColor(.white)
                
                VolumeSlider(value: $volumes[select], range: (0, 1), knobWidth: 14) { modifiers in
                  ZStack {
                    Color.white.cornerRadius(3).frame(height: 2).modifier(modifiers.barLeft)
                    Color.white.opacity(0.4).cornerRadius(3).frame(height: 2).modifier(modifiers.barRight)
                    ZStack {
                      Circle().fill(Color.white)
                    }.modifier(modifiers.knob)
                  }
                }
                .frame(height: 25)
                .onChange(of: volumes[0]) { volume in
                    selectedBaseSound.audioVolume = volume
                    baseAudioManager.changeVolume(track: selectedBaseSound.fileName, volume: volume)
                }
                .onChange(of: volumes[1]) { volume in
                    selectedMelodySound.audioVolume = volume
                    melodyAudioManager.changeVolume(track: selectedMelodySound.fileName, volume: volume)
                }
                .onChange(of: volumes[2]) { volume in
                    selectedWhiteNoiseSound.audioVolume = volume
                    whiteNoiseAudioManager.changeVolume(track: selectedWhiteNoiseSound.fileName, volume: volume)
                }
                
                Text("\(Int(volumes[select] * 100))")
                    .font(.body)
                    .foregroundColor(.systemGrey1)
                    .frame(maxWidth: 30)
            }.padding([.horizontal])
            
            ScrollView(.vertical,
                       showsIndicators: false) {
                HStack(spacing: 30) {
                    switch soundType {
                    case .base:
                        RadioButtonGroupView(selectedId: soundType.rawValue,
                                             items: SoundType.base.soundList) { baseSelected in
                            selectedBaseSound = baseSelected
                            // play music
                            
                            if selectedBaseSound.name == "Empty" {
                                baseAudioManager.stop()

                                opacityAnimationValues[0] = 0.0
                            } else {
                                baseAudioManager.startPlayer(track: selectedBaseSound.fileName)

                                opacityAnimationValues[0] = 1.0
                            }
                            selectedImageNames.base = selectedBaseSound.fileName
                        }

                    case .whiteNoise:
                        RadioButtonGroupView(selectedId: soundType.rawValue,
                                             items: SoundType.whiteNoise.soundList) { whiteNoiseSounds in
                            selectedWhiteNoiseSound = whiteNoiseSounds

                            if selectedWhiteNoiseSound.name == "Empty" {
                                whiteNoiseAudioManager.stop()

                                opacityAnimationValues[2] = 0.0
                            } else {
                                whiteNoiseAudioManager.startPlayer(track: selectedWhiteNoiseSound.fileName)
                                opacityAnimationValues[2] = 1.0
                            }
                            selectedImageNames.whiteNoise = selectedWhiteNoiseSound.fileName
                        }
                    case .melody:
                        RadioButtonGroupView(selectedId: soundType.rawValue,
                                             items: SoundType.melody.soundList) { melodySounds in
                            selectedMelodySound = melodySounds

                            if selectedMelodySound.name == "Empty" {
                                melodyAudioManager.stop()

                                opacityAnimationValues[1] = 0.0
                            } else {
                                melodyAudioManager.startPlayer(track: selectedMelodySound.fileName)
                                opacityAnimationValues[1] = 1.0

                            }
                            selectedImageNames.melody = selectedMelodySound.fileName
                        }
                    }
                }
            }.padding(.horizontal, 15)
        }
    }

    @ViewBuilder
    func MixButton() -> some View {
        NavigationLink {
            let mixedSound = MixedSound(name: "",
                                        baseSound: selectedBaseSound,
                                        melodySound: selectedMelodySound,
                                        whiteNoiseSound: selectedWhiteNoiseSound,
                                        fileName: recipeRandomName.randomElement()!)
            CDNamingView(goToPreviousView: $showOnboarding,
                         mixedSound: mixedSound,
                         previousView: .onboarding)
    } label: {
            Text("Mix")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor( ($selectedBaseSound.id == 0 || $selectedMelodySound.id == 10 || $selectedWhiteNoiseSound.id == 20) ? Color.gray : Color.relaxDimPurple )
        }
        .opacity(($selectedBaseSound.id == 0 || $selectedMelodySound.id == 10 || $selectedWhiteNoiseSound.id == 20) ? 0 : 1)
        .simultaneousGesture(TapGesture().onEnded { _ in
            baseSound = selectedBaseSound
            melodySound = selectedMelodySound
            whiteNoiseSound = selectedWhiteNoiseSound

            baseAudioManager.stop()
            melodyAudioManager.stop()
            whiteNoiseAudioManager.stop()
            self.textEntered = ""
        })
    }

    @ViewBuilder
    func OnboardingStepBar() -> some View {
        Rectangle()
            .frame(width: stepBarWidth, height: 3)
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.relaxNightBlue, Color.relaxLavender]), startPoint: .leading, endPoint: .trailing))
    }
}
