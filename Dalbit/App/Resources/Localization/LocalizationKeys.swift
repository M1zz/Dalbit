//
//  LocalizationKeys.swift
//  RelaxOn
//
//  Type-safe localization keys for internationalization
//

import Foundation

/// Type-safe localization keys organized by feature
enum L {

    // MARK: - Sound List
    enum SoundList {
        static let title = "sound_list.title"
        static let createNew = "sound_list.create_new"
        static let sample = "sound_list.sample"
        static let recommended = "sound_list.recommended"
        static let originalSounds = "sound_list.original_sounds"
        static let searchPlaceholder = "sound_list.search_placeholder"
        static let freeCount = "sound_list.free_count"
    }

    // MARK: - Create Sound
    enum CreateSound {
        static let title = "create_sound.title"
        static let back = "create_sound.back"
        static let create = "create_sound.create"
        static let canvasTitle = "create_sound.canvas_title"
        static let playing = "create_sound.playing"
        static let selectOriginal = "create_sound.select_original"
        static let selectBoth = "create_sound.select_both"
        static let canPlayNow = "create_sound.can_play_now"
        static let backgroundSound = "create_sound.background_sound"
        static let backgroundVolume = "create_sound.background_volume"
        static let originalSoundSelection = "create_sound.original_sound_selection"
        static let customizing = "create_sound.customizing"
        static let combinedFormat = "create_sound.combined_format"
        static let enterSoundName = "create_sound.enter_sound_name"
        static let selectedLayers = "create_sound.selected_layers"
        static let selectOriginalSound = "create_sound.select_original_sound"
        static let combineMultipleSounds = "create_sound.combine_multiple_sounds"
        static let originalSounds = "create_sound.original_sounds"
        static let tapToSelectMultiple = "create_sound.tap_to_select_multiple"
        static let backgroundMusic = "create_sound.background_music"
        static let optionalAmbience = "create_sound.optional_ambience"
        static let deselect = "create_sound.deselect"
        static let backgroundMusicVolume = "create_sound.background_music_volume"
    }

    // MARK: - Common
    enum Common {
        static let save = "common.save"
        static let cancel = "common.cancel"
        static let remove = "common.remove"
        static let edit = "common.edit"
        static let delete = "common.delete"
        static let reset = "common.reset"
        static let done = "common.done"
        static let close = "common.close"
        static let next = "common.next"
        static let filter = "common.filter"
        static let customized = "common.customized"
        static let variation = "common.variation"
        static let quiet = "common.quiet"
        static let loud = "common.loud"
        static let tapToCustomize = "common.tap_to_customize"
        static let on = "common.on"
        static let off = "common.off"
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
        static let enterDescription = "alert.enter_description"
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

    // MARK: - Presets
    enum Preset {
        enum DeepSleep {
            static let title = "preset.deep_sleep.title"
            static let description = "preset.deep_sleep.description"
        }

        enum QuickSleep {
            static let title = "preset.quick_sleep.title"
            static let description = "preset.quick_sleep.description"
        }

        enum Meditation {
            static let title = "preset.meditation.title"
            static let description = "preset.meditation.description"
        }

        enum Rest {
            static let title = "preset.rest.title"
            static let description = "preset.rest.description"
        }

        enum Focus {
            static let title = "preset.focus.title"
            static let description = "preset.focus.description"
        }

        enum Reading {
            static let title = "preset.reading.title"
            static let description = "preset.reading.description"
        }

        enum Rain {
            static let title = "preset.rain.title"
            static let description = "preset.rain.description"
        }

        enum ForestDawn {
            static let title = "preset.forest_dawn.title"
            static let description = "preset.forest_dawn.description"
        }

        // Rain 카테고리
        enum SoftRain {
            static let title = "preset.soft_rain.title"
            static let description = "preset.soft_rain.description"
        }

        enum CityRain {
            static let title = "preset.city_rain.title"
            static let description = "preset.city_rain.description"
        }

        // Ambient 카테고리
        enum Underwater {
            static let title = "preset.underwater.title"
            static let description = "preset.underwater.description"
        }

