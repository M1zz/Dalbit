//
//  LocalizationKeys.swift
//  Dalbit
//
//  Type-safe localization keys for internationalization
//

import Foundation

/// Type-safe localization keys organized by feature
enum L {

    // MARK: - Sound List
    enum SoundList {
        static let freeCount = "sound_list.free_count"
    }

    // MARK: - Create Sound
    enum CreateSound {
        static let enterSoundName = "create_sound.enter_sound_name"
        static let originalSounds = "create_sound.original_sounds"
        static let backgroundMusicVolume = "create_sound.background_music_volume"
    }

    // MARK: - Common
    enum Common {
        static let save = "common.save"
        static let cancel = "common.cancel"
        static let edit = "common.edit"
        static let delete = "common.delete"
        static let done = "common.done"
        static let close = "common.close"
        static let next = "common.next"
        static let on = "common.on"
        static let off = "common.off"
        static let loading = "common.loading"
    }

    // MARK: - Library (보관함)
    enum Library {
        static let effectsToggle = "library.effects_toggle"
        static let effectsToggleHint = "library.effects_toggle_hint"
        static let favoritesOnly = "library.favorites_only"
        static let favoritesOnlyHint = "library.favorites_only_hint"
        static let favoritesOnlyEmpty = "library.favorites_only_empty"
    }

    // MARK: - Tips (TipKit 안내)
    enum Tip {
        static let effectsOffTitle = "tip.effects_off.title"
        static let effectsOffMessage = "tip.effects_off.message"
        static let openLibrary = "tip.open_library"
        static let favoriteLongPressTitle = "tip.favorite_longpress.title"
        static let favoriteLongPressMessage = "tip.favorite_longpress.message"
    }

    // MARK: - Alert
    enum Alert {
        static let soundName = "alert.sound_name"
        static let enterName = "alert.enter_name"
        static let saveFailed = "alert.save_failed"
    }

    // MARK: - Category
    enum Category {
        static let none = "category.none"
        static let waterdrop = "category.waterdrop"
        static let singingBowl = "category.singing_bowl"
        static let bird = "category.bird"
        static let rain = "category.rain"
        static let ambient = "category.ambient"
        static let asmr = "category.asmr"
    }

    // MARK: - Filter
    enum Filter {
        // WaterDrop
        static let waterdrop = "filter.waterdrop"
        static let basement = "filter.basement"
        static let cave = "filter.cave"
        static let pipe = "filter.pipe"
        static let sink = "filter.sink"
        // SingingBowl
        static let singingBowl = "filter.singing_bowl"
        static let focus = "filter.focus"
        static let training = "filter.training"
        static let empty = "filter.empty"
        static let vibration = "filter.vibration"
        static let tibetanBowl = "filter.tibetan_bowl"
        static let bell = "filter.bell"
        static let bowlDeep = "filter.bowl_deep"
        static let bowlLoud = "filter.bowl_loud"
        // Bird
        static let bird = "filter.bird"
        static let owl = "filter.owl"
        static let woodpecker = "filter.woodpecker"
        static let forest = "filter.forest"
        static let cuckoo = "filter.cuckoo"
        static let jungle = "filter.jungle"
        static let forestBird = "filter.forest_bird"
        static let springForest = "filter.spring_forest"
        // Rain
        static let softRain = "filter.soft_rain"
        static let cityRain = "filter.city_rain"
        static let rainMaker = "filter.rain_maker"
        // Ambient
        static let ambientKeys = "filter.ambient_keys"
        static let underwater = "filter.underwater"
        static let meditationPad = "filter.meditation_pad"
        static let atmosphere = "filter.atmosphere"
        static let indigoMusic = "filter.indigo_music"
        // ASMR
        static let keyboard = "filter.keyboard"
        static let camera = "filter.camera"
        static let airShimmer = "filter.air_shimmer"
        static let sparkleBells = "filter.sparkle_bells"
    }

    // MARK: - Background Sound
    enum Background {
        static let wave = "background.wave"
        static let rain = "background.rain"
        static let tv = "background.tv"
        static let piano = "background.piano"
        static let guitar = "background.guitar"
        static let ambient = "background.ambient"
        static let lofi = "background.lofi"
        static let meditation = "background.meditation"
    }

