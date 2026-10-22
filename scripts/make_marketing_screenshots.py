#!/usr/bin/env python3
"""App Store 마케팅 스크린샷: 원본 캡처 + 헤드라인 → 헤드리스 Chrome (appstore-assets 스킬 방식).

사용법: python3 scripts/make_marketing_screenshots.py [ko en ...]   (없으면 전부)

원본    docs/screenshots/raw/<언어>/0N-….png         아이폰 6.9" 캡처(1320×2868)
        docs/screenshots/raw/ipad/<언어>/0N-….png    아이패드 13" 캡처(2064×2752)
제출본  docs/screenshots/marketing/<스토어 로케일>/0N-….png        1242×2688
        docs/screenshots/marketing/<스토어 로케일>/ipad-0N-….png   2064×2752

바탕·글자색은 제품 페이지 헤더(make_creative_assets.py)와 같다: 밤하늘 남보라 + 달빛 보라.
"""
import os, subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
WORK = pathlib.Path("/tmp") / "dalbit-marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# 원본 폴더 이름 → 스토어 로케일. 나머지는 이름이 같다(en-GB 는 en-US 와 따로 둔다).
STORE = {"en": "en-US"}

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
    "ja": [
        ("01-moon.png",    "月をタップすれば<br>眠りの時間", "横にスワイプで別の音、長押しでお気に入り"),
        ("02-studio.png",  "雨音の上に<br>しずくをひと粒", "音量もリズムも、聞こえる位置も思いのまま"),
        ("03-library.png", "一度つくれば<br>次の夜はワンタップ", "睡眠・集中・瞑想、保存した音をすぐ再生"),
        ("04-timer.png",   "ぷつりと切れず<br>そっと止まる", "スリープタイマーは音をゆっくり小さくします"),
        ("05-alarm.png",   "やさしい朝は<br>シンギングボウルで", "曜日ごとに設定できる、穏やかなアラーム"),
    ],
    "en-GB": [
        ("01-moon.png",    "Tap the moon.<br>Drift off.", "Swipe for another sound, hold to favourite"),
        ("02-studio.png",  "Water drops<br>over rain", "Set each layer's volume, rhythm and space"),
        ("03-library.png", "Make it once,<br>play it every night", "Sleep, focus and meditation mixes, one tap away"),
        ("04-timer.png",   "It fades.<br>It never cuts out.", "A sleep timer that won't wake you up"),
        ("05-alarm.png",   "Wake up to<br>a singing bowl", "Gentle alarms for the days you choose"),
    ],
    "zh-Hans": [
        ("01-moon.png",    "轻点月亮<br>安然入睡", "左右滑动换一种声音，长按加入收藏"),
        ("02-studio.png",  "雨声之上<br>再添水滴", "每一层的音量、节奏和方位都由你定"),
        ("03-library.png", "调好一次<br>夜夜一键播放", "睡眠、专注、冥想，保存的声音随点随听"),
        ("04-timer.png",   "慢慢变轻<br>不会戛然而止", "睡眠定时器会把声音缓缓调小"),
        ("05-alarm.png",   "在颂钵声中<br>醒来", "按星期设置的温柔闹钟"),
    ],
    "zh-Hant": [
        ("01-moon.png",    "輕點月亮<br>安心入睡", "左右滑動換一種聲音，長按加入喜好"),
        ("02-studio.png",  "雨聲之上<br>再添水滴", "每一層的音量、節奏和方位都由你決定"),
        ("03-library.png", "調好一次<br>每晚一鍵播放", "睡眠、專注、冥想，儲存的聲音隨點隨聽"),
        ("04-timer.png",   "慢慢變小聲<br>不會突然中斷", "睡眠計時器會把聲音緩緩調小"),
        ("05-alarm.png",   "在頌缽聲中<br>醒來", "可依星期設定的溫柔鬧鐘"),
    ],
    "ru": [
        ("01-moon.png",    "Коснитесь луны —<br>и засыпайте", "Смахните для другого звука, удерживайте для избранного"),
        ("02-studio.png",  "Капли<br>поверх дождя", "Громкость, ритм и место звучания каждого слоя"),
        ("03-library.png", "Создайте раз —<br>слушайте каждую ночь", "Сон, фокус и медитация в одно касание"),
        ("04-timer.png",   "Затихает плавно,<br>а не обрывается", "Таймер сна, который вас не разбудит"),
        ("05-alarm.png",   "Утро под звук<br>поющей чаши", "Мягкие будильники в выбранные дни"),
    ],
    "es": [
        ("01-moon.png",    "Toca la luna.<br>A dormir.", "Desliza para cambiar de sonido, mantén pulsado para favoritos"),
        ("02-studio.png",  "Gotas de agua<br>sobre la lluvia", "Volumen, ritmo y posición para cada capa"),
        ("03-library.png", "Créala una vez,<br>escúchala cada noche", "Dormir, concentrarte o meditar, con un toque"),
        ("04-timer.png",   "Se apaga poco a poco.<br>Sin cortes.", "Un temporizador que no te despierta"),
        ("05-alarm.png",   "Despierta con<br>un cuenco tibetano", "Alarmas suaves los días que elijas"),
    ],
    "de": [
        ("01-moon.png",    "Mond antippen.<br>Einschlafen.", "Wischen für einen anderen Klang, halten für Favoriten"),
        ("02-studio.png",  "Wassertropfen<br>über dem Regen", "Lautstärke, Rhythmus und Raum für jede Ebene"),
        ("03-library.png", "Einmal mischen,<br>jede Nacht hören", "Schlaf, Fokus und Meditation mit einem Tipp"),
        ("04-timer.png",   "Leise ausklingen.<br>Nie abrupt.", "Ein Schlaftimer, der dich nicht weckt"),
        ("05-alarm.png",   "Aufwachen mit<br>der Klangschale", "Sanfte Wecker an den Tagen deiner Wahl"),
    ],
    "fr": [
        ("01-moon.png",    "Touchez la lune.<br>Endormez-vous.", "Balayez pour changer de son, maintenez pour l’ajouter aux favoris"),
        ("02-studio.png",  "Des gouttes<br>sur la pluie", "Volume, rythme et position pour chaque couche"),
        ("03-library.png", "Créé une fois,<br>écouté chaque nuit", "Sommeil, concentration, méditation : en un geste"),
        ("04-timer.png",   "Le son s’estompe,<br>sans couper net", "Une minuterie qui ne vous réveille pas"),
        ("05-alarm.png",   "Réveil en douceur<br>au bol chantant", "Des alarmes douces, les jours de votre choix"),
    ],
    "it": [
        ("01-moon.png",    "Tocca la luna.<br>E dormi.", "Scorri per un altro suono, tieni premuto per i preferiti"),
        ("02-studio.png",  "Gocce d’acqua<br>sulla pioggia", "Volume, ritmo e posizione per ogni livello"),
        ("03-library.png", "Creala una volta,<br>ascoltala ogni notte", "Sonno, concentrazione e meditazione con un tocco"),
        ("04-timer.png",   "Si spegne piano.<br>Senza interruzioni.", "Un timer che non ti sveglia"),
        ("05-alarm.png",   "Svegliati con<br>una campana tibetana", "Sveglie delicate nei giorni che scegli"),
    ],
    "pt-BR": [
        ("01-moon.png",    "Toque na lua.<br>E durma.", "Deslize para outro som, segure para favoritar"),
        ("02-studio.png",  "Gotas d’água<br>sobre a chuva", "Volume, ritmo e posição de cada camada"),
        ("03-library.png", "Crie uma vez,<br>ouça toda noite", "Sono, foco e meditação a um toque"),
        ("04-timer.png",   "Diminui aos poucos.<br>Nunca corta.", "Um timer de sono que não te acorda"),
        ("05-alarm.png",   "Acorde com<br>uma tigela tibetana", "Alarmes suaves nos dias que você escolher"),
    ],
    "th": [
        ("01-moon.png",    "แตะดวงจันทร์<br>แล้วหลับสบาย", "ปัดเพื่อเปลี่ยนเสียง กดค้างเพื่อเพิ่มรายการโปรด"),
        ("02-studio.png",  "หยดน้ำ<br>บนเสียงฝน", "ปรับระดับเสียง จังหวะ และตำแหน่งได้ทุกชั้น"),
        ("03-library.png", "สร้างครั้งเดียว<br>ฟังได้ทุกคืน", "นอนหลับ จดจ่อ หรือทำสมาธิ แตะครั้งเดียว"),
        ("04-timer.png",   "ค่อย ๆ เบาลง<br>ไม่ตัดกะทันหัน", "ตัวตั้งเวลานอนที่ไม่ปลุกคุณ"),
        ("05-alarm.png",   "ตื่นเช้าด้วย<br>เสียงขันทิเบต", "นาฬิกาปลุกนุ่มนวลในวันที่คุณเลือก"),
    ],
    "vi": [
        ("01-moon.png",    "Chạm mặt trăng.<br>Ngủ thật ngon.", "Vuốt để đổi âm thanh, nhấn giữ để thêm yêu thích"),
        ("02-studio.png",  "Giọt nước<br>trên tiếng mưa", "Chỉnh âm lượng, nhịp và vị trí từng lớp"),
        ("03-library.png", "Tạo một lần,<br>nghe mỗi đêm", "Ngủ, tập trung, thiền chỉ với một chạm"),
        ("04-timer.png",   "Nhỏ dần.<br>Không tắt đột ngột.", "Hẹn giờ ngủ không làm bạn thức giấc"),
        ("05-alarm.png",   "Thức dậy cùng<br>tiếng chuông xoay", "Báo thức nhẹ nhàng vào ngày bạn chọn"),
    ],
    "cs": [
        ("01-moon.png",    "Klepněte na měsíc.<br>Usněte.", "Přejetím změníte zvuk, podržením přidáte do oblíbených"),
        ("02-studio.png",  "Kapky vody<br>nad deštěm", "Hlasitost, rytmus i umístění každé vrstvy"),
        ("03-library.png", "Namíchejte jednou,<br>poslouchejte každou noc", "Spánek, soustředění i meditace jedním klepnutím"),
        ("04-timer.png",   "Pomalu utichne.<br>Nikdy neutne.", "Časovač spánku, který vás nevzbudí"),
        ("05-alarm.png",   "Probuďte se<br>s tibetskou mísou", "Jemné budíky ve dny, které si zvolíte"),
    ],
    "da": [
        ("01-moon.png",    "Tryk på månen.<br>Fald i søvn.", "Swipe for en ny lyd, hold for at gøre den til favorit"),
        ("02-studio.png",  "Vanddråber<br>over regn", "Lydstyrke, rytme og placering for hvert lag"),
        ("03-library.png", "Lav den én gang,<br>hør den hver nat", "Søvn, fokus og meditation med ét tryk"),
        ("04-timer.png",   "Lyden toner ud.<br>Aldrig brat.", "En sovetimer, der ikke vækker dig"),
        ("05-alarm.png",   "Vågn op til<br>en syngeskål", "Blide alarmer på de dage, du vælger"),
    ],
    "el": [
        ("01-moon.png",    "Αγγίξτε το φεγγάρι.<br>Αποκοιμηθείτε.", "Σύρετε για άλλον ήχο, κρατήστε για τα αγαπημένα"),
        ("02-studio.png",  "Σταγόνες νερού<br>πάνω στη βροχή", "Ένταση, ρυθμός και θέση για κάθε επίπεδο"),
        ("03-library.png", "Φτιάξτε το μία φορά,<br>ακούστε το κάθε βράδυ", "Ύπνος, συγκέντρωση, διαλογισμός με ένα άγγιγμα"),
        ("04-timer.png",   "Σβήνει σιγά σιγά.<br>Δεν κόβεται απότομα.", "Χρονόμετρο ύπνου που δεν σας ξυπνά"),
        ("05-alarm.png",   "Ξυπνήστε με<br>θιβετιανό μπολ", "Απαλά ξυπνητήρια τις μέρες που διαλέγετε"),
    ],
    "fi": [
        ("01-moon.png",    "Napauta kuuta.<br>Nukahda.", "Pyyhkäise vaihtaaksesi ääntä, pidä painettuna suosikiksi"),
        ("02-studio.png",  "Vesipisaroita<br>sateen päälle", "Jokaisen kerroksen voimakkuus, rytmi ja paikka"),
        ("03-library.png", "Tee kerran,<br>kuuntele joka yö", "Uni, keskittyminen ja meditaatio yhdellä napautuksella"),
        ("04-timer.png",   "Hiipuu hiljaa.<br>Ei katkea kesken.", "Uniajastin, joka ei herätä sinua"),
        ("05-alarm.png",   "Herää<br>laulumaljan ääneen", "Lempeät herätykset valitsemillesi päiville"),
    ],
    "id": [
        ("01-moon.png",    "Ketuk bulan.<br>Lalu terlelap.", "Geser untuk suara lain, tahan untuk favorit"),
        ("02-studio.png",  "Tetesan air<br>di atas hujan", "Atur volume, ritme, dan posisi tiap lapisan"),
        ("03-library.png", "Buat sekali,<br>putar tiap malam", "Tidur, fokus, dan meditasi dengan sekali ketuk"),
        ("04-timer.png",   "Memudar perlahan.<br>Tak terputus tiba-tiba.", "Timer tidur yang tak membangunkanmu"),
        ("05-alarm.png",   "Bangun dengan<br>suara singing bowl", "Alarm lembut di hari yang kamu pilih"),
    ],
    "nb": [
        ("01-moon.png",    "Trykk på månen.<br>Sovn inn.", "Sveip for en annen lyd, hold for å gjøre den til favoritt"),
        ("02-studio.png",  "Vanndråper<br>over regn", "Volum, rytme og plassering for hvert lag"),
        ("03-library.png", "Lag den én gang,<br>spill den hver natt", "Søvn, fokus og meditasjon med ett trykk"),
        ("04-timer.png",   "Lyden toner ut.<br>Aldri brått.", "En sovetimer som ikke vekker deg"),
        ("05-alarm.png",   "Våkn til<br>en syngebolle", "Myke alarmer de dagene du velger"),
    ],
    "nl": [
        ("01-moon.png",    "Tik op de maan.<br>Val in slaap.", "Veeg voor een ander geluid, houd vast voor favorieten"),
        ("02-studio.png",  "Waterdruppels<br>op de regen", "Volume, ritme en plek voor elke laag"),
        ("03-library.png", "Eén keer maken,<br>elke nacht luisteren", "Slapen, focussen en mediteren met één tik"),
        ("04-timer.png",   "Het zwakt af.<br>Nooit abrupt.", "Een slaaptimer die je niet wekt"),
        ("05-alarm.png",   "Wakker worden<br>met een klankschaal", "Zachte wekkers op de dagen die jij kiest"),
    ],
    "pl": [
        ("01-moon.png",    "Dotknij księżyca.<br>Zaśnij.", "Przesuń, by zmienić dźwięk, przytrzymaj, by dodać do ulubionych"),
        ("02-studio.png",  "Krople wody<br>na tle deszczu", "Głośność, rytm i położenie każdej warstwy"),
        ("03-library.png", "Stwórz raz,<br>słuchaj co noc", "Sen, skupienie i medytacja jednym dotknięciem"),
        ("04-timer.png",   "Cichnie powoli.<br>Nigdy nie urywa.", "Wyłącznik czasowy, który cię nie obudzi"),
        ("05-alarm.png",   "Pobudka przy<br>misie tybetańskiej", "Łagodne alarmy w wybrane dni"),
    ],
    "sv": [
        ("01-moon.png",    "Tryck på månen.<br>Somna.", "Svep för ett annat ljud, håll kvar för favorit"),
        ("02-studio.png",  "Vattendroppar<br>över regn", "Volym, rytm och placering för varje lager"),
        ("03-library.png", "Skapa en gång,<br>lyssna varje natt", "Sömn, fokus och meditation med ett tryck"),
        ("04-timer.png",   "Ljudet tonar ut.<br>Aldrig tvärt.", "En sovtimer som inte väcker dig"),
        ("05-alarm.png",   "Vakna till<br>en klangskål", "Mjuka larm de dagar du väljer"),
    ],
    "tr": [
        ("01-moon.png",    "Aya dokun.<br>Uykuya dal.", "Başka ses için kaydır, favorilere eklemek için basılı tut"),
        ("02-studio.png",  "Yağmurun üstüne<br>su damlaları", "Her katmanın sesini, ritmini ve konumunu ayarla"),
        ("03-library.png", "Bir kez oluştur,<br>her gece dinle", "Uyku, odak ve meditasyon tek dokunuşla"),
        ("04-timer.png",   "Yavaşça kısılır.<br>Aniden kesilmez.", "Seni uyandırmayan bir uyku zamanlayıcısı"),
        ("05-alarm.png",   "Tibet çanağının<br>sesiyle uyan", "Seçtiğin günlerde yumuşak alarmlar"),
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
:lang(ja) .headline, :lang(ja) .sub { line-break:strict; font-family:-apple-system, "Hiragino Sans", sans-serif; }
:lang(zh-Hans) .headline, :lang(zh-Hans) .sub { line-break:strict; font-family:-apple-system, "PingFang SC", sans-serif; }
:lang(zh-Hant) .headline, :lang(zh-Hant) .sub { line-break:strict; font-family:-apple-system, "PingFang TC", sans-serif; }
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
    out = OUT / STORE.get(lang, lang)
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
        # DEVICES=iphone 처럼 기기를 골라 그릴 수 있다(아이패드 원본을 아직 안 찍었을 때).
        for device in os.environ.get("DEVICES", ",".join(DEVICES)).split(","):
            render(lang, device)
