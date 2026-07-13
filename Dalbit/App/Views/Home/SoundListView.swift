//
//  SoundListView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/07.
//

import SwiftUI
import Combine

/**
 앱에 저장된 Original Sound 정보들이 그리드 뷰 형태의 리스트로 나열된 Main View
 */
struct SoundListView: View {

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var searchText = ""
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.DefaultBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading) {
                    HStack {
                        Text(L.SoundList.title.localized)
                            .foregroundColor(Color(.TitleText))
                            .font(.system(size: 24, weight: .bold))

                        Spacer()

                        // 새 사운드 만들기 버튼
                        NavigationLink(destination: CreateNewSoundView().environmentObject(viewModel)) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                Text(L.SoundList.createNew.localized)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.PrimaryPurple))
                            .cornerRadius(8)
                        }

                        // 샘플 데이터 생성 버튼
                        Button(action: {
                            viewModel.createSampleData()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 14))
                                Text(L.SoundList.sample.localized)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.PrimaryPurple).opacity(0.7))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)

                    SearchBar(text: $searchText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 추천 프리셋 섹션
                            if searchText.isEmpty {
                                recommendedSection()
                            }

                            // 기존 사운드 그리드
                            gridView()
                        }
                    }
                }

                .navigationDestination(
                    isPresented: $appState.showSoundDetail) {
                        SoundDetailView(isTutorial: false, originalSound: OriginalSound(name: AudioFilter.WaterDrop.displayName, filter: .WaterDrop, category: .WaterDrop))
                    }
            }
        }

    }

    @ViewBuilder
    private func recommendedSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(.PrimaryPurple))
                    .font(.system(size: 16))
                Text(L.SoundList.recommended.localized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.TitleText))
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Preset.recommended) { preset in
                        NavigationLink(destination: presetDetailView(preset: preset)) {
                            presetCard(preset: preset)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func presetCard(preset: Preset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(preset.category.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 100)
                .background(Color(hex: preset.color))
                .cornerRadius(8)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(preset.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.Text))
                    .lineLimit(1)

                Text(preset.description)
                    .font(.system(size: 11))
                    .foregroundColor(Color(.Text).opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 140)
        }
        .frame(width: 140)
    }

    @ViewBuilder
    private func presetDetailView(preset: Preset) -> some View {
        SoundDetailView(
            isTutorial: false,
            originalSound: preset.toOriginalSound(),
            presetVariation: preset.audioVariation
        )
    }

    @ViewBuilder
    private func gridView() -> some View {

        VStack(alignment: .leading, spacing: 12) {
            Text(L.SoundList.originalSounds.localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(.TitleText))
                .padding(.horizontal, 24)

            LazyVGrid(columns: columns) {
                ForEach(filteredSounds(), id: \.self) { originalSound in
                    let isLocked = subscriptionManager.isCategoryLocked(originalSound.category)
                    if isLocked {
                        Button(action: { showSubscription = true }) {
                            gridViewItem(originalSound, locked: true)
                        }
                    } else {
                        NavigationLink(destination: SoundDetailView(isTutorial: false, originalSound: originalSound)) {
                            gridViewItem(originalSound, locked: false)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }
    }

    @ViewBuilder
    private func gridViewItem(_ originalSound: OriginalSound, locked: Bool = false) -> some View {

        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {

                Text(originalSound.category.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.Text))

                Image(originalSound.category.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 140)
                    .background(Color(hex: originalSound.color))
                    .cornerRadius(8)
            }
            .opacity(locked ? 0.5 : 1.0)

            if locked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Premium")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .cornerRadius(6)
                .padding(6)
            }
        }
    }

    private func filteredSounds() -> [OriginalSound] {
        if searchText.isEmpty {
            return SoundListView.originalSounds
        } else {
            return SoundListView.originalSounds.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct SoundListView_Previews: PreviewProvider {
    static var previews: some View {
        SoundListView()
    }
}
