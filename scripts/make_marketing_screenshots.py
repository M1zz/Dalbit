#!/usr/bin/env python3
"""App Store 마케팅 스크린샷: 원본 캡처 + 헤드라인 → 헤드리스 Chrome (appstore-assets 스킬 방식).

사용법: python3 scripts/make_marketing_screenshots.py [ko en ...]   (없으면 전부)

원본    docs/screenshots/raw/<언어>/0N-….png         아이폰 6.9" 캡처(1320×2868)
        docs/screenshots/raw/ipad/<언어>/0N-….png    아이패드 13" 캡처(2064×2752)
제출본  docs/screenshots/marketing/<스토어 로케일>/0N-….png        1242×2688
        docs/screenshots/marketing/<스토어 로케일>/ipad-0N-….png   2064×2752

바탕·글자색은 제품 페이지 헤더(make_creative_assets.py)와 같다: 밤하늘 남보라 + 달빛 보라.
"""
import subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
WORK = pathlib.Path("/tmp") / "dalbit-marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
STORE = {"ko": "ko", "en": "en-US"}

# (원본 파일, 헤드라인, 서브카피) — 언어마다 따로 쓴다.
SHOTS = {
    "ko": [
        ("01-moon.png",    "달을 누르면<br>잠이 시작돼요", "옆으로 밀면 다른 소리, 길게 누르면 즐겨찾기"),
        ("02-studio.png",  "빗소리 위에<br>물방울 한 겹", "볼륨과 간격, 들리는 자리까지 내 마음대로"),
        ("03-library.png", "한 번 만들면<br>다음 밤엔 한 번에", "수면 · 집중 · 명상, 저장한 소리를 바로"),
        ("04-timer.png",   "끊기지 않고<br>스르르 멈춰요", "수면 타이머는 소리를 천천히 줄여 줘요"),
        ("05-alarm.png",   "아침은<br>싱잉볼 소리로", "요일마다 부드럽게 깨워 주는 알람"),
    ],
    "en": [
        ("01-moon.png",    "Tap the moon.<br>Drift off.", "Swipe for another sound, hold to favorite"),
        ("02-studio.png",  "Water drops<br>over rain", "Set each layer's volume, rhythm and space"),
        ("03-library.png", "Make it once,<br>play it every night", "Sleep, focus and meditation mixes, one tap away"),
        ("04-timer.png",   "It fades.<br>It never cuts out.", "A sleep timer that won't wake you up"),
        ("05-alarm.png",   "Wake up to<br>a singing bowl", "Gentle alarms for the days you choose"),
    ],
}

DEVICES = {
    # 이름: (캔버스, 기기 폭, 기기 top, 모서리, 테두리, 파일 접두사, 원본 하위 폴더)
    "iphone": ((1242, 2688), 900, 820, 112, 24, "", ""),
    "ipad":   ((2064, 2752), 1560, 880, 70, 28, "ipad-", "ipad"),
}

CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:#121019; position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", sans-serif; }
.glow { position:absolute; left:50%%; top:%(GT)dpx; width:%(GW)dpx; height:%(GW)dpx; margin-left:-%(GH)dpx;
  border-radius:50%%; filter:blur(200px); background:rgba(140,132,240,.30); }
.t { position:absolute; left:80px; right:80px; top:%(TT)dpx; text-align:center; }
.headline { font-size:%(HS)dpx; font-weight:800; color:#F3F1FB; letter-spacing:-0.03em; line-height:1.14; }
.sub { margin-top:40px; font-size:%(SS)dpx; font-weight:500; color:#9C98B3; letter-spacing:-0.01em; line-height:1.3; }
:lang(ko) .headline, :lang(ko) .sub { word-break:keep-all; }
.dev { position:absolute; left:50%%; top:%(DT)dpx; width:%(DW)dpx; margin-left:-%(DH)dpx; background:#0c0b10;
  border:4px solid #3a3850; padding:%(PAD)dpx; border-radius:%(R)dpx; box-shadow:0 60px 160px rgba(0,0,0,.6); }
.dev img { width:100%%; display:block; border-radius:%(IR)dpx; }
"""

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>{css}</style></head>
<body><div class="glow"></div><div class="t"><div class="headline">{h}</div><div class="sub">{s}</div></div>
<div class="dev"><img src="{img}"></div></body></html>"""


def render(lang, device):
    (W, H), dw, dt, r, pad, prefix, sub = DEVICES[device]
    src = RAW / sub / lang if sub else RAW / lang
    out = OUT / STORE[lang]
    out.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(exist_ok=True)
    css = CSS % {"W": W, "H": H, "GT": dt + 200, "GW": 1400, "GH": 700, "TT": 230 if device == "iphone" else 210,
                 "HS": 104 if device == "iphone" else 120, "SS": 48 if device == "iphone" else 56,
                 "DT": dt, "DW": dw, "DH": dw // 2, "PAD": pad, "R": r, "IR": r - pad}
    for fname, h, s in SHOTS[lang]:
        img = src / fname
        html = WORK / f"{lang}-{device}-{fname}.html"
        html.write_text(HTML.format(lang=lang, css=css, h=h, s=s, img=img.as_uri()), encoding="utf-8")
        target = out / f"{prefix}{fname}"
        # 다른 세션의 Chrome 과 겹치면 가끔 실패하거나 끝나지 않는다 — 새 프로필로 다시 시도한다.
        for attempt in range(4):
            target.unlink(missing_ok=True)
            try:
                subprocess.run([CHROME, "--headless=new", f"--screenshot={target}", f"--window-size={W},{H}",
                                "--force-device-scale-factor=1", "--hide-scrollbars", "--disable-gpu",
                                "--no-first-run", f"--user-data-dir={WORK / f'chrome-{attempt}'}", html.as_uri()],
                               capture_output=True, timeout=40)
            except subprocess.TimeoutExpired:
                pass
            if target.exists() and target.stat().st_size > 0:
                break
        else:
            sys.exit(f"렌더 실패: {target}")
        print("rendered", target.relative_to(ROOT))


if __name__ == "__main__":
    for lang in sys.argv[1:] or list(SHOTS):
        for device in DEVICES:
            render(lang, device)