    // MARK: - Customization
    enum Customize {
        static let volume = "customize.volume"
        static let seconds = "customize.seconds"
        // 무드 프리셋 개편
        static let shapeSound = "customize.shape_sound"
        static let pickFeel = "customize.pick_feel"
        static let soundType = "customize.sound_type"
        static let moodCalm = "customize.mood_calm"
        static let moodClear = "customize.mood_clear"
        static let moodDeep = "customize.mood_deep"
        static let moodCozy = "customize.mood_cozy"
        static let moodLively = "customize.mood_lively"
        static let moodNatural = "customize.mood_natural"
    }

    // MARK: - Tab
    enum Tab {
        static let listen = "tab.listen"
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let start = "onboarding.start"
        static let skip = "onboarding.skip"
        static let next = "onboarding.next"

        /// 페이지 한 장 = 제목 + 본문. 순서는 Page.allCases 가 정한다.
        enum Page1 {
            static let title = "onboarding.p1.title"
            static let body = "onboarding.p1.body"
        }
        enum Page2 {
            static let title = "onboarding.p2.title"
            static let body = "onboarding.p2.body"
        }
        enum Page3 {
            static let title = "onboarding.p3.title"
            static let body = "onboarding.p3.body"
        }
        enum Page4 {
            static let title = "onboarding.p4.title"
            static let body = "onboarding.p4.body"
        }
    }

    // MARK: - About (달빛 이야기 — 효용과 만든 이의 노트)
    enum About {
        static let entry = "about.entry"
        static let entryHint = "about.entry_hint"
        static let title = "about.title"

        static let whyTitle = "about.why_title"
        static let whyBody = "about.why_body"
        static let valueTitle = "about.value_title"
        static let valueBody = "about.value_body"

        static let craftTitle = "about.craft_title"
        enum Craft {
            static let breathTitle = "about.craft_breath_title"
            static let breathBody = "about.craft_breath_body"
            static let fadeTitle = "about.craft_fade_title"
            static let fadeBody = "about.craft_fade_body"
            static let sleepTitle = "about.craft_sleep_title"
            static let sleepBody = "about.craft_sleep_body"
            static let nightTitle = "about.craft_night_title"
            static let nightBody = "about.craft_night_body"
            static let moonTitle = "about.craft_moon_title"
            static let moonBody = "about.craft_moon_body"
            static let privacyTitle = "about.craft_privacy_title"
            static let privacyBody = "about.craft_privacy_body"
        }

        static let replayTitle = "about.replay_title"
        static let replayOnboarding = "about.replay_onboarding"
        static let replayGestures = "about.replay_gestures"
        static let replayDone = "about.replay_done"
    }

    // MARK: - Listen View
    enum Listen {
        static let selectSoundToPlay = "listen.select_sound_to_play"
        static let savedSounds = "listen.saved_sounds"
        static let noSavedSounds = "listen.no_saved_sounds"
        static let createFirstSound = "listen.create_first_sound"
        static let newSoundCreate = "listen.new_sound_create"
        static let mySounds = "listen.my_sounds"
        static let searchResults = "listen.search_results"
        static let searchResultCount = "listen.search_result_count"   // %lld = 찾은 개수
        static let noSearchResults = "listen.no_search_results"
        static let soundSearch = "listen.sound_search"
        static let recommendationMorning = "listen.recommendation_morning"
        static let recommendationFocus = "listen.recommendation_focus"
        static let recommendationEvening = "listen.recommendation_evening"
        static let recommendationSleep = "listen.recommendation_sleep"
        static let swipeHint = "listen.swipe_hint"
        static let campfire = "listen.campfire"
        static let campfireDescription = "listen.campfire_description"
        static let rainSound = "listen.rain_sound"
        static let rainSoundDescription = "listen.rain_sound_description"
        static let heavyRain = "listen.heavy_rain"
        static let heavyRainDescription = "listen.heavy_rain_description"
        static let favoriteOn = "listen.favorite_on"
        static let favoriteOff = "listen.favorite_off"

        /// 첫 실행 1회 제스처 안내
        enum Coachmark {
            static let title = "listen.coachmark.title"
            static let tap = "listen.coachmark.tap"
            static let swipeSide = "listen.coachmark.swipe_side"
            static let swipeUp = "listen.coachmark.swipe_up"
            static let swipeDown = "listen.coachmark.swipe_down"
        }
    }

