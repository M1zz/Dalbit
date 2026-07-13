# 🔊 RelaxOn 음원 소싱 가이드 (저작권 안전)

앱에 쓸 소리를 **상업적 사용이 가능한 무료 음원**으로 채우기 위한 정리 문서입니다.
파일을 받아 **아래 정해진 이름**으로 해당 폴더에 넣으면 코드 수정 없이 바로 동작합니다
(앱은 `파일명 == enum rawValue`로 로드하며, 효과음 32종은 이미 프로젝트에 연결돼 있음).

---

## 1. 어디서 받나 (라이선스 우선순위)

| 소스 | 라이선스 | 비고 |
|---|---|---|
| **Pixabay** (`pixabay.com/sound-effects`) | **상업적 사용 OK, 출처표기 불필요** | 1순위 추천. 가장 안전·간편 |
| **Freesound** (`freesound.org`) | 필터에서 **CC0** 만 선택 | CC-BY는 출처표기 필요 |
| **Mixkit** (`mixkit.co/free-sound-effects`) | 무료 상업적 사용 | 항목별 약관 확인 |

⚠️ **피하기**: `BY-NC`(비상업), `BY-ND`(2차변경 금지), `BY-SA` 일부 → 앱 배포(구독 포함)에 부적합.
다운로드 페이지에서 라이선스 표기를 **파일마다 한 번 더 확인**하세요.

> 자동 다운로드는 막혀 있어(Pixabay 403 등) 직접 파일을 받아야 합니다.
> 브라우저로 받으면 되고, 받은 파일을 아래 이름으로 폴더에 넣으면 끝입니다.

---

## 2. 배경음 (연속 루프) — `Assets/Sound/music/` 또는 `background/`

길고(최소 1~2분) 끊김 없이 이어지는 트랙. 앱이 무한 루프(`.loops`) 시킴.

| 목표 파일명 | 폴더 | Pixabay 검색 |
|---|---|---|
| `wave_10min.mp3` | background | https://pixabay.com/sound-effects/search/ocean%20waves/ |
| `rain_10min.mp3` | background | https://pixabay.com/sound-effects/search/rain%20loop/ |
| `tv_10min.mp3` | background | https://pixabay.com/sound-effects/search/white%20noise/ |
| `piano_10min.mp3` | music | https://pixabay.com/sound-effects/search/calm%20piano/ |
| `guitar_10min.mp3` | music | https://pixabay.com/sound-effects/search/acoustic%20guitar%20ambient/ |
| `ambient_10min.mp3` | music | https://pixabay.com/sound-effects/search/ambient%20drone/ |
| `lofi_10min.mp3` | music | https://pixabay.com/sound-effects/search/lofi/ |
| `meditation_10min.mp3` | music | https://pixabay.com/sound-effects/search/meditation/ |
| `space_1min.mp3` | music | https://pixabay.com/sound-effects/search/deep%20space%20ambient/ |

## 3. 효과음 (짧은 1~8초, 간격마다 반복) — `Assets/Sound/<카테고리>/`

파일명 = 필터 이름 그대로. 카테고리 폴더에 넣으면 됨.

### WaterDrop/  (물방울 계열)
`WaterDrop.mp3` `Basement.mp3` `Cave.mp3` `Pipe.mp3` `Sink.mp3`
→ https://pixabay.com/sound-effects/search/water%20drop/  ·  https://pixabay.com/sound-effects/search/dripping%20cave/

### SingingBowl/  (싱잉볼·종)
`SingingBowl.mp3` `Focus.mp3` `Training.mp3` `Empty.mp3` `Vibration.mp3` `TibetanBowl.mp3` `Bell.mp3` `BowlDeep.mp3` `BowlLoud.mp3`
→ https://pixabay.com/sound-effects/search/singing%20bowl/  ·  https://pixabay.com/sound-effects/search/tibetan%20bowl/  ·  https://pixabay.com/sound-effects/search/bell/

### Bird/  (새·숲)
`Bird.mp3` `Owl.mp3` `Woodpecker.mp3` `Forest.mp3` `Cuckoo.mp3` `Jungle.mp3` `ForestBird.mp3` `SpringForest.mp3`
→ https://pixabay.com/sound-effects/search/birds/  ·  https://pixabay.com/sound-effects/search/owl/  ·  https://pixabay.com/sound-effects/search/forest%20birds/  ·  https://pixabay.com/sound-effects/search/jungle/

### Rain/  (비)
`SoftRain.mp3` `CityRain.mp3` `RainMaker.mp3`
→ https://pixabay.com/sound-effects/search/soft%20rain/  ·  https://pixabay.com/sound-effects/search/city%20rain/  ·  https://pixabay.com/sound-effects/search/rain%20stick/

### Ambient/  (앰비언트)
`AmbientKeys.mp3` `Underwater.mp3` `MeditationPad.mp3` `Atmosphere.mp3` `IndigoMusic.mp3`
→ https://pixabay.com/sound-effects/search/ambient%20keys/  ·  https://pixabay.com/sound-effects/search/underwater/  ·  https://pixabay.com/sound-effects/search/meditation%20pad/  ·  https://pixabay.com/sound-effects/search/atmosphere%20drone/

### ASMR/
`Keyboard.mp3` `Camera.mp3`
→ https://pixabay.com/sound-effects/search/keyboard%20typing/  ·  https://pixabay.com/sound-effects/search/camera%20shutter/

---

## 4. 받은 파일 넣는 법

1. 위 이름 **그대로** 해당 폴더에 복사 (예: `Assets/Sound/Bird/Owl.mp3`).
2. **효과음 32종**은 이미 Xcode 타깃에 등록돼 있어, 같은 이름으로 덮어쓰면 **바로 적용**.
3. **새 파일/새 배경음**을 추가할 때만 Xcode 타깃 멤버십(또는 pbxproj) 등록이 필요 — 말해주면 자동으로 처리.
4. iOS 아이콘과 달리 음원은 캐시 없음. 빌드만 다시 하면 반영.

## 5. 한 번에 받기용 스크립트 템플릿

각 파일의 **직접 다운로드 URL**을 확인했으면 `sounds.tsv`에 `URL<TAB>대상경로`로 적고 아래 실행:

```bash
# sounds.tsv 예:
# https://cdn.pixabay.com/audio/..../owl.mp3	RelaxOn/App/Assets/Sound/Bird/Owl.mp3
while IFS=$'\t' read -r url path; do
  [ -z "$url" ] && continue
  curl -sL --max-time 120 "$url" -o "$path" && echo "✓ $path"
done < sounds.tsv
```

---

**Last updated**: 2026-06-21
