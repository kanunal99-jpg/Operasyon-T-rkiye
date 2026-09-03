extends CanvasLayer

signal finished

var panel: Panel
var banner: ColorRect
var ticker: Label
var category_label: Label
var headline_label: Label
var body_label: Label
var location_label: Label
var progress_label: Label
var progress_bar: ProgressBar
var continue_button: Button
var skip_button: Button
var timer := 0.0
var card_index := 0
var cards: Array[Dictionary] = []
var active := false
var typewriter_token := 0

func _ready() -> void:
    layer = 50
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel = Panel.new()
    panel.position = Vector2(70, 55)
    panel.size = Vector2(1140, 610)
    add_child(panel)

    banner = ColorRect.new()
    banner.position = Vector2(0, 0)
    banner.size = Vector2(1140, 42)
    banner.color = Color("#8f1722")
    panel.add_child(banner)
    ticker = Label.new()
    ticker.text = "● SON DAKİKA   •   OPERASYON TÜRKİYE   •   ULUSLARARASI KRİZ MASASI"
    ticker.position = Vector2(24, 9)
    ticker.add_theme_font_size_override("font_size", 18)
    banner.add_child(ticker)

    category_label = Label.new(); category_label.position = Vector2(35, 62); category_label.add_theme_font_size_override("font_size", 20); panel.add_child(category_label)
    headline_label = Label.new(); headline_label.position = Vector2(35, 105); headline_label.size = Vector2(1070, 95); headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; headline_label.add_theme_font_size_override("font_size", 34); panel.add_child(headline_label)
    body_label = Label.new(); body_label.position = Vector2(35, 215); body_label.size = Vector2(1070, 210); body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body_label.add_theme_font_size_override("font_size", 22); panel.add_child(body_label)
    location_label = Label.new(); location_label.position = Vector2(35, 445); location_label.size = Vector2(720, 40); panel.add_child(location_label)
    progress_label = Label.new(); progress_label.position = Vector2(35, 485); panel.add_child(progress_label)

    progress_bar = ProgressBar.new()
    progress_bar.position = Vector2(35, 520)
    progress_bar.size = Vector2(720, 12)
    progress_bar.show_percentage = false
    panel.add_child(progress_bar)

    continue_button = Button.new(); continue_button.text = "DEVAM ET"; continue_button.position = Vector2(820, 470); continue_button.size = Vector2(140, 60); continue_button.pressed.connect(_next_card); panel.add_child(continue_button)
    skip_button = Button.new(); skip_button.text = "⏭ ATLA"; skip_button.position = Vector2(970, 470); skip_button.size = Vector2(140, 60); skip_button.pressed.connect(skip); panel.add_child(skip_button)
    panel.visible = false

func play_briefing(country: String, city: String, operation: String, ally_count: int = 0, custom_cards: Array[Dictionary] = []) -> void:
    cards = custom_cards if not custom_cards.is_empty() else [
        {"category":"DÜNYA HABERLERİ • SON DAKİKA", "headline":"SINIR HATTINDA GERİLİM TIRMANIYOR", "body":"%s çevresinde güvenlik alarmı yükseldi. Hükümetler olağanüstü toplantıya çağrıldı; birlikler savunma hazırlıklarını artırdı." % country, "location":"CANLI YAYIN • %s" % city},
        {"category":"BAŞKANLIK AÇIKLAMASI", "headline":"BAŞKENTTEN SERT AÇIKLAMA", "body":"Kurgusal devlet başkanı, ülkenin güvenliği için gerekli tedbirlerin alınacağını açıkladı. Diplomatik kanallar açık tutuluyor.", "location":"BAŞKENT • ULUSAL BASIN MERKEZİ"},
        {"category":"İTTİFAK MASASI", "headline":"MÜTTEFİKLER ORTAK SAVUNMAYI GÖRÜŞÜYOR", "body":"%d müttefik ülke koordinasyon görüşmelerinde. İstihbarat, lojistik ve savunma desteği seçenekleri değerlendiriliyor." % ally_count, "location":"ORTAK KRİZ MASASI"},
        {"category":"GAZETE • SABAH BASKISI", "headline":"DÜNYA YENİ BİR KRİZİN EŞİĞİNDE", "body":"Başkentlerde diplomasi sürerken birlikler alarmda. Gözler şimdi %s operasyonunda." % operation, "location":"ULUSLARARASI BASIN • ÖZEL HABER"}
    ]
    card_index = 0
    timer = 0.0
    active = true
    panel.visible = true
    _show_card()

func play_result(country: String, city: String, operation: String, score: int, xp: int, allies: int, alert: String) -> void:
    play_briefing(country, city, operation, allies, [
        {"category":"SON DAKİKA • OPERASYON RAPORU", "headline":"OPERASYON BAŞARIYLA TAMAMLANDI", "body":"%s / %s operasyonu tamamlandı. Saha raporları merkeze ulaştı; birlikler güvenli bölgeye çekiliyor." % [city, operation], "location":"MERKEZ KOMUTA • GÖREV SONU"},
        {"category":"SAHA İSTATİSTİKLERİ", "headline":"GÖREV PERFORMANSI KAYDA GEÇTİ", "body":"Toplam skor: %d\nKazanılan XP: %d\nMüttefik desteği: %d ülke" % [score, xp, allies], "location":"OPERASYON MERKEZİ • PERFORMANS RAPORU"},
        {"category":"DİPLOMASİ MASASI", "headline":"ULUSLARARASI ALARM SEVİYESİ: %s" % alert, "body":"Kurgusal hükümetler yeni gelişmeleri değerlendiriyor. Diplomatik kanallar açık; müttefikler ortak savunma seçeneklerini görüşüyor.", "location":"ORTAK KRİZ MASASI"},
        {"category":"GAZETE • ÖZEL BASKI", "headline":"CEPHEDE YENİ BİR SAYFA AÇILDI", "body":"Operasyonun ardından dünya başkentlerinde yeni kararlar bekleniyor. Bir sonraki görev, kampanyanın yönünü değiştirebilir.", "location":"ULUSLARARASI BASIN • GECE BASKISI"}
    ])

func _process(delta: float) -> void:
    if not active: return
    timer += delta
    if timer >= 5.0: _next_card()
    if progress_bar != null: progress_bar.value = minf(100.0, (timer / 5.0) * 100.0)

func _show_card() -> void:
    if cards.is_empty(): skip(); return
    var card: Dictionary = cards[card_index]
    category_label.text = str(card.get("category", "SON DAKİKA"))
    headline_label.text = str(card.get("headline", "GELİŞME"))
    body_label.text = ""
    location_label.text = str(card.get("location", "SAHA RAPORU"))
    progress_label.text = "HABER %d / %d • 5 sn • İSTEĞE BAĞLI" % [card_index + 1, cards.size()]
    progress_bar.value = 0
    timer = 0.0
    typewriter_token += 1
    var token := typewriter_token
    var full_body := str(card.get("body", ""))
    for i in range(full_body.length() + 1):
        if token != typewriter_token or not active: return
        body_label.text = full_body.substr(0, i)
        await get_tree().create_timer(0.012).timeout

func _next_card() -> void:
    if not active: return
    typewriter_token += 1
    card_index += 1
    if card_index >= cards.size(): skip(); return
    _show_card()

func skip() -> void:
    if not active: return
    active = false
    typewriter_token += 1
    panel.visible = false
    finished.emit()