    // MARK: - Timer
    enum Timer {
        static let sleepTimer = "timer.sleep_timer"
        static let forGoodSleep = "timer.for_good_sleep"
        static let autoStopDescription = "timer.auto_stop_description"
        static let startTimer = "timer.start_timer"
        static let remainingTime = "timer.remaining_time"
        static let stop = "timer.stop"
        static let pause = "timer.pause"
        static let resume = "timer.resume"
        static let hours = "timer.hours"
        static let minutes = "timer.minutes"
        static let hour = "timer.hour"
        static let minute = "timer.minute"
        static let second = "timer.second"
    }

    // MARK: - Player
    enum Player {
        static let spatialAudio = "player.spatial_audio"
        static let positionAdjust = "player.position_adjust"
        static let layerFormat = "player.layer_format"
        static let distance = "player.distance"
        static let angle = "player.angle"
        static let height = "player.height"
        static let spatialAudioEnabled = "player.spatial_audio_enabled"
    }

    // MARK: - Sample Sounds
    enum Sample {
        static let morningMeditation = "sample.morning_meditation"
        static let focusTime = "sample.focus_time"
        static let sleepHelper = "sample.sleep_helper"
        static let rainFeeling = "sample.rain_feeling"
        static let calmNight = "sample.calm_night"
        static let caveWater = "sample.cave_water"
        static let meditationBell = "sample.meditation_bell"
        static let dawnBirds = "sample.dawn_birds"
        static let restTime = "sample.rest_time"
        static let natureSound = "sample.nature_sound"
    }

    // MARK: - Preset Sounds (New)
    enum PresetNew {
        enum DeepSleep {
            static let name = "preset_new.deep_sleep.name"
            static let description = "preset_new.deep_sleep.description"
        }
        enum RainSleep {
            static let name = "preset_new.rain_sleep.name"
            static let description = "preset_new.rain_sleep.description"
        }
        enum WhiteNoiseSleep {
            static let name = "preset_new.white_noise_sleep.name"
            static let description = "preset_new.white_noise_sleep.description"
        }
        enum CafeFocus {
            static let name = "preset_new.cafe_focus.name"
            static let description = "preset_new.cafe_focus.description"
        }
        enum DeepFocus {
            static let name = "preset_new.deep_focus.name"
            static let description = "preset_new.deep_focus.description"
        }
        enum StudyTime {
            static let name = "preset_new.study_time.name"
            static let description = "preset_new.study_time.description"
        }
        enum MeditationTime {
            static let name = "preset_new.meditation_time.name"
            static let description = "preset_new.meditation_time.description"
        }
        enum YogaStretching {
            static let name = "preset_new.yoga_stretching.name"
            static let description = "preset_new.yoga_stretching.description"
        }
        enum ForestWalk {
            static let name = "preset_new.forest_walk.name"
            static let description = "preset_new.forest_walk.description"
        }
        enum CaveExplore {
            static let name = "preset_new.cave_explore.name"
            static let description = "preset_new.cave_explore.description"
        }

        // 새 Rain 카테고리
        enum SoftRain {
            static let name = "preset_new.soft_rain.name"
            static let description = "preset_new.soft_rain.description"
        }

        enum CityRain {
            static let name = "preset_new.city_rain.name"
            static let description = "preset_new.city_rain.description"
        }

        // 새 Ambient 카테고리
        enum UnderwaterMeditation {
            static let name = "preset_new.underwater_meditation.name"
            static let description = "preset_new.underwater_meditation.description"
        }

        enum CosmicAtmosphere {
            static let name = "preset_new.cosmic_atmosphere.name"
            static let description = "preset_new.cosmic_atmosphere.description"
        }

        // 새 ASMR 카테고리
        enum TypingFocus {
            static let name = "preset_new.typing_focus.name"
            static let description = "preset_new.typing_focus.description"
        }

        enum CameraASMR {
            static let name = "preset_new.camera_asmr.name"
            static let description = "preset_new.camera_asmr.description"
        }

        // 확장된 SingingBowl
        enum TibetanMeditation {
            static let name = "preset_new.tibetan_meditation.name"
            static let description = "preset_new.tibetan_meditation.description"
        }

        // 확장된 Bird
        enum JungleMorning {
            static let name = "preset_new.jungle_morning.name"
            static let description = "preset_new.jungle_morning.description"
        }

        enum SpringForest {
            static let name = "preset_new.spring_forest.name"
            static let description = "preset_new.spring_forest.description"
        }
    }