        enum DeepMeditation {
            static let title = "preset.deep_meditation.title"
            static let description = "preset.deep_meditation.description"
        }

        enum CosmicAtmosphere {
            static let title = "preset.cosmic_atmosphere.title"
            static let description = "preset.cosmic_atmosphere.description"
        }

        // ASMR 카테고리
        enum TypingFocus {
            static let title = "preset.typing_focus.title"
            static let description = "preset.typing_focus.description"
        }

        enum CameraClick {
            static let title = "preset.camera_click.title"
            static let description = "preset.camera_click.description"
        }

        // 확장 카테고리
        enum TibetanMeditation {
            static let title = "preset.tibetan_meditation.title"
            static let description = "preset.tibetan_meditation.description"
        }

        enum JungleMorning {
            static let title = "preset.jungle_morning.title"
            static let description = "preset.jungle_morning.description"
        }
    }

    // MARK: - Customization
    enum Customize {
        static let volume = "customize.volume"
        static let pitch = "customize.pitch"
        static let interval = "customize.interval"
        static let variation = "customize.variation"
        static let min = "customize.min"
        static let base = "customize.base"
        static let max = "customize.max"
        static let seconds = "customize.seconds"
        static let variationDescription = "customize.variation_description"
        static let variationDescriptionSeconds = "customize.variation_description_seconds"
        static let variationDescriptionPercent = "customize.variation_description_percent"
        static let findYourSound = "customize.find_your_sound"
        static let adjustSlider = "customize.adjust_slider"
        static let variationRange = "customize.variation_range"
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
        static let skip = "onboarding.skip"
        static let next = "onboarding.next"
        static let start = "onboarding.start"
        static let title1 = "onboarding.title1"
        static let title2 = "onboarding.title2"
        static let title3 = "onboarding.title3"
        static let title4 = "onboarding.title4"
        static let desc1 = "onboarding.desc1"
        static let desc2 = "onboarding.desc2"
        static let desc3 = "onboarding.desc3"
        static let desc4 = "onboarding.desc4"
    }

    // MARK: - Listen View
    enum Listen {
        static let selectSoundToPlay = "listen.select_sound_to_play"
        static let relaxWithWhiteNoise = "listen.relax_with_white_noise"
        static let playSoundForCampfire = "listen.play_sound_for_campfire"
        static let savedSounds = "listen.saved_sounds"
        static let noSavedSounds = "listen.no_saved_sounds"
        static let createFirstSound = "listen.create_first_sound"
        static let newSoundCreate = "listen.new_sound_create"
        static let mySounds = "listen.my_sounds"
        static let searchResults = "listen.search_results"
        static let noSearchResults = "listen.no_search_results"
        static let soundSearch = "listen.sound_search"
        static let presets = "listen.presets"
        static let recommendationMorning = "listen.recommendation_morning"
        static let recommendationFocus = "listen.recommendation_focus"
        static let recommendationEvening = "listen.recommendation_evening"
        static let recommendationSleep = "listen.recommendation_sleep"
        static let layerCount = "listen.layer_count"
        static let tapToPlay = "listen.tap_to_play"
        static let nowPlayingState = "listen.now_playing_state"
        static let swipeHint = "listen.swipe_hint"
        static let campfire = "listen.campfire"
        static let campfireDescription = "listen.campfire_description"
        static let rainSound = "listen.rain_sound"
        static let rainSoundDescription = "listen.rain_sound_description"
        static let heavyRain = "listen.heavy_rain"
        static let heavyRainDescription = "listen.heavy_rain_description"
        static let favoriteOn = "listen.favorite_on"
        static let favoriteOff = "listen.favorite_off"
        static let satelliteHint = "listen.satellite_hint"
    }

