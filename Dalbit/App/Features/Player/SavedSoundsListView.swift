//
//  SavedSoundsListView.swift
//  Dalbit
//
//  보관함 — 달에서 아래로 스와이프하면 나오는, 저장한 소리 목록.
//

import SwiftUI

struct SavedSoundsListView: View {
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var showCreateView = false
    @State private var showSubscription = false
    @State private var editingSound: CustomSound? = nil
    @State private var showEditView = false
    @State private var showSettings = false
    /// 페이저에 임베드될 때 닫기(홈으로) 콜백. nil이면 일반 네비게이션 화면으로 동작.
    var onClose: (() -> Void)? = nil
    /// 세그먼트 페이저에 콘텐츠만 임베드되는 모드. 헤더/네비게이션 크롬을 숨기고, 추가(+)는 상위가 담당한다.
    var embedded: Bool = false
    /// embedded 모드에서 '새 사운드 만들기' 요청을 상위로 전달.
    var onRequestCreate: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // 배경 없음(투명) — 상위 ListenListView의 공유 우주 별 배경(Starfield·CosmicEvents)이
            // 그대로 비치도록 한다. 홈 페이지와 동일하게 별이 움직이는 배경을 공유한다.
            VStack(spacing: 0) {
                // 무료 사용자에게 항상 보이는 프리미엄 진입 배지 (페이월 접근성 + 심사자 발견성)
                if !subscriptionManager.isPremium {
                    premiumBadge()
                }

                if viewModel.customSounds.isEmpty {
                    emptyStateView()
                } else {
                    soundsListView()
                }
            }
        }
        // 임베드 모드: 중첩 NavigationStack 대신 상단에 커스텀 헤더(닫기+제목+추가)를 둔다.
        // 세그먼트 페이저(embedded)에서는 상위가 헤더/세그먼트를 그리므로 자체 크롬을 숨긴다.
        // 상단 바 — 제목 줄과 검색을 함께 고정한다. 목록을 아무리 내려도 검색은 늘 손 닿는 자리에.
        .safeAreaInset(edge: .top) { topBar() }
        .navigationTitle(onClose == nil && !embedded ? L.Listen.savedSounds.localized : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 제목이 잘리지 않도록 우측에는 컴팩트한 '+' 버튼 하나만 둔다. (일반 모드에서만)
            if onClose == nil && !embedded {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { createTapped() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(DS.Colors.accent)
                    }
                    .accessibilityLabel(L.A11y.createNewButton.localized)
                }
            }
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }
        .navigationDestination(isPresented: $showCreateView) {
            SoundStudioView()
                .environmentObject(viewModel)
                .onDisappear {
                    viewModel.loadSound()
                    print("🔄 [SavedSoundsListView] 리스트 새로고침 - 저장된 사운드 개수: \(viewModel.customSounds.count)")
                }
        }
        .navigationDestination(isPresented: $showEditView) {
            if let editing = editingSound {
                SoundDetailView(
                    isTutorial: false,
                    originalSound: OriginalSound(
                        name: editing.category.displayName,
                        filter: editing.filter,
                        category: editing.category
                    ),
                    editingSound: editing
                )
                .environmentObject(viewModel)
                .onDisappear { viewModel.loadSound() }
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            viewModel.loadSound()
            viewModel.loadPresetSounds() // 프리셋 사운드 로드
            print("📋 [SavedSoundsListView] 저장된 사운드 개수: \(viewModel.customSounds.count)")
        }
    }

    // MARK: - Premium Badge (페이월 진입)
    @ViewBuilder
    private func premiumBadge() -> some View {
        Button { showSubscription = true } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.Colors.warm)
                Text(L.Subscription.upgradeBadge.localized)
                    .font(DS.Font.subhead().weight(.semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.accentSoft)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.xs)
        .accessibilityLabel(L.Subscription.upgradeBadge.localized)
    }

    // 새 사운드 만들기 (무료 한도 체크)
    private func createTapped() {
        let userCount = viewModel.customSounds.filter { !$0.isPreset }.count
        if subscriptionManager.canCreateMoreSounds(currentCount: userCount) {
            showCreateView = true
        } else {
            showSubscription = true
        }
    }

    // MARK: - Top Bar (제목 줄 + 검색)

    /// 상단 바 전체. 재질은 **여기 한 번만** 깔고, 안쪽 줄들은 투명하게 둔다 —
    /// 줄마다 재질을 겹치면 경계가 층져 보인다.
    @ViewBuilder
    private func topBar() -> some View {
        VStack(spacing: 0) {
            if let onClose, !embedded {
                embeddedHeader(onClose: onClose)
            }
            // 검색은 찾을 게 있을 때만. 빈 보관함에 검색창부터 내미는 건 무례하다.
            if !viewModel.customSounds.isEmpty {
                searchBar()
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.bottom, DS.Spacing.xs)
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Embedded Header (페이저용 상단 바)
    @ViewBuilder
    private func embeddedHeader(onClose: @escaping () -> Void) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.Common.close.localized)

            Spacer()

            Text(L.Listen.savedSounds.localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Button(action: createTapped) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.A11y.createNewButton.localized)

            // 설정 (효과음 끄기·즐겨찾기만 재생·피드백·앱 정보)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.Settings.title.localized)
        }
        .padding(.horizontal, DS.Spacing.sm)
    }

    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: DS.Spacing.xl) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(DS.Colors.accent.opacity(0.5))
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.xs) {
                Text(L.Listen.noSavedSounds.localized)
                    .font(DS.Font.title())
                    .foregroundColor(DS.Colors.textPrimary)

                Text(L.Listen.createFirstSound.localized)
                    .font(DS.Font.callout())
                    .foregroundColor(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if embedded { onRequestCreate?() } else { showCreateView = true }
            } label: {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text(L.Listen.newSoundCreate.localized)
                }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            .padding(.top, DS.Spacing.xs)
        }
        .padding(.horizontal, DS.Spacing.xxl)
    }

    // MARK: - Sounds List (네이티브 List + 스와이프: 삭제/즐겨찾기)
    private func soundsListView() -> some View {
        VStack(spacing: 0) {
            // 검색은 상단 바(topBar)로 올라갔다 — 목록을 내려도 고정된다.
            List {
                if searchText.isEmpty {
                    ForEach(PresetCategory.allCases, id: \.self) { category in
                        if let presets = groupedPresets[category], !presets.isEmpty {
                            Section(category.displayName) {
                                ForEach(presets) { soundRow($0) }
                            }
                        }
                    }
                    if !myCreatedSounds.isEmpty {
                        // 무료 카운터를 여기로 옮겼다 — 세는 대상이 "내가 만든 사운드"라
                        // 그 섹션 옆에 있어야 무엇의 개수인지 바로 읽힌다.
                        Section {
                            ForEach(myCreatedSounds) { soundRow($0) }
                        } header: {
                            HStack {
                                Text(L.Listen.mySounds.localized)
                                Spacer()
                                freeCountLabel()
                            }
                        }
                    }
                } else {
                    Section {
                        if filteredSounds.isEmpty {
                            Text(L.Listen.noSearchResults.localized)
                                .font(DS.Font.callout())
                                .foregroundColor(DS.Colors.textSecondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(filteredSounds) { soundRow($0) }
                        }
                    } header: {
                        HStack {
                            Text(L.Listen.searchResults.localized)
                            Spacer()
                            // 몇 개가 걸렸는지 — 없을 때만이 아니라 있을 때도 알려 준다.
                            if !filteredSounds.isEmpty {
                                Text(String(format: L.Listen.searchResultCount.localized, filteredSounds.count))
                                    .foregroundColor(DS.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // 목록을 밀면 키보드가 내려간다 — 검색 결과를 보려는 동작과 자연스럽게 이어진다.
            .scrollDismissesKeyboard(.immediately)
        }
    }

    /// 무료 사용자에게만 보이는 "내 사운드 N / 3". 한도에 닿으면 색으로 알린다.
    @ViewBuilder
    private func freeCountLabel() -> some View {
        if !subscriptionManager.isPremium {
            let userCount = viewModel.customSounds.filter { !$0.isPreset }.count
            let reached = userCount >= SubscriptionManager.freeMaxCustomSounds
            Text(String(format: L.SoundList.freeCount.localized,
                        userCount, SubscriptionManager.freeMaxCustomSounds))
                .foregroundColor(reached ? DS.Colors.warm : DS.Colors.textTertiary)
        }
    }

    /// 프리셋을 카테고리별로 그룹화
    private var groupedPresets: [PresetCategory: [CustomSound]] {
        Dictionary(grouping: viewModel.presetSounds) { preset in
            PresetSound.allPresets.first(where: { $0.localizedName == preset.title })?.category ?? .sleep
        }
    }

    // MARK: - Sound Row (이름만 — 삭제/즐겨찾기는 스와이프)
    @ViewBuilder
    private func soundRow(_ sound: CustomSound) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(sound.title)
                .font(DS.Font.callout())
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
            if sound.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(DS.Colors.warm)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { selectSound(sound) }
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(soundCardAccessibilityLabel(sound))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L.A11y.playSoundHint.localized)
        .accessibilityAction(named: Text(L.A11y.favorite.localized)) { viewModel.toggleFavorite(sound) }
        .accessibilityAction(named: Text(L.Common.delete.localized)) { if !sound.isPreset { deleteSound(sound) } }
        // 왼쪽으로 밀기 → 즐겨찾기
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { viewModel.toggleFavorite(sound) } label: {
                Label(L.A11y.favorite.localized, systemImage: sound.isFavorite ? "star.slash.fill" : "star.fill")
            }
            .tint(DS.Colors.warm)
        }
        // 오른쪽으로 밀기 → 삭제(내 사운드만) + 편집
        .swipeActions(edge: .trailing, allowsFullSwipe: !sound.isPreset) {
            if !sound.isPreset {
                Button(role: .destructive) { deleteSound(sound) } label: {
                    Label(L.Common.delete.localized, systemImage: "trash")
                }
                Button { startEdit(sound) } label: {
                    Label(L.Common.edit.localized, systemImage: "slider.horizontal.3")
                }
                .tint(DS.Colors.accent)
            }
        }
    }

    // MARK: - Search Bar

    /// 검색 필드.
    ///
    /// ⚠️ 여기에 `.padding(.horizontal)` 을 걸지 않는다 — 감싸는 쪽이 이미 화면 여백을 준다.
    ///    예전엔 양쪽에서 한 번씩 줘서 검색창만 다른 요소보다 24pt 더 들어가 있었고,
    ///    그래서 이 줄만 화면에서 떠 보였다.
    @ViewBuilder
    private func searchBar() -> some View {
        HStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    // 입력 중이면 아이콘도 같이 살아난다 — 지금 어디에 타이핑되는지가 분명해진다.
                    .foregroundColor(isSearchFocused ? DS.Colors.accent : DS.Colors.textTertiary)
                    .accessibilityHidden(true)

                TextField(L.Listen.soundSearch.localized, text: $searchText)
                    .focused($isSearchFocused)
                    .foregroundColor(DS.Colors.textPrimary)
                    .font(DS.Font.body())
                    .tint(DS.Colors.accent)
                    // 소리 제목은 사람이 지은 이름이라 자동수정·대문자화가 오히려 방해가 된다.
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { isSearchFocused = false }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(DS.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.A11y.clearSearch.localized)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            // 캡슐 + 유리 — iOS 검색 필드의 생김새를 따른다. 사각형 판이면 그냥 입력창으로 읽힌다.
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(isSearchFocused ? DS.Colors.accent.opacity(0.55)
                                                          : Color.white.opacity(0.10),
                                          lineWidth: 1)
                    )
            }

            // 입력 중일 때만 나오는 취소 — iOS 검색의 관례이자, 키보드를 닫는 확실한 출구다.
            if isSearchFocused || !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearchFocused = false
                } label: {
                    Text(L.Common.cancel.localized)
                        .font(DS.Font.callout())
                        .foregroundColor(DS.Colors.accent)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: isSearchFocused)
        .animation(.easeOut(duration: 0.18), value: searchText.isEmpty)
    }

    // MARK: - Computed Properties
    private var filteredSounds: [CustomSound] {
        if searchText.isEmpty {
            return viewModel.customSounds
        } else {
            return viewModel.customSounds.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    /// 사용자가 직접 만든 사운드 (프리셋 제외)
    private var myCreatedSounds: [CustomSound] {
        viewModel.customSounds.filter { !$0.isPreset }
    }

    // MARK: - Actions
    private func selectSound(_ sound: CustomSound) {
        print("🎵 [SavedSoundsListView] 사운드 선택: \(sound.title)")
        viewModel.selectedSound = sound
        viewModel.play(with: sound)
        dismiss()
    }

    /// 사운드 수정 화면으로 이동
    private func startEdit(_ sound: CustomSound) {
        if viewModel.isPlaying { viewModel.stopSound() }
        editingSound = sound
        showEditView = true
    }

    /// 사운드 삭제 (내가 만든 사운드만)
    private func deleteSound(_ sound: CustomSound) {
        guard let index = viewModel.customSounds.firstIndex(where: { $0.id == sound.id }) else { return }
        viewModel.remove(at: index)
    }

    /// 카드에 길게 눌러 수정/삭제하는 컨텍스트 메뉴 (내가 만든 사운드 전용)
    @ViewBuilder
    private func cardContextMenu(for sound: CustomSound) -> some View {
        if !sound.isPreset {
            Button {
                startEdit(sound)
            } label: {
                Label(L.Common.edit.localized, systemImage: "slider.horizontal.3")
            }
            Button(role: .destructive) {
                deleteSound(sound)
            } label: {
                Label(L.Common.delete.localized, systemImage: "trash")
            }
        }
    }

    // MARK: - Accessibility
    /// 사운드 카드를 VoiceOver에서 읽어줄 라벨 (제목, 카테고리, 즐겨찾기 상태)
    private func soundCardAccessibilityLabel(_ sound: CustomSound) -> String {
        var parts = [sound.title, sound.category.displayName]
        if sound.isFavorite { parts.append(L.A11y.favoriteOn.localized) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Recommendation Card View
struct RecommendationCard: View {
    let sound: CustomSound

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // 상단 아이콘 영역
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: sound.color).opacity(0.55),
                                Color(hex: sound.color).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                if sound.isLayeredSound {
                    SoundThumbnailView(sound: sound, size: 32)
                } else {
                    Image(sound.category.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
            }

            // 사운드 정보
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(sound.title)
                    .font(DS.Font.subhead().weight(.semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "waveform")
                        .font(.system(size: 9))
                    Text(sound.category.displayName)
                        .font(DS.Font.caption())
                }
                .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .frame(width: 150, alignment: .leading)
        .dsCard(padding: DS.Spacing.md, radius: DS.Radius.md)
    }
}


// MARK: - Gesture Coachmark (첫 실행 1회 제스처 안내)