    // MARK: - Preset Space (첫 실행 자동재생 · 좌우 굴리기 리스트)
    enum PresetSpace {
        enum Space {
            static let name = "preset_space.space.name"
            static let description = "preset_space.space.description"
        }
        enum Cinematic {
            static let name = "preset_space.space_cinematic.name"
            static let description = "preset_space.space_cinematic.description"
        }
        enum Ambient1 {
            static let name = "preset_space.space_ambient_1.name"
            static let description = "preset_space.space_ambient_1.description"
        }
        enum Deep {
            static let name = "preset_space.space_deep.name"
            static let description = "preset_space.space_deep.description"
        }
        enum Ambient2 {
            static let name = "preset_space.space_ambient_2.name"
            static let description = "preset_space.space_ambient_2.description"
        }
        enum Cinematic2 {
            static let name = "preset_space.space_cinematic_2.name"
            static let description = "preset_space.space_cinematic_2.description"
        }
        enum Shuttle {
            static let name = "preset_space.space_shuttle.name"
            static let description = "preset_space.space_shuttle.description"
        }
        enum Solar {
            static let name = "preset_space.space_solar.name"
            static let description = "preset_space.space_solar.description"
        }
        enum Drift {
            static let name = "preset_space.space_drift.name"
            static let description = "preset_space.space_drift.description"
        }
        enum Cinematic3 {
            static let name = "preset_space.space_cinematic_3.name"
            static let description = "preset_space.space_cinematic_3.description"
        }
        enum Ambient3 {
            static let name = "preset_space.space_ambient_3.name"
            static let description = "preset_space.space_ambient_3.description"
        }
        enum Orbit {
            static let name = "preset_space.space_orbit.name"
            static let description = "preset_space.space_orbit.description"
        }
        enum Void {
            static let name = "preset_space.space_void.name"
            static let description = "preset_space.space_void.description"
        }
    }

    // MARK: - Preset MIDI (순수 미디 음원 · 첫 실행 무료 제공)
    enum PresetMidi {
        enum Piano {
            static let name = "preset_midi.piano.name"
            static let description = "preset_midi.piano.description"
        }
        enum Lofi {
            static let name = "preset_midi.lofi.name"
            static let description = "preset_midi.lofi.description"
        }
        enum Meditation {
            static let name = "preset_midi.meditation.name"
            static let description = "preset_midi.meditation.description"
        }
    }

    // MARK: - Save View
    enum SaveView {
        static let enterOneChar = "save_view.enter_one_char"
        static let duplicateName = "save_view.duplicate_name"
        static let defaultSoundName = "save_view.default_sound_name"
    }

    // MARK: - Subscription
    enum Subscription {
        static let title = "subscription.title"
        static let description = "subscription.description"
        static let subscribe = "subscription.subscribe"
        static let restore = "subscription.restore"
        static let freeTier = "subscription.free_tier"
        static let premiumTier = "subscription.premium_tier"
        static let freeSoundsLimit = "subscription.free_sounds_limit"
        static let freeCategoriesLimit = "subscription.free_categories_limit"
        static let unlimitedSounds = "subscription.unlimited_sounds"
        static let allCategories = "subscription.all_categories"
        static let priceFormat = "subscription.price_format"
        static let error = "subscription.error"
        static let freeTrialWeek = "subscription.free_trial_week"
        static let loadingProducts = "subscription.loading_products"
        static let retry = "subscription.retry"
        static let termsOfUse = "subscription.terms_of_use"
        static let privacyPolicy = "subscription.privacy_policy"
        static let legalNotice = "subscription.legal_notice"
        static let upgradeBadge = "subscription.upgrade_badge"
        static let promoTitle = "subscription.promo_title"
        static let promoPlaceholder = "subscription.promo_placeholder"
        static let promoApply = "subscription.promo_apply"
        static let promoSuccess = "subscription.promo_success"
        static let promoInvalid = "subscription.promo_invalid"
    }

    // MARK: - Preset Categories
    enum PresetCategory {
        static let sleep = "preset_category.sleep"
        static let focus = "preset_category.focus"
        static let meditation = "preset_category.meditation"
        static let nature = "preset_category.nature"
        static let rain = "preset_category.rain"
    }

    // MARK: - Sound Studio (생성 개편)
    enum Studio {
        static let title = "studio.title"
        static let whereHeard = "studio.where_heard"
        static let interval = "studio.interval"
        static let intervalHint = "studio.interval_hint"
        static let space = "studio.space"
    }