    // MARK: - Timer
    enum Timer {
        static let title = "timer.title"
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
        static let layer = "player.layer"
        static let layerFormat = "player.layer_format"
        static let distance = "player.distance"
        static let angle = "player.angle"
        static let height = "player.height"
        static let realTimePlaying = "player.real_time_playing"
        static let hasVariation = "player.has_variation"
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
        enum OceanWave {
            static let name = "preset_new.ocean_wave.name"
            static let description = "preset_new.ocean_wave.description"
        }
        enum SummerRain {
            static let name = "preset_new.summer_rain.name"
            static let description = "preset_new.summer_rain.description"
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
        static let selectYourSound = "save_view.select_your_sound"
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
        static let limitReached = "subscription.limit_reached"
        static let limitReachedDescription = "subscription.limit_reached_description"
        static let categoryLocked = "subscription.category_locked"
        static let categoryLockedDescription = "subscription.category_locked_description"
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
        static let fineTune = "studio.fine_tune"
        static let interval = "studio.interval"
        static let intervalHint = "studio.interval_hint"
        static let irregularity = "studio.irregularity"
        static let regular = "studio.regular"
        static let natural = "studio.natural"
        static let space = "studio.space"
        static let narrow = "studio.narrow"
        static let wide = "studio.wide"
    }

    enum Place {
        static let cave = "place.cave"
        static let basement = "place.basement"
        static let sink = "place.sink"
        static let forest = "place.forest"
        static let jungle = "place.jungle"
        static let rain = "place.rain"
        static let cityRain = "place.city_rain"
        static let temple = "place.temple"
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

    // MARK: - Feedback (사용자 의견 보내기)
    enum Feedback {
        static let entry = "feedback.entry"
        static let entryHint = "feedback.entry_hint"
        static let title = "feedback.title"
        static let typeLabel = "feedback.type_label"
        static let typeBug = "feedback.type_bug"
        static let typeFeature = "feedback.type_feature"
        static let typeQuestion = "feedback.type_question"
        static let typeOther = "feedback.type_other"
        static let messageLabel = "feedback.message_label"
        static let placeholderBug = "feedback.placeholder_bug"
        static let placeholderFeature = "feedback.placeholder_feature"
        static let placeholderQuestion = "feedback.placeholder_question"
        static let placeholderOther = "feedback.placeholder_other"
        static let deviceInfo = "feedback.device_info"
        static let send = "feedback.send"
        static let sending = "feedback.sending"
        static let sent = "feedback.sent"
        static let errorICloud = "feedback.error_icloud"
        static let errorSend = "feedback.error_send"
    }

    // MARK: - Accessibility (VoiceOver)
    enum A11y {
        static let savedSoundsButton = "a11y.saved_sounds_button"
        static let timerButton = "a11y.timer_button"
        static let timerActiveValue = "a11y.timer_active_value"          // %@ = 남은 시간
        static let play = "a11y.play"
        static let pause = "a11y.pause"
        static let stop = "a11y.stop"
        static let closeButton = "a11y.close_button"
        static let backButton = "a11y.back_button"
        static let nowPlaying = "a11y.now_playing"                       // %1$@ 제목, %2$@ 카테고리
        static let openFullPlayerHint = "a11y.open_full_player_hint"
        static let playSoundHint = "a11y.play_sound_hint"
        static let favorite = "a11y.favorite"
        static let favoriteOn = "a11y.favorite_on"
        static let favoriteOff = "a11y.favorite_off"
        static let createNewButton = "a11y.create_new_button"
        static let hoursPicker = "a11y.hours_picker"
        static let minutesPicker = "a11y.minutes_picker"
        static let remainingTimeLabel = "a11y.remaining_time_label"
        static let volumeSlider = "a11y.volume_slider"
        static let pitchSlider = "a11y.pitch_slider"
        static let intervalSlider = "a11y.interval_slider"
        static let filterPicker = "a11y.filter_picker"
        static let clearSearch = "a11y.clear_search"
        static let decorativeAnimation = "a11y.decorative_animation"
        static let previousSound = "a11y.previous_sound"
        static let nextSound = "a11y.next_sound"
        static let removeLayer = "a11y.remove_layer"
        static let distanceSlider = "a11y.distance_slider"
        static let angleSlider = "a11y.angle_slider"
        static let heightSlider = "a11y.height_slider"
    }
}