    // MARK: - Alarm (알람 시계)
    enum Alarm {
        static let title = "alarm.title"
        static let segmentTimer = "alarm.segment_timer"
        static let myAlarms = "alarm.my_alarms"
        static let add = "alarm.add"
        static let emptyTitle = "alarm.empty_title"
        static let emptyDesc = "alarm.empty_desc"
        static let editTitle = "alarm.edit_title"
        static let delete = "alarm.delete"
        static let repeatTitle = "alarm.repeat"
        static let sound = "alarm.sound"
        static let label = "alarm.label"
        static let labelPlaceholder = "alarm.label_placeholder"
        static let time = "alarm.time"
        static let rowHint = "alarm.row_hint"
        static let repeatOnce = "alarm.repeat_once"
        static let repeatEveryday = "alarm.repeat_everyday"
        static let repeatWeekdays = "alarm.repeat_weekdays"
        static let repeatWeekend = "alarm.repeat_weekend"
        static let summaryOnce = "alarm.summary_once"
        static let summaryEveryday = "alarm.summary_everyday"
        static let summaryWeekdays = "alarm.summary_weekdays"
        static let summaryWeekend = "alarm.summary_weekend"
        static let summaryFormat = "alarm.summary_format"       // %@ = 요일 목록
        static let stop = "alarm.stop"
        static let a11yWeekday = "alarm.a11y_weekday"            // %@ = 요일
        static let a11yRow = "alarm.a11y_row"                    // %1$@ 시각, %2$@ 라벨, %3$@ 반복
        static let soundDefault = "alarm.sound_default"
        static let soundSingingBowl = "alarm.sound_singing_bowl"
        static let soundTibetanBowl = "alarm.sound_tibetan_bowl"
        static let soundBell = "alarm.sound_bell"
        static let soundBirds = "alarm.sound_birds"
        static let soundCuckoo = "alarm.sound_cuckoo"
        static let soundLoudBowl = "alarm.sound_loud_bowl"
    }

    // MARK: - Settings (설정)
    enum Settings {
        static let title = "settings.title"
        static let sectionSound = "settings.section_sound"
        static let sectionDisplay = "settings.section_display"
        static let idleDim = "settings.idle_dim"
        static let idleDimHint = "settings.idle_dim_hint"
        static let sectionSupport = "settings.section_support"
        static let sectionAbout = "settings.section_about"
        static let version = "settings.version"
    }

    // MARK: - Feedback (사용자 의견 보내기)
    enum Feedback {
        static let entry = "feedback.entry"
        static let entryHint = "feedback.entry_hint"
    }

    // MARK: - Accessibility (VoiceOver)
    enum A11y {
        static let savedSoundsButton = "a11y.saved_sounds_button"
        static let timerButton = "a11y.timer_button"
        static let timerActiveValue = "a11y.timer_active_value"          // %@ = 남은 시간
        static let play = "a11y.play"
        static let pause = "a11y.pause"
        static let closeButton = "a11y.close_button"
        static let backButton = "a11y.back_button"
        static let clearSearch = "a11y.clear_search"
        static let openFullPlayerHint = "a11y.open_full_player_hint"
        static let playSoundHint = "a11y.play_sound_hint"
        static let favorite = "a11y.favorite"
        static let favoriteOn = "a11y.favorite_on"
        static let createNewButton = "a11y.create_new_button"
        static let hoursPicker = "a11y.hours_picker"
        static let minutesPicker = "a11y.minutes_picker"
        static let remainingTimeLabel = "a11y.remaining_time_label"
        static let previousSound = "a11y.previous_sound"
        static let nextSound = "a11y.next_sound"
        static let removeLayer = "a11y.remove_layer"
        static let distanceSlider = "a11y.distance_slider"
        static let angleSlider = "a11y.angle_slider"
        static let heightSlider = "a11y.height_slider"
        static let changeColor = "a11y.change_color"
    }

    // MARK: - Recap (나의 기록 — 사용자가 자기 청취 기록을 보는 화면)
    enum Recap {
        static let entry = "recap.entry"
        static let entryHint = "recap.entry_hint"
        static let title = "recap.title"
        static let total = "recap.total"
        static let empty = "recap.empty"
        static let streak = "recap.streak"
        static let activeDays = "recap.active_days"
        static let slept = "recap.slept"
        static let longest = "recap.longest"
        static let night = "recap.night"
        static let daysFormat = "recap.days_format"          // %lld = 일수
        static let timesFormat = "recap.times_format"        // %lld = 횟수
        static let estimateNote = "recap.estimate_note"
        static let localNote = "recap.local_note"
        static let feedbackTitle = "recap.feedback_title"
        static let feedbackBody = "recap.feedback_body"
    }

    // MARK: - Usage Stats (개발자 통계 화면)
    //
    // ⚠️ 개발자만 보는 화면이지만 지역화한다 — 앱 안에서 언어가 섞이지 않게 하려는 것이고,
    //    앞으로 이 화면을 다른 사람에게 보여 줄 여지도 남긴다.
    enum Stats {
        static let title = "stats.title"
        static let entry = "stats.entry"
        static let entryHint = "stats.entry_hint"
        static let loadFailFormat = "stats.load_fail_format"        // %@ = 실패한 항목들
        static let sourceSnapshots = "stats.source_snapshots"
        static let sourceEvents = "stats.source_events"
        static let sourceFeedback = "stats.source_feedback"
        static let permissionHint = "stats.permission_hint"

        static let deviceTitle = "stats.device_title"
        static let deviceNote = "stats.device_note"
        static let lastSnapshot = "stats.last_snapshot"
        static let lastSnapshotNone = "stats.last_snapshot_none"
        static let lastSnapshotHint = "stats.last_snapshot_hint"
        static let metricsCount = "stats.metrics_count"
        static let metricsCountHint = "stats.metrics_count_hint"
        static let installIDFormat = "stats.install_id_format"      // %@ = 설치 UUID
        static let reportingOn = "stats.reporting_on"
        static let reportingOnDefault = "stats.reporting_on_default"
        static let reportingOffLocal = "stats.reporting_off_local"
        static let reportingOffRemote = "stats.reporting_off_remote"

        static let evidenceTitle = "stats.evidence_title"
        static let evidenceNote = "stats.evidence_note"
        static let totalHours = "stats.total_hours"
        static let listeners = "stats.listeners"
        static let reachFormat = "stats.reach_format"               // %@ = 비율
        static let perListener = "stats.per_listener"
        static let perListenerHint = "stats.per_listener_hint"
        static let sleepSessions = "stats.sleep_sessions"
        static let sleepHintFormat = "stats.sleep_hint_format"      // %1$@ 비율, %2$lld 전체
        static let timerCompletion = "stats.timer_completion"
        static let ofCountFormat = "stats.of_count_format"          // %1$lld / %2$lld
        static let nightUse = "stats.night_use"
        static let nightHint = "stats.night_hint"
        static let bounce = "stats.bounce"
        static let bounceHint = "stats.bounce_hint"
        static let evidenceFootnote = "stats.evidence_footnote"
        static let rhythmTitle = "stats.rhythm_title"
        static let rhythmNote = "stats.rhythm_note"
        static let weeklyActive = "stats.weekly_active"
        static let weeklyActiveHint = "stats.weekly_active_hint"
        static let monthlyActive = "stats.monthly_active"
        static let minutesPerActive = "stats.minutes_per_active"
        static let minutesPerActiveHint = "stats.minutes_per_active_hint"
        static let daysPerWeek = "stats.days_per_week"
        static let daysPerWeekHint = "stats.days_per_week_hint"
        static let sessionsPerDay = "stats.sessions_per_day"
        static let sessionsPerDayHint = "stats.sessions_per_day_hint"
        static let daysIdle = "stats.days_idle"
        static let daysIdleHint = "stats.days_idle_hint"
        static let bestStreak = "stats.best_streak"
        static let bestStreakHint = "stats.best_streak_hint"
        static let rhythmFootnote = "stats.rhythm_footnote"
        static let hourTitle = "stats.hour_title"
        static let hourNote = "stats.hour_note"
        static let axisHour = "stats.axis_hour"
        static let daysFormat = "stats.days_format"          // %.1f = 일수
        static let timesFormat = "stats.times_format"        // %.1f = 횟수

        static let lengthTitle = "stats.length_title"
        static let lengthNote = "stats.length_note"
        static let lengthEmpty = "stats.length_empty"
        static let axisLength = "stats.axis_length"
        static let axisSessions = "stats.axis_sessions"

        static let trendTitle = "stats.trend_title"
        static let trendNote = "stats.trend_note"
        static let unitPicker = "stats.unit_picker"
        static let unitDay = "stats.unit_day"
        static let unitWeek = "stats.unit_week"
        static let unitMonth = "stats.unit_month"
        static let trendEmpty = "stats.trend_empty"
        static let axisPeriod = "stats.axis_period"
        static let axisActive = "stats.axis_active"
        static let axisSeries = "stats.axis_series"
        static let axisSlept = "stats.axis_slept"
        static let legendActive = "stats.legend_active"
        static let legendSlept = "stats.legend_slept"

        static let retentionTitle = "stats.retention_title"
        static let retentionNote = "stats.retention_note"
        static let retentionEmpty = "stats.retention_empty"
        static let peopleFormat = "stats.people_format"             // %lld = 사람 수

        static let mixTitle = "stats.mix_title"
        static let mixNote = "stats.mix_note"
        static let snapshotEmpty = "stats.snapshot_empty"
        static let axisMixCount = "stats.axis_mix_count"
        static let axisInstalls = "stats.axis_installs"
        static let mixFootnote = "stats.mix_footnote"

        static let signalTitle = "stats.signal_title"
        static let funnelTitle = "stats.funnel_title"
        static let funnelNote = "stats.funnel_note"
        static let eventTitle = "stats.event_title"
        static let eventNote = "stats.event_note"
        static let eventEmpty = "stats.event_empty"
        static let feedbackTitle = "stats.feedback_title"
        static let feedbackCountFormat = "stats.feedback_count_format"   // %1$lld 전체, %2$lld 미처리
        static let inboxEntry = "stats.inbox_entry"

        static let minutesFormat = "stats.minutes_format"           // %lld 분
        static let hoursDecimalFormat = "stats.hours_decimal_format" // %.1f 시간
        static let hoursFormat = "stats.hours_format"               // %lld 시간
        static let countFormat = "stats.count_format"               // %lld 개
    }

    // MARK: - Product Signals
    enum Signal {
        static let proRate = "signal.pro_rate"
        static let proRateHint = "signal.pro_rate_hint"
        static let madeOwnMix = "signal.made_own_mix"
        static let madeOwnMixHint = "signal.made_own_mix_hint"
        static let usedTimer = "signal.used_timer"
        static let usedTimerHint = "signal.used_timer_hint"
        static let unusedMixes = "signal.unused_mixes"
        static let unusedMixesHint = "signal.unused_mixes_hint"
        static let mixesPerInstall = "signal.mixes_per_install"
        static let mixesPerInstallHint = "signal.mixes_per_install_hint"
        static let avgStreak = "signal.avg_streak"
        static let avgStreakHint = "signal.avg_streak_hint"
    }

    // MARK: - Distribution Buckets
    enum MixBucket {
        static let zero = "mix_bucket.zero"
        static let oneTwo = "mix_bucket.one_two"
        static let three = "mix_bucket.three"          // 무료 한도
        static let fourNine = "mix_bucket.four_nine"
        static let tenPlus = "mix_bucket.ten_plus"
    }

    enum LengthBucket {
        static let under5 = "length_bucket.under5"
        static let fiveToFifteen = "length_bucket.5to15"
        static let fifteenToThirty = "length_bucket.15to30"
        static let thirtyToSixty = "length_bucket.30to60"
        static let over60 = "length_bucket.over60"
    }

    enum Funnel {
        static let listen = "funnel.listen"
        static let paywall = "funnel.paywall"
        static let purchase = "funnel.purchase"
    }

    // MARK: - Stability (크래시·멈춤 진단)
    enum Stability {
        static let title = "stability.title"
        static let entry = "stability.entry"
        static let entryHint = "stability.entry_hint"
        static let byVersion = "stability.by_version"
        static let byVersionNote = "stability.by_version_note"
        static let recent = "stability.recent"
        static let empty = "stability.empty"
        static let loadError = "stability.load_error"
        static let delayNote = "stability.delay_note"
        static let kindCrash = "stability.kind_crash"
        static let kindHang = "stability.kind_hang"
        static let kindDiskWrite = "stability.kind_disk_write"
        static let copy = "stability.copy"
        static let copied = "stability.copied"
        static let countFormat = "stability.count_format"   // %lld = 건수
    }

    // MARK: - App
    enum App {
        static let name = "app.name"
    }
}
